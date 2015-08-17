#!/bin/bash
set -e

if [ -z ${STACKDRIVER_API_KEY+x} ]; then
  export STACKDRIVER_API_KEY="$(curl -fs -H "Metadata-Flavor: Google" "http://metadata/computeMetadata/v1/project/attributes/stackdriver-agent-key" 2>/dev/null)"
  if [ -z $STACKDRIVER_API_KEY ]; then
    echo "Unable to discover STACKDRIVER_API_KEY"
    exit 1
  fi
fi

if [ -z ${INSTANCE_ID+x} ]; then
  export INSTANCE_ID="$(curl -fs -H "Metadata-Flavor: Google" "http://metadata/computeMetadata/v1/instance/id" 2>/dev/null)"
  if [ -z $INSTANCE_ID ]; then
    echo "Unable to discover INSTANCE_ID"
    exit 1
  fi
fi

if [ -z ${COLLECTD_ENDPOINT+x} ]; then
  export COLLECTD_ENDPOINT="collectd-gateway.google.stackdriver.com"
fi

sed -i "s/{INSTANCE_ID}/$INSTANCE_ID/; s/{STACKDRIVER_API_KEY}/$STACKDRIVER_API_KEY/; s|{COLLECTD_ENDPOINT}|$COLLECTD_ENDPOINT|" /opt/stackdriver/collectd/etc/collectd.conf

if [ "$1" == "stackdriver-agent" ]; then
  if [ -d /host/proc ]; then
    mount -o bind /host/proc /proc
  fi
  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/stackdriver/collectd/lib64:/opt/stackdriver/collectd/lib"
  exec /opt/stackdriver/collectd/sbin/stackdriver-collectd -f -C /opt/stackdriver/collectd/etc/collectd.conf
else
  exec "$@"
fi
