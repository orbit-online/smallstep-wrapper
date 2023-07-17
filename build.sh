#!/usr/bin/env bash

set -eo pipefail
shopt -s inherit_errexit

PKGROOT=$(upkg root "${BASH_SOURCE[0]}")

main() {
  docker build \
    --tag secoya/smallstep-wrapper:latest \
    --file="$PKGROOT/Dockerfile" "$PKGROOT"
}

main "$@"
