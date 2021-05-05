#! /bin/bash

if [ $# -ne 1 ]; then
    echo "ERROR: Please provide a config file."
    exit 1
fi

SKIP_GET=False

CONFIG_FILE=$1
source $CONFIG_FILE
if [ $? -ne 0 ]; then
    echo "ERROR: Invalid config file"
    exit 1
fi

if ! $SKIP_GET; then
    mkdir -p repos
    ./src/1-get-repo-list.sh "$BEARER_TOKEN" "$GITHUB_ORG" "$REPO_FILTER" "${REPO_LIST}"
    [ $? -ne 0 ] && exit 1

    chmod 744 ./src/*.sh

    ./src/1.1-clone.sh
    ./src/1.1-pull.sh
fi

echo "
Building report using DATE_FILTER=$DATE_FILTER and APPROVAL_FILTER=$APPROVAL_FILTER
"
if ! [ -z $REPO_LIST ]; then
    echo -e "Applying repo filter REPO_LIST=$REPO_LIST\n"
    ./src/2-filter-repos.sh "$REPO_LIST"
fi

./src/3-update-repos-track-authors.sh "$DATE_FILTER"
./src/4-get-unapproved-authors.sh "$APPROVAL_FILTER"
./src/5-truffling.sh "$SKIP_TRUFFLE" "$GITHUB_ORG"

./src/6-post-truffle.sh "$SKIP_TRUFFLE" "$SKIP_POST_TRUFFLE" "$BEARER_TOKEN" "$GITHUB_ORG"

./src/7-interactive-find-live-aws-keys.sh "$BEARER_TOKEN" "$GITHUB_ORG"
