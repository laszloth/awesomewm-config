#!/bin/sh

ARCH_FORMAT=tar.gz
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
SHORT_HASH=$(git rev-parse --short HEAD)
PREFIX=${REPO_NAME}-${BRANCH_NAME}-${SHORT_HASH}
OUTPUT_FILE=/tmp/${PREFIX}.${ARCH_FORMAT}

git archive --format="$ARCH_FORMAT" -o $OUTPUT_FILE --prefix=$PREFIX/ $BRANCH_NAME

echo "Wrote '$OUTPUT_FILE'"
