#! /bin/bash

BEARER_TOKEN="$1"
GITHUB_ORG="$2"
REPO_FILTER="$3"

mkdir -p temp
trap ctrl_c INT
function ctrl_c() {
        echo "Exiting safely"
        rm -rf temp
        exit 1
}

if [ "$REPO_FILTER" == "" ]; then
  REPO_FILTER="^$"
fi

echo "GitHub API: Getting number of pages"
wget --header "Authorization: Bearer $BEARER_TOKEN"\
 --save-headers "https://api.github.com/orgs/$GITHUB_ORG/repos?page=$PAGE_NUMBER"\
  -O temp/out.txt 2>/dev/null
[ $? -ne 0 ] && echo "Error: GitHub credentials invalid" && exit 1

sed -i -e "s/^M//" temp/out.txt
TOTAL_PAGES=$(cat temp/out.txt | grep ^Link: | awk -F'?' '{print $NF}' | cut -d'>' -f1 | cut -d'=' -f2)

echo "GitHub API: Looping through $TOTAL_PAGES pages"
for PAGE_NUMBER in $(seq 1 $TOTAL_PAGES)
do
    echo "GitHub API: Page $PAGE_NUMBER"
    wget --header "Authorization: Bearer $BEARER_TOKEN"\
    "https://api.github.com/orgs/$GITHUB_ORG/repos?page=$PAGE_NUMBER"\
    -O temp/content.$PAGE_NUMBER 2>/dev/null
done

cat temp/content.* | jq '.[].ssh_url' -r | sort | uniq | egrep -v "$REPO_FILTER" > src/1-repo-list.txt

echo "pushd repos" > src/1.1-clone.sh
cat temp/content.* | jq '.[].ssh_url' -r | sort | uniq | egrep -v "$REPO_FILTER" | awk '{print "git clone "$1}' >> src/1.1-clone.sh
echo "popd" >> src/1.1-clone.sh

echo "pushd repos" > src/1.1-pull.sh
cat temp/content.* | jq '.[].ssh_url' -r | sort | uniq | egrep -v "$REPO_FILTER" | cut -d'/' -f2 | sed 's/.git//g' | awk '{print "pushd "$1"; git pull; popd"}' >> src/1.1-pull.sh
echo "popd" >> src/1.1-pull.sh

rm -rf temp
echo "src/1-repo-list.txt, src/1.1-clone.sh and src/1.1-pull.sh have been re-generated"
