#!/bin/sh

yum install -y nc

# if the proxy is around, use it
nc -z -w3 192.168.1.1 8123 && export http_proxy="http://192.168.1.1:8123"

mkdir -p /vagrant/substrate-assets
chmod 755 /vagrant/substrate/run.sh

set -e

if [ "${VAGRANT_BUILD_DEBUG}" = "1" ]; then
    /vagrant/substrate/run.sh /vagrant/substrate-assets
else
    /vagrant/substrate/run.sh /vagrant/substrate-assets > /dev/null
fi
