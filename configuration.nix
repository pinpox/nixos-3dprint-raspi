{ config, pkgs, lib, ... }: {

  ###############
  # 3D-Printing #
  ###############

  services.octoprint = {
    enable = true;
    # port = 5000; # Default
    # host = 0.0.0.0 # Default
    openFirewall = true;

    # Converted to YAML
    extraConfig = {
      # plugins = plugins: with plugins; [ octolapse ];

      # Start and stop the webcam stream when printer is connected/disconnected
      events = {
        enabled = "True";
        subscriptions = [
          {
            event = "Connected";
            command = "/run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl start vlcstream.service";
            type = "system";
          }
          {
            event = "Disconnected";
            command = "/run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl stop vlcstream.service";
            type = "system";
          }
          # - PrintFailed
          # - PrintDone
        ];
      };
    };
  };

  # Allow octoprint user to start/stop/restart the VLC stream stervice without password
  security.sudo.enable = true;
  security.sudo.extraRules = [

    # Allow execution of "/home/root/secret.sh" by user `backup`, `database`
    # and the group with GID `1006` without a password.
    {
      users = [ "octoprint" ];
      commands = [
        { command = "${pkgs.systemd}/bin/systemctl start vlcstream.service"; options = [ "SETENV" "NOPASSWD" ]; }
        { command = "${pkgs.systemd}/bin/systemctl stop vlcstream.service"; options = [ "SETENV" "NOPASSWD" ]; }
        { command = "${pkgs.systemd}/bin/systemctl stop vlcstream.service"; options = [ "SETENV" "NOPASSWD" ]; }
      ];
    }
  ];

  # Service to stream webcam using VLC
  systemd.services.vlcstream = {
    serviceConfig = {
      User = "octoprint";
      Group = "octoprint";
      ExecStart = ''
        ${pkgs.vlc}/bin/cvlc v4l2:///dev/video0 \
        --sout '#transcode{vcodec=mjpg}:std{access=http{mime=multipart/x-mixed-replace;boundary=-7b3cc56e5f51db803f790dad720ed50a},mux=mpjpeg,dst=192.168.2.121:8081}'
      '';
    };
  };

  systemd.services.octoprint.serviceConfig.SupplementaryGroups = [ "video" ];
  users.users.octoprint.extraGroups = [ "video" ];

  networking.firewall.allowedTCPPorts = [ 8081 ];

  #################
  # GENERAL STUFF #
  #################

  system.stateVersion = "23.05";

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
    settings.PasswordAuthentication = false;
    startWhenNeeded = true;
    settings.KbdInteractiveAuthentication = false;
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
