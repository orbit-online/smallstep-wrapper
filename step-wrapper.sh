#!/usr/bin/env bash

main() {
  set -eo pipefail
  shopt -s inherit_errexit

  export STEPPATH=$HOME/.step
  local config config_path=$HOME/.step/config/defaults.json
  config=$(cat /step-config-template.json)
  config=$(jq '.root=(.root | sub("\\$STEPPATH"; "/external-steppath"; "g"))' <<<"$config")
  if [[ -n $YKSERIAL ]]; then
    config=$(jq --arg serial "${YKSERIAL:?}" --arg pin "${PIN:?}" \
      '.kms="pkcs11:module-path=/usr/lib/pkcs11/p11-kit-client.so;token=YubiKey%20PIV%20%23\($serial)?pin-value=\($pin)" |
      .["x5c-cert"]="pkcs11:token=YubiKey%20PIV%20%23\($serial);object=X.509%20Certificate%20for%20PIV%20Authentication" |
      .["x5c-key"]="pkcs11:token=YubiKey%20PIV%20%23\($serial);object=Private%20key%20for%20PIV%20Authentication"' <<<"$config")
  fi
  printf '%s\n' "$config" >"$config_path"
  exec step "$@"
}

main "$@"
