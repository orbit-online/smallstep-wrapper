#!/usr/bin/env bash

step() {
  set -eo pipefail
  shopt -s inherit_errexit
  local pkgroot
  pkgroot=$(upkg root "${BASH_SOURCE[0]}")
  PATH="$pkgroot/.upkg/.bin:$PATH"
  # shellcheck source=.upkg/orbit-online/records.sh/records.sh
  source "$pkgroot/.upkg/orbit-online/records.sh/records.sh"
  checkdeps docker jq

  : "${STEP_URL:?"\$STEP_URL is required"}"
  : "${STEP_ROOT_FP:?"\$STEP_ROOT_FP is required"}"

  local version image additional_opts=() cmd=()
  version=$(image-version "$(jq -re '.version // empty' "$pkgroot/upkg.json" 2>/dev/null || git symbolic-ref HEAD)")
  image=secoya/smallstep-wrapper:$version

  local p11_kit_socket="$XDG_RUNTIME_DIR/p11-kit/pkcs11"
  if [[ -S "$p11_kit_socket" ]] && ! ${STEP_SKIP_P11_KIT:-false}; then
    checkdeps p11tool
    local yubikey_serials=()
    readarray -t yubikey_serials < <(p11tool --list-token-urls | grep manufacturer=Yubico%20%28www.yubico.com%29 | sed 's/.*;serial=\([0-9]\+\);.*/\1/g')
    [[ ${#yubikey_serials[@]} -gt 0 ]] || fatal "No YubiKeys found"
    [[ ${#yubikey_serials[@]} -eq 1 ]] || fatal "%d YubiKeys detected, remove all but one" "${#yubikey_serials[@]}"
    if [[ -z $PIN ]]; then
      export PIN
      # shellcheck disable=2059
      PIN=$(pinentry-wrapper "PIN" --desc "$(printf -- "${STEP_PIN_DESC:-"Smallstep CLI requires access to your YubiKey in order to authenticate with step-ca
YubiKey #%s"}" "${yubikey_serials[0]}")")
    fi
    additional_opts+=(
      -e "YKSERIAL=${yubikey_serials[0]}" -e PIN
      -v "$p11_kit_socket:$p11_kit_socket"
    )
  elif ${STEP_SKIP_P11_KIT:-false}; then
    verbose "p11-kit socket forwarding disabled"
  else
    verbose "Socket '%s' not found, skipping p11-kit forwarding" "$p11_kit_socket"
  fi
  local envvar
  for envvar in $(env | grep '^STEP' | cut -d= -f1); do
    [[ $envvar != 'STEPPATH' ]] || continue
    additional_opts+=(-e "$envvar")
  done
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
  [[ $(docker images -q "$image" 2>/dev/null) != "" ]] || info "Pulling %s" "$image"
  # shellcheck disable=2086,2068
  docker run --quiet --rm -i \
    ${additional_opts[@]} \
    -e TMP=/tmp --tmpfs /tmp -e HOME -e "UID=$(id -u)" \
    -v "$PWD:$HOME/pwd" --tmpfs $HOME/.step \
    "secoya/smallstep-wrapper:$version" \
    ${cmd[@]}
}

step "$@"
