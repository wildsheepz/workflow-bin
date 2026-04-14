#!/bin/bash

set -e

REPO="helm/helm"
BIN_NAME="helm"
if [ $(basename `pwd`) == "setup-$BIN_NAME" ]; then
    cd ..
fi
RELEASE=$(cat "setup-$BIN_NAME/$BIN_NAME-HEAD.json" 2>/dev/null | jq -r '.tagName')

download() {
    rm -rf ./downloads
    mkdir downloads
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
    ) && \
    URL=$(jq -r '.url' < "setup-$BIN_NAME/$BIN_NAME-$RELEASE.json") && \
    curl -L https://get.helm.sh/helm-$RELEASE-linux-amd64.tar.gz -o downloads/helm-$RELEASE-linux-amd64.tar.gz && \
    curl -L https://get.helm.sh/helm-$RELEASE-linux-amd64.tar.gz.sha256sum -o downloads/helm-$RELEASE-linux-amd64.tar.gz.sha256sum && \
    SIGNING_PUBKEY="$(curl -L $URL | grep -Po 'which can be found at.*$' | grep -Po 'https\S+"' | tr -d '"')" && \
    curl -L "$SIGNING_PUBKEY" -o downloads/pgp_keys.asc && \
    gh release download $RELEASE -R $REPO -p '*linux-amd64*' --dir downloads --clobber && \
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
    gpg --import < pgp_keys.asc && \
    gpg -q --verify helm-$RELEASE-linux-amd64.tar.gz.sha256sum.asc && \
    gpg -q --verify helm-$RELEASE-linux-amd64.tar.gz.asc && \
    sha256sum --ignore-missing -c helm-$RELEASE-linux-amd64.tar.gz.sha256sum
}

extract() {
    mkdir -p downloads
    tar -xvf setup-$BIN_NAME/*-linux-amd64.tar.gz -C ./downloads --strip-components=1 && \
    mkdir -p setup-$BIN_NAME/linux/amd64/bin && \
    mv downloads/$BIN_NAME setup-$BIN_NAME/linux/amd64/bin/$BIN_NAME && \
    chmod +x setup-helm/linux/amd64/bin/helm
}

store() {
    echo "Cleaning up files..."
    rm -fv setup-$BIN_NAME/*linux-amd64.tar.gz
    rm -fv setup-$BIN_NAME/*.*sum
    rm -fv setup-$BIN_NAME/*.asc

    echo "Storing downloaded bin and checksum files for $BIN_NAME..."
    cp -v downloads/*linux-amd64.tar.gz "setup-$BIN_NAME/"
    cp -v downloads/*.*sum "setup-$BIN_NAME/"
    cp -v downloads/*.asc "setup-$BIN_NAME/"
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
