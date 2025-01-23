{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: let
    configuration = nixpkgs.lib.nixosSystem {
      modules = [
        "${nixpkgs}/nixos/modules/profiles/base.nix"
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
        ./sd-image.nix
        {
          nixpkgs.config.allowUnsupportedSystem = true;
          nixpkgs.hostPlatform.system = "aarch64-linux";
          nixpkgs.buildPlatform.system = "x86_64-linux";
        }
      ];
    };

    image = configuration.config.system.build.sdImage;
  in {
    nixosConfigurations.radxaZero3e = configuration;
    images.radxaZero3e = image;
  };
}
