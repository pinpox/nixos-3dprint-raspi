# Build Image

```sh
nix build '.#raspi-image'
```

# Reprovision

```sh
nixos-rebuild switch --flake '.#nixos-3dprint-raspi' --target-host root@192.168.2.121
```
