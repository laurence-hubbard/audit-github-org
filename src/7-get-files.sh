#! /bin/bash

BEARER_TOKEN=$1
GITHUB_ORG=$2

while read FILENAME; do

    AWS_KEY=$(echo $FILENAME | cut -d'.' -f1)
    URL=$(head -1 $FILENAME)
    GITPATH=$(echo $URL | awk -F"${GITHUB_ORG}/" '{print $2}' | sed 's}blob/}}g')

    echo $AWS_KEY,$URL,$GITPATH

    curl -H "Authorization: token ${BEARER_TOKEN}" \
            -H 'Accept: application/vnd.github.v3.raw' \
            -L "https://raw.githubusercontent.com/${GITHUB_ORG}/${GITPATH}" 2>/dev/null > $AWS_KEY.out

done <<<"$(ls -1 | grep txt)"
