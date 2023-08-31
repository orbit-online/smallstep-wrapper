#!/usr/bin/env bash

main() {
  set -eo pipefail
  shopt -s inherit_errexit
  local pkgroot
  pkgroot=$(upkg root "${BASH_SOURCE[0]}")
  PATH="$pkgroot/.upkg/.bin:$PATH"
  # shellcheck source=.upkg/orbit-online/records.sh/records.sh
  source "$pkgroot/.upkg/orbit-online/records.sh/records.sh"
  checkdeps docker jq

  STEPPATH=${STEPPATH:-"$HOME/.step"}
  [[ -d "$STEPPATH" ]] || fatal "\$STEPPATH '%s' not found." "$STEPPATH"

  local version additional_opts=() cmd=()
  version=$(image-version "$(jq -re '.version // empty' "$pkgroot/upkg.json" 2>/dev/null || git symbolic-ref HEAD)")

  local p11_kit_socket="$XDG_RUNTIME_DIR/p11-kit/pkcs11"
  if [[ -S "$p11_kit_socket" ]]; then
    checkdeps p11tool
    local yubikey_serials=()
    readarray -t yubikey_serials < <(p11tool --list-token-urls | grep manufacturer=Yubico%20%28www.yubico.com%29 | sed 's/.*;serial=\([0-9]\+\);.*/\1/g')
    [[ ${#yubikey_serials[@]} -gt 0 ]] || fatal "No YubiKeys found"
    [[ ${#yubikey_serials[@]} -eq 1 ]] || fatal "%d YubiKeys detected, remove all but one" "${#yubikey_serials[@]}"
    if [[ -z $PIN ]]; then
      export PIN
      PIN=$(pinentry-wrapper "PIN" --desc "Smallstep CLI requires access to your YubiKey in order to authenticate with step-ca
YubiKey #${yubikey_serials[0]}")
    fi
    additional_opts+=(
      -e "YKSERIAL=${yubikey_serials[0]}" -e PIN
      -v "$p11_kit_socket:$p11_kit_socket"
    )
  else
    verbose "Socket '%s' not found, skipping p11-kit forwarding" "$p11_kit_socket"
  fi
  if [[ -t 0 && -t 1 ]]; then
    additional_opts+=("-t")
  else
    additional_opts+=(-a stdout -a stderr)
  fi
  if [[ $1 = 'root' ]]; then
    shift
    additional_opts+=(--entrypoint /bin/bash)
    cmd=("$@")
  elif [[ $1 = 'user' ]]; then
    shift
    cmd=("$@")
  else
    cmd=(step-wrapper "$@")
  fi
  # shellcheck disable=2086,2068
  docker run --rm -i \
    ${additional_opts[@]} \
    -e TMP=/tmp --tmpfs /tmp \
    -e HOME -e "UID=$(id -u)" \
    -v "$PWD:$HOME/pwd" \
    --tmpfs $HOME/.step/config \
    -v "$STEPPATH:/external-steppath:ro" \
    -v "$STEPPATH/config/defaults.json:/step-config-template.json:ro" \
    "secoya/smallstep-wrapper:$version" \
    ${cmd[@]}
}

main "$@"
