#!/bin/bash

set -e

REPO="anchore/grype"
BIN_NAME="grype"
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
    gh release download "$RELEASE" -R "$REPO" -p '*linux_amd64.tar.gz' --dir downloads --clobber
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
    cosign verify-blob \
        --certificate *checksums.txt.pem \
        --signature *checksums.txt.sig \
        --certificate-identity-regexp 'https://github.com/anchore/grype/.*' \
        --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
        *checksums.txt && \
    sha256sum --ignore-missing -c *checksums.txt
}

extract() {
    mkdir -p downloads
    echo "Extracting binary for $BIN_NAME from setup-$BIN_NAME..."
    tar -xf setup-$BIN_NAME/*_linux_amd64.tar.gz -C ./downloads
    mkdir -p "setup-$BIN_NAME/linux/amd64/bin"
    mv -v "downloads/$BIN_NAME" "setup-$BIN_NAME/linux/amd64/bin/$BIN_NAME"
    chmod +x "setup-$BIN_NAME/linux/amd64/bin/$BIN_NAME"
}

store() {
    echo "Storing downloaded bin and checksum files for $BIN_NAME..."
    cp -v downloads/*_linux_amd64.tar.gz "setup-$BIN_NAME/"
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
