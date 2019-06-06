#!/bin/sh
set -eu

: "${remote?:"Define a remote, e.g. quay.io"}"
: "${repo?:"Define a repo, e.g qoqodev/telegraf"}"

is_alpine() {
    if [ -f /etc/os-release ]; then
        grep -qx ID=alpine /etc/os-release
        return "$?"
    fi
    return 1
}

docker_login() {
    remote="$1"; shift
    docker login -u "$DOCKER_USER" -p "$DOCKER_PASS" "$remote"
}

nl="$(printf '\nx')"; nl="${nl%x}"

spin() {
    spinner='-\|/'
    while :; do
        for i in $(seq 1 4); do
            echo "$spinner" | cut -c"$i" | tr -d "$nl"
            printf '\b'
            sleep 0.1
        done
    done
}

docker_build() {
    tag="$1"; shift
    name="$remote/$repo:$tag"

    spin &
    pid="$!"
    trap 'kill -9 $pid' INT TERM

    printf "%-40s %s" "$name" "building "
    docker build --build-arg "base=$tag" -t "$name" . >/dev/null
    printf "✓ "

    printf "pushing "
    docker push "$name" >/dev/null
    printf "✓"

    echo
    kill -9 "$pid"
}

load() {
    is_alpine && apk add -U curl

    upstream_repo="telegraf"
    recent_tags="$(
        curl -s "https://registry.hub.docker.com/v1/repositories/$upstream_repo/tags" \
        | tr -d ' "[]{,' \
        | tr '}' '\n' \
        | cut -d: -f3 \
        | grep -vE '^(0|1[.][0-7]([.-]|$))'
    )"
    for tag in $recent_tags; do
        docker_build "$tag"
    done
}

sync() {
    is_alpine && apk add -U curl grep coreutils

    # tag:date pairs
    upstream_pairs="$(
        curl -sL https://registry.hub.docker.com/v2/repositories/library/telegraf/tags?page_size=100 \
        | grep -oP '(name|last_updated).+?[,}]' \
        | tr -d ' ",' \
        | paste - - -d: \
        | cut -d: -f2,4-
    )"

    today="$(date +%s)"

    for pair in $upstream_pairs; do
        tag="$(echo "$pair" | cut -d: -f1)"
        last="$(echo "$pair" | cut -d: -f2- | date -f- +%s)"
        if [ "$last" -gt "$today" ]; then
            docker_build "$tag"
        fi
    done
}
