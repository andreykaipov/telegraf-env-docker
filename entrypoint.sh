#!/bin/sh -eu

: "${config_path:=/etc/telegraf/telegraf.conf}"
mkdir -p "$(dirname $config_path)"

env2conf -prefix inputs,processors,aggregators,outputs -output toml > /opt/telegraf.conf

if [ -s /opt/telegraf.conf ]; then
    nonempty='yes'
fi

if echo "$@" | grep -q ^-; then
    set -- telegraf ${nonempty:+--config /opt/telegraf.conf} "$@"
fi

exec "$@"
