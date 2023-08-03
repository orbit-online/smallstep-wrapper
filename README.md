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
upkg install -g orbit-online/smallstep-wrapper
```
