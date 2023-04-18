# nixos-3dprint-raspi

This Nix Flake provides the configuration of the Raspberry Pi 4 controlling my
Ender 3v2 Neo 3D-printer. The image can be flashed with dd and booted directly
or the configuration re-provisioned after the initial flash.

The Raspberry has a USB-webcam connected to it for livestreaming 

## Build Image

```sh
nix build '.#raspi-image'
```

Flash with (adjust path of your SD-card):
```sh
dd bs=4M if=result/sd-image/raspi-image-23.05.20230228.68196a6-aarch64-linux.img of=/dev/sdX status=progress oflag=sync
```

## Reprovision

```sh
nixos-rebuild switch --flake '.#nixos-3dprint-raspi' --target-host root@192.168.2.121
```
