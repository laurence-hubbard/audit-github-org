#! /bin/bash

SKIP_TRUFFLE=$1
SKIP_POST_TRUFFLE=$2
BEARER_TOKEN=$3
GITHUB_ORG=$4

TOTAL=$(cat src/truffle-results/SUMMARY_AWS_API_Key_hash.txt | wc -l)

COUNT=0

if ! $SKIP_POST_TRUFFLE; then

    echo -e "\nScanning truffle results...\n"

    mkdir -p src/post-truffle-results/ 2>/dev/null
    rm src/post-truffle-results/*.txt 2>/dev/null

    while read URL; do
        GITPATH=$(echo $URL | awk -F"${GITHUB_ORG}/" '{print $2}' | sed 's}blob/}}g')

        while read KEY_ID; do
            if [ "${KEY_ID}" != "" ]; then
                echo $URL >> "src/post-truffle-results/${KEY_ID}.txt"
            fi
        done <<<"$(curl -H "Authorization: token ${BEARER_TOKEN}" \
            -H 'Accept: application/vnd.github.v3.raw' \
            -L "https://raw.githubusercontent.com/${GITHUB_ORG}/${GITPATH}" 2>/dev/null \
            | egrep -o "AKIA[0-9A-Z]{16}")"

        COUNT=$((COUNT+1))
        if ! ((COUNT % 10)); then
            echo "$COUNT of $TOTAL AWS key results scanned"
        fi

    done <<<"$(cat src/truffle-results/SUMMARY_AWS_API_Key_hash.txt | awk '{{print $NF}}')"

else
    echo -e "\nWARNING: Not running post analysis of trufflehog. Will display previous results if they exist.\n"
fi

if [ -d src/truffle-results/ ]; then
    echo -e "\nTRUFFLE OUTPUT ANALYSIS REPORT\n"

    echo "$(ls -1 src/post-truffle-results/ | wc -l) confirmed AWS keys found:"
    wc -l src/post-truffle-results/* | grep -v total

fi
