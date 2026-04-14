#!/bin/bash

set -e

REPO="sigstore/cosign"
BIN_NAME="cosign"
if [ $(basename `pwd`) == "setup-$BIN_NAME" ]; then
    cd ..
fi
RELEASE=$(cat "setup-$BIN_NAME/$BIN_NAME-HEAD.json" 2>/dev/null | jq -r '.tagName')
download() {
    rm -rf ./downloads
    RELEASE=$(./scripts/find_release.sh "$REPO" 60)
    echo "Downloading $BIN_NAME release $RELEASE..."
    mkdir -p "setup-$BIN_NAME/linux/amd64/bin"
    (
        TAG_URL=$(gh api "repos/$REPO/git/ref/tags/$RELEASE" --template '{{.object.url}}')
        TAG_COMMIT_SHA=$(curl -s "$TAG_URL" | jq -r '.object.sha')
        if [ "$TAG_COMMIT_SHA" == "null" ]; then
            TAG_COMMIT_SHA=$(curl -s "$TAG_URL" | jq -r '.sha')
        fi
        gh release view "$RELEASE" -R "$REPO" --json tagName,id,name,publishedAt,url \
            | jq --arg tag_commit_sha "$TAG_COMMIT_SHA" '.tag_commit_sha = $tag_commit_sha' \
            | tee "setup-$BIN_NAME/$BIN_NAME-$RELEASE.json"
    )
    gh release download $RELEASE -R $REPO -p "cosign-linux-amd64" --dir downloads --clobber
    gh release download $RELEASE -R $REPO -p "cosign-linux-amd64-kms.sigstore.json" --dir downloads --clobber

    ln -sf $BIN_NAME-$RELEASE.json setup-$BIN_NAME/$BIN_NAME-HEAD.json
}

verify() {
    set -e -o pipefail;
    echo "Verifying signatures for $BIN_NAME release $RELEASE..."
    if [[ ! -f "downloads/cosign-linux-amd64" && ! -f "setup-$BIN_NAME/cosign-linux-amd64" ]]; then
        extract
    fi
    if [ -d "downloads" ]; then
        cd downloads
    else
        cd setup-$BIN_NAME
    fi
    set -x
    
    # init tuf client
    go install github.com/theupdateframework/go-tuf/cmd/tuf-client@latest
    curl -o sigstore-root.json https://raw.githubusercontent.com/sigstore/root-signing/refs/heads/main/metadata/root.json
    tuf-client init https://tuf-repo-cdn.sigstore.dev sigstore-root.json
    tuf-client get https://tuf-repo-cdn.sigstore.dev artifact.pub > artifact.pub

    cat cosign-linux-amd64-kms.sigstore.json | jq -r .messageSignature.signature | base64 -d > cosign-linux-amd64-kms.sig.decoded

    openssl dgst -sha256 -verify artifact.pub -signature cosign-linux-amd64-kms.sig.decoded cosign-linux-amd64

    # openssl dgst -sha256 -verify artifact.pub -signature $FILENAME.sig.decoded $FILENAME
}

extract() {
    mkdir -p "setup-$BIN_NAME/linux/amd64/bin"
    echo "Extracting binary for $BIN_NAME from setup-$BIN_NAME..."
    tar -xf setup-$BIN_NAME/*-linux-amd64.tar.gz -C ./setup-$BIN_NAME
    cp -v "setup-$BIN_NAME/cosign-linux-amd64" "setup-$BIN_NAME/linux/amd64/bin/$BIN_NAME"
    
    chmod +x "setup-$BIN_NAME/linux/amd64/bin/$BIN_NAME"
}

store() {
    echo "Cleaning up files..."
    rm -fv setup-$BIN_NAME/cosign-linux-amd64.tar.gz
    rm -fv setup-$BIN_NAME/*kms.sigstore.json
    
    echo "Storing downloaded bin and checksum files for $BIN_NAME..."
    if [ ! -f "./downloads/cosign-linux-amd64.tar.gz" ]; then
        (cd downloads && tar -zcf cosign-linux-amd64.tar.gz cosign-linux-amd64)
    fi

    cp -v downloads/*linux-amd64.tar.gz "setup-$BIN_NAME/"
    cp -v downloads/*kms.sigstore.json "setup-$BIN_NAME/"
}

case "$1" in
    download)
        download
        ;;
    verify)
        verify
        ;;
    extract)
        extract
        ;;
    store)
        store
        ;;
    *)
        echo "Usage: $0 {download|verify|extract|store}"
        exit 1
        ;;
esac
