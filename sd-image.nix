{
  config,
  pkgs,
  lib,
  ...
}:
let
  rkbin = pkgs.stdenv.mkDerivation {
    pname = "rkbin";
    version = "2024-10-23";

    src = pkgs.fetchFromGitHub {
      owner = "rockchip-linux";
      repo = "rkbin";
      rev = "7c35e21a8529b3758d1f051d1a5dc62aae934b2b";
      hash = "sha256-KBmO++Z1AfIKvAmx7CzXScww16Stvq2BWr2raPiR6Q8=";
    };

    installPhase = ''
      mkdir $out
      mv bin doc $out/
    '';

    BL31_RK3566 = "bin/rk35/rk3566_ddr_1056MHz_v1.23.bin";
    ROCKCHIP_TPL_RK3566 = "bin/rk35/rk3566_ddr_1056MHz_v1.23.bin";

    meta = with pkgs.lib; {
      description = "Rockhip proprietary bootloader blobs";
      homepage = "https://github.com/rockhip-linux/rkbin";
      license = licenses.unfree;
      platforms = [ "aarch64-linux" ];
    };
  };

  firmware = pkgs.buildArmTrustedFirmware rec {
    extraMakeFlags = [ "bl31" ];
    platform = "rk3588"; # for rk3566 & rk3568
    extraMeta.platforms = [ "aarch64-linux" ];
    filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
    platformCanUseHDCPBlob = true;
/*
    src = pkgs.fetchFromGitHub {
      owner = "ARM-software";
      repo = "arm-trusted-firmware";
      # Commit that addded support for rk3566/rk3568
      rev = "9fd9f1d024872b440e3906eded28037330b6f422";
      hash = "sha256-xYXZgysxQOiMVIZOlJSzLR7bT451gAoF0vXgZWiPcxo=";
    };
*/
        src = pkgs.fetchFromGitLab {
      domain = "gitlab.collabora.com";
      owner = "hardware-enablement/rockchip-3588";
      repo = "trusted-firmware-a";
      rev = "002d8e85ce5f4f06ebc2c2c52b4923a514bfa701";
      hash = "sha256-1XOG7ILIgWa3uXUmAh9WTfSGLD/76OsmWrUhIxm/zTg=";
    };
  };

  uboot = pkgs.buildUBoot {
    defconfig = "radxa-zero-3-rk3566_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
    BL31 = "${firmware}/bl31.elf";
    ROCKCHIP_TPL = "${rkbin}/${rkbin.ROCKCHIP_TPL_RK3566}";
    filesToInstall = [ "u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" ];
  };

  firmwareConfigTxt = pkgs.writeText "config.txt" ''
    [all]
    kernel=u-boot-radxa-zero-3e.bin
    arm_64bit=1
    enable_uart=1
    avoid_warnings=1
  '';
in
{
#  imports = [
#    <nixpkgs/nixos/modules/profiles/base.nix>
#    <nixpkgs/nixos/modules/installer/sd-card/sd-image.nix>
#  ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.consoleLogLevel = lib.mkDefault 7;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "rkbin"
    "arm-trusted-firmware-rk3568" # for rk3566 & rk3568
    "arm-trusted-firmware-rk3588"
  ];

  sdImage = {
    populateFirmwareCommands = ''
      cp ${firmwareConfigTxt} firmware/config.txt

      cp ${uboot}/u-boot.bin firmware/u-boot-radxa-zero-3e.bin
    '';

    populateRootCommands = ''
      mkdir =p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  system.stateVersion = "24.11";
}
