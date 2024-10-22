#!/bin/bash

. vars.sh 
. functions.sh

# get host volumes' and devices' gids
VOL_GIDS=($(get_host_dir_groups $VOLUMES))
DEV_GIDS=($(get_host_dir_groups $DEVICES))
# get the group ids from group names
GIDS=($(get_gid $CONT_GROUPS))
# combine, sort, uniqe
GIDS="$(merge_unique_int DEV_GIDS[@] VOL_GIDS[@] GIDS[@])"
# change to coma separated string
GIDS="${GIDS// /,}"

echo GIDS: $GIDS

BUILD_ARGS="\
  --build-arg GITHUB_REPO=$GITHUB_REPO \
  --build-arg gids=$GIDS \
  --build-arg uid=$CONT_UID \
  --build-arg gid=$CONT_GID \
  --build-arg user=$CONT_USER"

echo Invoking:
echo "docker build . --tag=$TAG_BASE:$TAG_VERSION $BUILD_ARGS"
docker build . --tag=$TAG_BASE:$TAG_VERSION $BUILD_ARGS


# if we are building latest version 
#LATEST=$(get_latest "$GITHUB_REPO")
#if [ "$LATEST" == "$BUILD_VERSION" ]; then
  echo Invoking:
  echo "docker build . --tag=$TAG_BASE:latest $BUILD_ARGS"
  docker build . --tag=$TAG_BASE:latest $BUILD_ARGS
#fi
