#! /bin/bash

DATE_FILTER="$1"

rm src/2-authors.txt

trap ctrl_c INT
function ctrl_c() {
        echo "Exiting safely"
        rm src/2-authors.txt
        exit 1
}

echo "Retrieving authors from repos..."
while read REPO_SSH; do

    REPO=repos/$(echo $REPO_SSH | cut -d'/' -f2 | sed 's/.git$//g')
    pushd $REPO > /dev/null
        echo "-INFO- $REPO" >> ../../src/2-authors.txt
        git log --after="$(date +%F -d"${DATE_FILTER}")" | grep ^Author >> ../../src/2-authors.txt
        [ ${PIPESTATUS[0]} -ne 0 ] && echo "^ Above error from $REPO has been ignored"
    popd > /dev/null

done < src/1-repo-list.txt
echo "src/1-repo-list.txt has been populated"
