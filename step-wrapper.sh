#!/usr/bin/env bash

step_wrapper() {
  set -eo pipefail; shopt -s inherit_errexit

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
  if [[ -n $TOKEN_URL ]]; then
    case "$(get_pkcs11_url_val model <<<"${TOKEN_URL:?}")" in
      YubiKey*)
        config=$(jq --arg token_url "$TOKEN_URL" --arg pin "${PIN:?}" \
          '.kms="pkcs11:module-path=/usr/lib/pkcs11/p11-kit-client.so;\($token_url)?pin-value=\($pin)" |
          .["x5c-cert"]="pkcs11:\($token_url);object=X.509%20Certificate%20for%20PIV%20Authentication" |
          .["x5c-key"]="pkcs11:\($token_url);object=Private%20key%20for%20PIV%20Authentication"' <<<"$config")
        ;;
      Intel*)
        config=$(jq --arg token_url "$TOKEN_URL" --arg pin "${PIN:?}" \
          '.kms="pkcs11:module-path=/usr/lib/pkcs11/p11-kit-client.so;\($token_url)?pin-value=\($pin)" |
          .["x5c-cert"]="pkcs11:\($token_url);object=PIV;" |
          .["x5c-key"]="pkcs11:\($token_url);object=PIV;type=private"' <<<"$config")
        ;;
    esac
  fi
  printf '%s\n' "$config" >"$config_path"
  exec step "$@"
}

get_pkcs11_url_val() {
  local field=$1
  sed 's/^pkcs11:\(.*;\)\?\('"$field"'=\([^;]\+\)\)\?\(;.*\)\?$/\3/g' | grep -v '^pkcs11:'
}

step_wrapper "$@"
