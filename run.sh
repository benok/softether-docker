#!/bin/bash

. vars.sh
. functions.sh

for v in ${VOLUMES//,/ }; do
    vol=( ${v//:/ } )
    host_dir=${vol[0]}
    cont_dir=${vol[1]}
    #host_dir=$(cut -d: -f1 < <(echo $v))
    if [ ! -e $host_dir ] && [[ ! "$N" =~ .*[/].* ]]; then
      docker volume create --name $host_dir
    else
      if [ -d $host_dir ]; then
        chmod g+rwxs $host_dir
      fi
      chmod -R g+w $host_dir
    fi
done

RUN_ARGS="$(for c in ${CAPS//,/ }; do echo --cap-add $c ; done) \
          $(for v in ${VOLUMES//,/ }; do echo -v $v ; done) \
          $(for d in ${DEVICES//,/ }; do echo --device $d ; done) \
          $(for p in ${PUBLISH_PORTS//,/ }; do echo -p ${HOST_IP}:$p:$p ; done)"

echo "Invoking:"
echo "docker run --name $CONT_NAME -d --restart unless-stopped $RUN_ARGS $TAG_BASE $@"
docker run --name $CONT_NAME -d --restart unless-stopped $RUN_ARGS $TAG_BASE $@
#docker run -it --rm $RUN_ARGS $TAG_BASE $@

