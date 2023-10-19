{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) optionals mkIf mkDefault;
  sys = config.modules.system;
  cfg = sys.virtualization;
in {
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      optionals cfg.qemu.enable [
        virt-manager
        virt-viewer
      ]
      ++ optionals cfg.docker.enable [
        podman
        podman-compose
      ]
      ++ optionals (cfg.docker.enable && sys.video.enable) [
        lxd
      ]
      ++ optionals cfg.distrobox.enable [
        distrobox
      ]
      ++ optionals cfg.waydroid.enable [
        waydroid
      ];

    virtualisation = {
      # qemu
      kvmgt.enable = cfg.qemu.enable && config.modules.device.type == "intel";
      spiceUSBRedirection.enable = cfg.qemu.enable;
      libvirtd = mkIf cfg.qemu.enable {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          ovmf = {
            enable = true;
            packages = [pkgs.OVMFFull.fd];
          };
          swtpm.enable = true;
        };
      };

      # podman
      podman = mkIf cfg.docker.enable {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings = {
          dns_enabled = true;
        };
        enableNvidia = builtins.any (driver: driver == "nvidia") config.services.xserver.videoDrivers;
        autoPrune = {
          enable = true;
          flags = ["--all"];
          dates = "weekly";
        };
      };

      waydroid.enable = cfg.waydroid.enable;
      lxd.enable = mkDefault config.virtualisation.waydroid.enable;
    };
    systemd.user = mkIf cfg.distrobox.enable {
      timers."distrobox-update" = {
        enable = true;
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "1h";
          OnUnitActiveSec = "1d";
          Unit = "distrobox-update.service";
        };
      };

      services."distrobox-update" = {
        enable = true;
        script = ''
          ${pkgs.distrobox}/bin/distrobox upgrade --all
        '';
        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
  };
}
