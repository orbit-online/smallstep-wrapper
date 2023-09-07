# smallstep-wrapper

A containerized smallstep step-cli that mounts your p11-kit socket (if it exists)
and configures communication with your YubiKey.

It mounts `$STEPPATH` and extends your configuration with the necessary settings.
`$STEPPATH` in the config will be replaced with the mounted path inside the container
(currently only implemented for the `root` setting).

The current working directory is also mounted, meaning relative arguments to files
under `$PWD` will work.

## Installation

With [μpkg](https://github.com/orbit-online/upkg)

```
upkg install -g orbit-online/smallstep-wrapper@<VERSION>
```

## Environment variables

All `$STEP` prefixed environment variables are forwarded (see the
[smallstep docs](https://smallstep.com/docs/step-cli/the-step-command/#environment-variables)
for more info).  
There are also a few env vars that modify the behavior of the wrapper:

| Name                 | Description                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------ |
| `$STEP_PIN_DESC`     | The description in the YubiKey PIN prompt modal (`%s` is replaced with the YubiKey serial) |
| `$STEP_SKIP_P11_KIT` | Do not mount the p11-kit socket (`true`/`false`)                                           |
