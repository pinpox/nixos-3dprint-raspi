{ config, pkgs, lib, ... }: {

  ###############
  # 3D-Printing #
  ###############

  services.octoprint = {
    enable = true;
    # port = 5000; # Default
    # host = 0.0.0.0 # Default
    openFirewall = true;
    # extraConfig = {}; # Converted to YAML
    # plugins = plugins: with plugins; [ octolapse ];
  };


  systemd.services.octoprint.serviceConfig.SupplementaryGroups = [ "video" ];
  users.users.octoprint.extraGroups = [ "video" ];

  systemd.services.motion = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart =
      "${pkgs.motion}/bin/motion -c ${./motion.conf}";
  };

  networking.firewall.allowedTCPPorts = [ 8081 8082 ];


  #################
  # GENERAL STUFF #
  #################

  system.stateVersion = 23.05;

  # Define a user account.
  users.users.root = {
    openssh.authorizedKeys.keyFiles = [
      (pkgs.fetchurl {
        url = "https://github.com/pinpox.keys";
        sha256 = "sha256-V0ek+L0axLt8v1sdyPXHfZgkbOxqwE3Zw8vOT2aNDcE=";
      })
    ];
  };

  # Time zone and internationalisation
  time = { timeZone = "Europe/Berlin"; };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  # Networking and SSH
  networking = {
    hostName = "nixos-3dprint-raspi";
    interfaces.eth0 = { useDHCP = true; };
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    startWhenNeeded = true;
    kbdInteractiveAuthentication = false;
  };

  # Nix settings
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      # Free up to 1GiB whenever there is less than 100MiB left.
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';

    settings = {
      # Save space by hardlinking store files
      auto-optimise-store = true;
      allowed-users = [ "root" ];
    };

    # Clean up old generations after 30 days
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
