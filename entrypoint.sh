#!/usr/bin/env sh
# shellcheck disable=3028
set -e
[ $UID -eq 0 ] || adduser -D -h "${HOME:?}" -s /bin/bash -u "${UID:?}" user 1> /dev/null 2>&1
cd "$HOME/pwd"
exec /sbin/su-exec "$UID:$UID" "$@"
