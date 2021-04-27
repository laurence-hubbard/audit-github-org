#! /bin/bash

SKIP_TRUFFLE="$1"
GITHUB_ORG="$2"

if ! $SKIP_TRUFFLE; then
    echo "Truffling"

    rm src/5-results.txt 2>/dev/null
    mkdir -p src/truffle-results/ 2>/dev/null
    rm src/truffle-results/*.txt 2>/dev/null
    while read REPO_SSH; do

        REPO=$(echo $REPO_SSH | cut -d'/' -f2 | sed 's/.git$//g')
        pushd repos/$REPO > /dev/null

            docker run --rm -v "$(pwd):/proj" dxa4481/trufflehog --regex --entropy=False file:///proj | sed -r "s/[[:cntrl:]]\[[0-9]{1,3}m//g" | egrep -i "^Reason:|^Filepath:|^Branch:|~~~~~~~~~~~~~~~~~~~~~|^Hash:" > ../../src/truffle-results/$REPO.txt
            # truffleHog --regex --entropy=False ./ | sed -r "s/[[:cntrl:]]\[[0-9]{1,3}m//g" | egrep -i "^Reason:|^Filepath:|^Branch:|~~~~~~~~~~~~~~~~~~~~~|^Hash:" > ../../src/truffle-results/$REPO.txt
            RESULTS=$(cat ../../src/truffle-results/$REPO.txt | grep -c "^Reason:")
        popd > /dev/null

        echo "$RESULTS --> $REPO"
        echo "$RESULTS --> $REPO" >> src/5-results.txt

    done < src/1-repo-list.txt
else
    echo "WARNING: Not running trufflehog. Will display previous results if they exist."
fi

if [ -d src/truffle-results/ ]; then
    pushd src/truffle-results/ > /dev/null
    echo -e "\nTRUFFLE REPORT \n\nCount of issues by type:\n"
    grep Reason * | awk -F'Reason: ' '{print $2}' | sort | uniq > truffle-result-types.txt
    grep Reason * | awk -F'Reason: ' '{print $2}' | sort | uniq -c

    if ! ls SUMMARY* >/dev/null 2>&1; then
        echo -e "\n"
        while read RESULT_TYPE; do
            echo -e "Calculating summary for $RESULT_TYPE"

            RESULT_TYPE_FILE_NAME=$(echo $RESULT_TYPE | sed 's/[ ()]/_/g' | sed 's/__/_/g')

            grep "Reason: $RESULT_TYPE" * -A2 | grep Filepath | sort | uniq | sed "s)^)https://github.com/$GITHUB_ORG/)g" | sed 's)\.txt-Filepath: )/blob/master/)g' > "SUMMARY_${RESULT_TYPE_FILE_NAME}_master.txt"
            grep "Reason: $RESULT_TYPE" * -A2 | grep Filepath | sort | uniq | cut -d' ' -f2 | sed "s@\(.*\)@grep \"$RESULT_TYPE\" * -A2 | grep \1 -B2@g" | /bin/bash | xargs | sed 's/--/\n/g'| sed "s@.*Hash: \([^ ]*\) \(.*\).txt-Filepath: \([^ ]*\)@open https://github.com/$GITHUB_ORG/\2/blob/\1/\3@g" > "SUMMARY_${RESULT_TYPE_FILE_NAME}_hash.txt"

            if [ $(cat "SUMMARY_${RESULT_TYPE_FILE_NAME}_hash.txt" | wc -l) -eq 0 ]; then
                rm "SUMMARY_${RESULT_TYPE_FILE_NAME}_hash.txt"
            fi

            if [ $(cat "SUMMARY_${RESULT_TYPE_FILE_NAME}_master.txt" | wc -l) -eq 0 ]; then
                rm "SUMMARY_${RESULT_TYPE_FILE_NAME}_master.txt"
            fi

        done < truffle-result-types.txt 
    fi

    popd > /dev/null

    echo -e "\nSummaries available in src/truffle-results/:\n"
    wc -l src/truffle-results/SUMMARY*
fi
