#!/usr/bin/env bash

set -ex

NEXT=$(cat ./var/n.txt)
NEXT=$((NEXT + 1))
echo $NEXT > ./var/n.txt

TAG=v0.${NEXT}.0

docker buildx imagetools create \
  ghcr.io/akuity/guestbook:latest \
  -t ghcr.io/vojtechmares-examples/guestbook:${TAG}
