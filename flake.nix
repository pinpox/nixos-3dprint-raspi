{
  description = "RPi 3+ image for thermal printer photobooth";

  inputs = {

    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    {

      nixosConfigurations.nixos-3dprint-raspi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./raspi.nix
          ./configuration.nix

          {
            nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
            nix.registry.nixpkgs.flake = nixpkgs;
            sdImage.compressImage = false;
            sdImage.imageBaseName = "raspi-image";

          }
        ];
      };
    } //

    flake-utils.lib.eachDefaultSystem (system:
      {
        packages = flake-utils.lib.flattenTree {

          # Generate a sd-card image for the pi
          # nix build '.#raspi-image'
          raspi-image = self.nixosConfigurations.nixos-3dprint-raspi.config.system.build.sdImage;
        };
      });
}
