{ config, pkgs, lib, ... }: {

  # Restart klipper and moonraker on config changes
  systemd.services.klipper.restartTriggers = [
    config.services.klipper.configFile
  ];

  systemd.services.moonraker.restartTriggers = [
    config.services.klipper.configFile
  ];

  services.klipper = {
    enable = true;
    configFile = ./ender3-klipper.cfg;

    # mutableConfig = false;
    # Whether to copy the config to a mutable directory instead of using the one
    # directly from the nix store. This will only copy the config if the file at
    # services.klipper.mutableConfigPath doesn’t exist.

    firmwares.ender3 = {
      enable = true;
      enableKlipperFlash = true;
      serial = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0";
      # https://github.com/Klipper3d/klipper/blob/master/config/printer-creality-ender3-v2-neo-2022.cfg
      configFile = ./ender3-klipper-firmware.cfg;
    };
  };

  services.mainsail = {
    enable = true;
    # hostName = "localhost";
  };

security.polkit.enable = true;

  services.moonraker = {
    enable = true;
    allowSystemControl = true; # for reboot and systemd unit control and starting/stopping ustreamer
    address = "0.0.0.0";
    user = "klipper";
    group = "klipper";
    settings = {



      "power ender3" = {
        type = "shelly";
        #   The type of device.  Can be either gpio, klipper_device, rf,
        #   tplink_smartplug, tasmota, shelly, homeseer, homeassistant, loxonev1,
        #   smartthings, mqtt or hue.
        #   This parameter must be provided.
        initial_state = "off";
        #    The state the power device should be initialized to.  May be on or
        #    off.  When this option is not specifed no initial state will be set.
        off_when_shutdown = true;
        #   If set to True the device will be powered off when Klipper enters
        #   the "shutdown" state.  This option applies to all device types.
        #   The default is False.
        off_when_shutdown_delay = 0;
        #   If "off_when_shutdown" is set, this option specifies the amount of time
        #   (in seconds) to wait before turning the device off. Default is 0 seconds.
        on_when_job_queued = true;
        #   If set to True the device will power on if a job is queued while the
        #   device is off.  This allows for an automated "upload, power on, and
        #   print" approach directly from the slicer, see the configuration example
        #   below for details. The default is False.
        locked_while_printing = true;
        #   If True, locks the device so that the power cannot be changed while the
        #   printer is printing. This is useful to avert an accidental shutdown to
        #   the printer's power.  The default is False.
        restart_klipper_when_powered = true;
        #   If set to True, Moonraker will schedule a "FIRMWARE_RESTART" to command
        #   after the device has been powered on. If it isn't possible to immediately
        #   schedule a firmware restart (ie: Klippy is disconnected), the restart
        #   will be postponed until Klippy reconnects and reports that startup is
        #   complete.  Prior to scheduling the restart command the power device will
        #   always check Klippy's state.  If Klippy reports that it is "ready", the
        #   FIRMWARE_RESTART will be aborted as unnecessary.
        #   The default is False.
        # restart_delay: 1.
        #   If "restart_klipper_when_powered" is set, this option specifies the amount
        #   of time (in seconds) to delay the restart.  Default is 1 second.
        bound_services = [ "ustreamer" ];
        #   A newline separated list of services that are "bound" to the state of this
        #   device.  When the device is powered on all bound services will be started.
        #   When the device is powered off all bound services are stopped.
        #
        #   The items in this list are limited to those specified in the allow list,
        #   see the [machine] configuration documentation for details.  Additionally,
        #   the Moonraker service can not be bound to a power device.  Note that
        #   service names are case sensitive.
        #
        #   When the "initial_state" option is explcitly configured bound services
        #   will be synced with the current state.  For example, if the initial_state
        #   is "off", all bound services will be stopped after device initialization.
        #
        #   The default is no services are bound to the device.

        address = "192.168.2.142";
        #   A valid ip address or hostname for the shelly device.  This parameter
        #   must be provided.
        # user:
        #   A user name to use for request authentication.  This option accepts
        #   Jinja2 Templates, see the [secrets] section for details.  If no password
        #   is set the the default is no user, otherwise the default is "admin".
        # password:
        #   The password to use for request authentication.  This option accepts
        #   Jinja2 Templates, see the [secrets] section for details. The default is no
        #   password.
        # output_id:
        #   The output_id (or relay id) to use if the Shelly device supports
        #   more than one output.  Default is 1.
      };




      "webcam Chamber" = {
        location = "Chamber";
        service = "mjpegstreamer";
        target_fps = 30;
        target_fps_idle = 5;
        stream_url = "http://192.168.2.121:8081/stream";
        snapshot_url = "http://192.168.2.121:8081/snapshot";
        # flip_horizontal: False
        # flip_vertical: False
        # aspect_ratio: 4:3
      };

      history = { };
      authorization = {
        force_logins = true;
        cors_domains = [
          "*.local"
          "*.lan"
          "*://app.fluidd.xyz"
          "*://my.mainsail.xyz"
          "*"
        ];
        trusted_clients = [
          "10.0.0.0/8"
          "127.0.0.0/8"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "192.168.1.0/24"
          "FE80::/10"
          "::1/128"
        ];
      };
    };
  };

  ###############
  # 3D-Printing #
  ###############

  systemd.services.ustreamer = {
    # --format=uyvy \ # Device input format
    # --workers=3 \ # Workers number
    #  --dv-timings \ # Use DV-timings
    wantedBy = [ "multi-user.target" ];
    description = "uStreamer for video0";
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.ustreamer}/bin/ustreamer \
        --encoder=HW \
        --persistent \
        --drop-same-frames=30 \
        --host=0.0.0.0 \
        --port=8081
      '';
    };
  };

  # services.octoprint = {
  #   enable = true;
  #   # port = 5000; # Default
  #   # host = 0.0.0.0 # Default
  #   openFirewall = true;

  #   # Converted to YAML
  #   extraConfig = {
  #     # plugins = plugins: with plugins; [ octolapse ];

  #     # Start and stop the webcam stream when printer is connected/disconnected
  #     events = {
  #       enabled = "True";
  #       subscriptions = [
  #         {
  #           event = "Connected";
  #           command = "/run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl start vlcstream.service";
  #           type = "system";
  #         }
  #         {
  #           event = "Disconnected";
  #           command = "/run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl stop vlcstream.service";
  #           type = "system";
  #         }
  #         # - PrintFailed
  #         # - PrintDone
  #       ];
  #     };
  #   };
  # };

  # Allow octoprint user to start/stop/restart the VLC stream stervice without password
  # security.sudo.enable = true;
  # security.sudo.extraRules = [

  #   # Allow execution of "/home/root/secret.sh" by user `backup`, `database`
  #   # and the group with GID `1006` without a password.
  #   {
  #     users = [ "octoprint" ];
  #     commands = [
  #       { command = "${pkgs.systemd}/bin/systemctl start vlcstream.service"; options = [ "SETENV" "NOPASSWD" ]; }
  #       { command = "${pkgs.systemd}/bin/systemctl stop vlcstream.service"; options = [ "SETENV" "NOPASSWD" ]; }
  #       { command = "${pkgs.systemd}/bin/systemctl stop vlcstream.service"; options = [ "SETENV" "NOPASSWD" ]; }
  #     ];
  #   }
  # ];



  # Service to stream webcam using VLC
  # systemd.services.vlcstream = {
  #   serviceConfig = {
  #     User = "octoprint";
  #     Group = "octoprint";
  #     ExecStart = ''
  #       ${pkgs.vlc}/bin/cvlc v4l2:///dev/video0 \
  #       --sout '#transcode{vcodec=mjpg}:std{access=http{mime=multipart/x-mixed-replace;boundary=-7b3cc56e5f51db803f790dad720ed50a},mux=mpjpeg,dst=192.168.2.121:8081}'
  #     '';
  #   };
  # };

  # systemd.services.octoprint.serviceConfig.SupplementaryGroups = [ "video" ];
  # users.users.octoprint.extraGroups = [ "video" ];

  networking.firewall.allowedTCPPorts = [
    8081 # webcam stream
    80 # mainsail
    config.services.moonraker.port
  ];

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
