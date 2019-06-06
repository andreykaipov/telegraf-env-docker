#!/bin/sh -eu

: "${config_path:=/etc/telegraf/telegraf.conf}"
mkdir -p "$(dirname $config_path)"
"$(dirname "$0")/telegraf.conf.sh" > $config_path

if echo "$@" | grep -q ^-; then
    set -- telegraf --config "$config_path" "$@"
fi

exec "$@"
