#!/bin/sh -eu

: "${config_path:=/etc/telegraf/telegraf.conf}"
mkdir -p "$(dirname $config_path)"

env2conf -prefix agent,inputs,processors,aggregators,outputs -output toml > $config_path

if echo "$@" | grep -q ^-; then
    set -- telegraf "$@"
fi

exec "$@"
