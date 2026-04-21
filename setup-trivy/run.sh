#!/bin/bash

set -e

REPO="aquasecurity/trivy"
BIN_NAME="trivy"
if [ $(basename `pwd`) == "setup-$BIN_NAME" ]; then
    cd ..
fi
RELEASE=$(cat "setup-$BIN_NAME/$BIN_NAME-HEAD.json" 2>/dev/null | jq -r '.tagName')

download() {
    rm -rf ./downloads
    RELEASE=$(./scripts/find_release.sh "$REPO" 30)
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
    gh release download "$RELEASE" -R "$REPO" -p '*Linux-64bit.tar.gz*' --dir downloads --clobber
    gh release download "$RELEASE" -R "$REPO" -p '*checksum*' --dir downloads --clobber
    ln -sf $BIN_NAME-$RELEASE.json setup-$BIN_NAME/$BIN_NAME-HEAD.json
}

verify() {
    set -e -o pipefail;
    echo "Verifying signatures for $BIN_NAME release $RELEASE..."
    if [ -d "downloads" ]; then
        cd downloads
    else
        cd setup-$BIN_NAME
    fi
    set -x
    
    FILE=$(ls | grep -P 'checksums.txt$')
    if [ -f "$FILE.sigstore.json" ]; then
        # init tuf client
        cosign verify-blob-attestation  \
        --bundle $FILE.sigstore.json \
        --certificate-identity-regexp "https://github.com/$REPO/.*" \
        --certificate-oidc-issuer https://token.actions.githubusercontent.com \
        $FILE
    fi
    FILE=$(ls | grep -P 'tar.gz$')
    if [ -f "$FILE.sigstore.json" ]; then
        # init tuf client
        cosign verify-blob-attestation  \
        --bundle $FILE.sigstore.json \
        --certificate-identity-regexp "https://github.com/$REPO/.*" \
        --certificate-oidc-issuer https://token.actions.githubusercontent.com \
        $FILE
    fi
    sha256sum --ignore-missing -c *checksums.txt
}

extract() {
    mkdir -p downloads
    echo "Extracting binary for $BIN_NAME from setup-$BIN_NAME..."
    tar -xf setup-$BIN_NAME/*_Linux-64bit.tar.gz -C ./downloads
    mkdir -p "setup-$BIN_NAME/linux/amd64/bin"
    mv -v "downloads/$BIN_NAME" "setup-$BIN_NAME/linux/amd64/bin/$BIN_NAME"
    chmod +x "setup-$BIN_NAME/linux/amd64/bin/$BIN_NAME"
}

store() {
    echo "Cleaning up files..."
    rm -fv setup-$BIN_NAME/*checksum*
    rm -fv setup-$BIN_NAME/*_Linux-64bit.tar.gz
    echo "Storing downloaded bin and checksum files for $BIN_NAME..."
    cp -v downloads/*_Linux-64bit.tar.gz* "setup-$BIN_NAME/"
    cp -v downloads/*checksum* "setup-$BIN_NAME/"
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
