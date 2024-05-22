# smallstep-wrapper

A containerized smallstep step-cli that mounts your p11-kit socket (if it exists)
and configures communication with your YubiKey.

The config is bootstrapped through the environment variables `$STEP_URL` and
`$STEP_ROOT_FP`.

The current working directory is also mounted, meaning relative arguments to files
under `$PWD` will work.

## Installation

See [the latest release](https://github.com/orbit-online/smallstep-wrapper/releases/latest) for instructions.

## Environment variables

All `$STEP` prefixed environment variables are forwarded (see the
[smallstep docs](https://smallstep.com/docs/step-cli/the-step-command/#environment-variables)
for more info).  
There are also a few env vars that modify the behavior of the wrapper:

| Name                 | Description                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------ |
| `$STEP_URL`          | URL to the step-ca `required`                                                              |
| `$STEP_ROOT_FP`      | Fingerprint of the step-ca root certificate `required`                                     |
| `$STEP_PIN_DESC`     | The description in the YubiKey PIN prompt modal (`%s` is replaced with the YubiKey serial) |
| `$STEP_SKIP_P11_KIT` | Do not mount the p11-kit socket (`true`/`false`)                                           |
