#! /bin/bash

APPROVAL_FILTER="$1"

echo "
AUDIT REPORT:
"
cat src/2-authors.txt | grep -v "^-INFO-" | sort | uniq -c | egrep -v "$APPROVAL_FILTER"

echo ""
