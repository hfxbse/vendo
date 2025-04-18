# vendo

Drink vending machine software designed to run on a Raspberry PI.

# Debugging

## Locally

To test the firmware locally run

```shell
DATA_DIR=./var/lib/vendo nix run .#flutter-elinux --impure -- run
```

While in debug mode, if the GPIO chip of the Raspberry Pi cannot be found, the hardware drivers are replaced with a
Keyboard listener.

| Key    | Simulated action                                                                                    |
|--------|-----------------------------------------------------------------------------------------------------|
| 0 to 9 | Inserting a coin to the coin selector with the value at that particular slot. 0 represents slot 10. |
| d      | Completing the dispensation of a drink                                                              |

## Remote on a Raspberry Pi

Add the device as a custom device to Flutter as described in the
[Wiki](https://github.com/sony/flutter-elinux/wiki/Remote-target-devices).

To create a debug build run

```shell
nix run .#flutter-elinux -- build elinux --target-arch=arm64 --debug --target-backend-type=gbm
```

To run the binary without Nix as the actively used package manager, the patches applied to the ELF file need to be
reversed.
In case of Debian and similar distributions, this includes setting the interpreter

```shell
patchelf --set-interpreter "/lib/ld-linux-aarch64.so.1" <file>" 
```

and setting `LD_LIBRARY_PATH` to the app bundles `lib` directory.

This can be automated within the custom device config like this:

```json
{
  "runDebug": [
    "ssh",
    "vendo@vendo.local",
    "patchelf --set-interpreter \"/lib/ld-linux-aarch64.so.1\" \"/tmp/${appName}/${appName}\" && DATA_DIR=./var/lib/${appName} LD_LIBRARY_PATH=\"/tmp/${appName}/lib\" /tmp/${appName}/${appName} -b . -r 90"
  ]
}

```
