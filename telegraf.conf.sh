#!/bin/sh

main() {
    [ -n "$SET_TELEGRAF_DEFAULTS" ] || exec env \
	'SET_TELEGRAF_DEFAULTS=1' \
    	"agent.interval=$(get_env agent.interval "10s")" \
    	"agent.round_interval=$(get_env agent.round_interval true)" \
    	"agent.metric_batch_size=$(get_env agent.metric_batch_size 1000)" \
    	"agent.metric_buffer_limit=$(get_env agent.metric_buffer_limit 10000)" \
    	"agent.collection_jitter=$(get_env agent.collection_jitter "0s")" \
    	"agent.flush_interval=$(get_env agent.flush_interval "10s")" \
    	"agent.flush_jitter=$(get_env agent.flush_jitter "0s")" \
    	"agent.precision=$(get_env agent.precision "")" \
    	"agent.debug=$(get_env agent.debug false)" \
    	"agent.quiet=$(get_env agent.quiet false)" \
    	"agent.logfile=$(get_env agent.logfile "")" \
    	"agent.hostname=$(get_env agent.hostname "")" \
    	"agent.omit_hostname=$(get_env agent.omit_hostname false)" \
    	$0

    set -eu

    echo [global_tags]
    get_table global_tags

    echo [agent]
    get_table agent

    get_array_of_tables "aggregators"
    get_array_of_tables "inputs"
    get_array_of_tables "outputs"
    get_array_of_tables "parsers"
    get_array_of_tables "processors"
    get_array_of_tables "serializers"
}

# awk supports env vars with dots :-)
get_env() {
    key="$1"; shift
    default="$1"; shift
    val="$(awk -v "key=$key" 'BEGIN {print ENVIRON[key]}')"
    if [ -n "$val" ]; then
	echo "$val"
    else
	echo "$default"
    fi
}

indent() { sed 's/^/    /'; }

get_table() {
    local tablename="$1"; shift
    local IFS=$'\n'
    for var in $(env | grep -E "^$tablename[.]" | cut -c"$(echo "${tablename}." | wc -c)"-); do
	local k="$(echo "$var" | cut -d= -f1)"
	local v="$(echo "$var" | cut -d= -f2- | sed -e 's/^"//g' -e 's/"$//g')" # sanitize

	local kv=""
	if $(echo "$v" | grep -qE '^[0-9.]+$'); then
	    kv="$k = $v"
	elif $(echo "$v" | grep -qE '^(false|true)$'); then
	    kv="$k = $v"
	elif $(echo "$v" | grep -qE '^\[.*\]$'); then
	    kv="$k = $v"
	else
	    kv="$k = \"$v\""
	fi
	echo "$kv" | indent
    done
}

get_array_of_tables() {
    local tablekind="$1"; shift
    for kind in $(env | grep -E "^$tablekind[.]" | cut -d. -f1-2 | sort | uniq); do
	echo "[[$kind]]"
        get_table "$kind"
    done
}

main
