#! /bin/bash

BEARER_TOKEN=$1
GITHUB_ORG=$2

# Extract Secrets & Detect Live Keys
while read FILENAME; do

    AWS_KEY=$(echo $FILENAME | cut -d'.' -f1)
    URL=$(head -1 src/results/post-truffle-results/$FILENAME)
    GITPATH=$(echo $URL | awk -F"${GITHUB_ORG}/" '{print $2}' | sed 's}blob/}}g')
    AWS_SECRET_FILE="src/results/post-truffle-results/${AWS_KEY}.secret"
    LIVE_RESULTS_FILE="src/results/post-truffle-results/${AWS_KEY}.check"

    if [ ! -f "${AWS_SECRET_FILE}" ]; then

        curl -H "Authorization: token ${BEARER_TOKEN}" \
            -H 'Accept: application/vnd.github.v3.raw' \
            -L "https://raw.githubusercontent.com/${GITHUB_ORG}/${GITPATH}" 2>/dev/null | egrep -A3 -B3 "AKIA[0-9A-Z]{16}"
        
        echo -e "\nPlease grab the AWS Secret from the above file ($URL) for key ${AWS_KEY}:\n"
        read AWS_SECRET < /dev/tty
        echo "${AWS_SECRET}" > "${AWS_SECRET_FILE}"
    fi

    if [ ! -f "${LIVE_RESULTS_FILE}" ]; then

        AWS_SECRET="$(cat "${AWS_SECRET_FILE}")"

        export AWS_ACCESS_KEY_ID="${AWS_KEY}"
        export AWS_SECRET_ACCESS_KEY="${AWS_SECRET}"

        aws s3 ls > /tmp/key-response.txt 2> /tmp/key-response.txt

        INVALID=$(cat /tmp/key-response.txt | grep -c InvalidAccessKeyId)
        DENIED=$(cat /tmp/key-response.txt | egrep -c "AccessDenied|SignatureDoesNotMatch")
        ALLOWED=$(cat /tmp/key-response.txt | egrep -c "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}")

        echo "KEY=${AWS_KEY}, INVALID=$INVALID, DENIED=$DENIED, ALLOWED=$ALLOWED"

        if [ ${DENIED} -gt 0 ] || [ $ALLOWED -gt 0 ]; then
            echo "alive" > "${LIVE_RESULTS_FILE}"
        else
            echo "dead" > "${LIVE_RESULTS_FILE}"
        fi
    fi

done <<<"$(ls -1 src/results/post-truffle-results/ | grep txt)"

# Report on Live Keys
echo -e "Live keys report\n_______________"
echo -e "Number of live keys found: $(grep -RH --include="*.check" alive src/results/post-truffle-results | wc -l)\n"

rm -f /tmp/live-key-references
while read GREP; do

    AWS_KEY=$(echo $GREP | cut -d'/' -f4 | cut -d'.' -f1)
    cat "src/results/post-truffle-results/${AWS_KEY}.txt" | sed "s/^/${AWS_KEY},/g" >> /tmp/live-key-references
    
done <<<"$(grep -RH --include="*.check" alive src/results/post-truffle-results)"

echo "Live key appearances in commits per repo: "
cat /tmp/live-key-references | cut -d'/' -f5 | sort | uniq -c
