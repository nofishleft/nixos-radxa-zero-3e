{
  config,
  pkgs,
  lib,
  ...
}:
let
  uboot = pkgs.buildUBoot {
    defconfig = "radxa-zero-3-rk3566_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
    BL31 = "${pkgs.rkbin.BL31_RK3568}";
    ROCKCHIP_TPL = "${pkgs.rkbin.TPL_RK3568}";
    filesToInstall = [ "u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" ];
  };

  firmwareConfigTxt = pkgs.writeText "config.txt" ''
    [all]
    kernel=u-boot-rockchip.bin
    arm_64bit=1
    enable_uart=1
    avoid_warnings=1
  '';
in
{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.consoleLogLevel = lib.mkDefault 7;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "rkbin-unstable"
  ];

  sdImage = {
    populateFirmwareCommands = ''
      cp ${firmwareConfigTxt} firmware/config.txt

      cp ${uboot}/*.bin ${uboot}/*.itb firmware/
    '';

    populateRootCommands = ''
      mkdir =p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  system.stateVersion = "24.11";
}
