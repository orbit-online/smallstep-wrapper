#!/usr/bin/env bash

step_wrapper() {
  set -eo pipefail
  shopt -s inherit_errexit

  export STEPPATH=${HOME:?}/.step
  local bs_out bs_ret
  if bs_out=$(step ca bootstrap --ca-url="${STEP_URL:?}" --fingerprint="${STEP_ROOT_FP:?}" 2>&1); then
    :
  else
    bs_ret=$?
    printf "%s\n" "$bs_out" >&2
    return $bs_ret
  fi
  local config config_path=$STEPPATH/config/defaults.json
  config=$(cat "$config_path")
  if [[ -n $YKSERIAL ]]; then
    config=$(jq --arg serial "${YKSERIAL:?}" --arg pin "${PIN:?}" \
      '.kms="pkcs11:module-path=/usr/lib/pkcs11/p11-kit-client.so;token=YubiKey%20PIV%20%23\($serial)?pin-value=\($pin)" |
      .["x5c-cert"]="pkcs11:token=YubiKey%20PIV%20%23\($serial);object=X.509%20Certificate%20for%20PIV%20Authentication" |
      .["x5c-key"]="pkcs11:token=YubiKey%20PIV%20%23\($serial);object=Private%20key%20for%20PIV%20Authentication"' <<<"$config")
  fi
  printf '%s\n' "$config" >"$config_path"
  exec step "$@"
}

step_wrapper "$@"
