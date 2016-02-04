#!/bin/sh

export LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
export EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
export EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"

if [ ! -z "$ATLAS_INFRASTRUCTURE" ] && [ ! -z "$ATLAS_TOKEN" ]; then
    echo "Using Atlas ($ATLAS_INFRASTRUCTURE) to join Consul Server"
    exec consul agent -config-dir=/config "$@" -atlas-join -atlas=$ATLAS_INFRASTRUCTURE -atlas-token=$ATLAS_TOKEN -advertise $LOCAL_IP -dc $EC2_REGION
else
    echo "Using $SERVER_IP to join Consul Server"
    exec consul agent -config-dir=/config "$@" -join $SERVER_IP -advertise $LOCAL_IP -dc $EC2_REGION -config-file /etc/consul/consul.json
fi