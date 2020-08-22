#! /bin/bash

REPO_LIST="$1"

mkdir -p temp
cat src/1-repo-list.txt | egrep "$(cat "$REPO_LIST" | xargs | sed 's/ /|/g')" > temp/filtered-repo-list.txt
cat temp/filtered-repo-list.txt > src/1-repo-list.txt
rm -rf temp
