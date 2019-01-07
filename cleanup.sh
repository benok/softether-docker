#!/bin/bash

. vars.sh

docker stop $CONT_NAME
docker rm $CONT_NAME
