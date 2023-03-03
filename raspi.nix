{ config, pkgs, lib, ... }: {

  # Hardware-specific settings

  # Required for the Wireless firmware
  hardware.enableRedistributableFirmware = true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  boot = {

    # kernelParams = [ "console=ttyS1,115200n8" ];

    loader = {
      raspberryPi = {
        firmwareConfig = ''
          dtparam=poe_fan_temp0=50000
          dtparam=poe_fan_temp1=60000
          dtparam=poe_fan_temp2=70000
          dtparam=poe_fan_temp3=80000
        '';
      };
    };
  };


  boot.initrd.availableKernelModules = [ "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Use 1GB of additional swap memory in order to not run out of memory
  # when installing lots of things while running other things at the same time.
  # swapDevices = [{ device = "/swapfile"; size = 1024; }];
  swapDevices = [ ];

  ##############################

  # boot.kernelPackages = pkgs.linuxPackages_rpi3;
  environment.systemPackages = with pkgs; [

    # Needed for operation
    libraspberrypi

    # Optional, for development
    git

  ];

  # File systems configuration for using the installer's partition layout
  # fileSystems = {
  #   "/boot" = {
  #     device = "/dev/disk/by-label/NIXOS_BOOT";
  #     fsType = "vfat";
  #   };
  #   "/" = {
  #     device = "/dev/disk/by-label/NIXOS_SD";
  #     fsType = "ext4";
  #   };
  # };

  # boot.supportedFilesystems = ["ext4"];

  # Preserve space by sacrificing documentation and history
  # documentation.nixos.enable = false;
  # boot.cleanTmpDir = true;
}
