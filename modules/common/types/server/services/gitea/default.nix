{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.services.gitea;
  inherit (config.networking) domain;
  gitea_domain = "git.${domain}";

  # stole this from https://git.winston.sh/winston/deployment-flake/src/branch/main/config/services/gitea.nix who stole it from https://github.com/getchoo
  theme = pkgs.fetchzip {
    url = "https://github.com/catppuccin/gitea/releases/download/v0.4.1/catppuccin-gitea.tar.gz";
    sha256 = "sha256-14XqO1ZhhPS7VDBSzqW55kh6n5cFZGZmvRCtMEh8JPI=";
    stripRoot = false;
  };
in {
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      config.services.gitea.settings.server.HTTP_PORT
      config.services.forgejo.settings.server.SSH_PORT
    ];

    modules.system.services.database = {
      redis.enable = true;
      postgresql.enable = true;
    };

    systemd.services = {
      gitea = {
        after = ["sops-nix.service"];
        preStart = let
          inherit (config.services.gitea) stateDir;
        in
          lib.mkAfter ''
            rm -rf ${stateDir}/custom/public
            mkdir -p ${stateDir}/custom/public
            ln -sf ${theme} ${stateDir}/custom/public/css
          '';
      };
    };

    services = {
      gitea = {
        enable = true;
        package = pkgs.forgejo;
        appName = "iztea";
        stateDir = "/srv/storage/gitea/data";

        mailerPasswordFile = config.sops.secrets.mailserver-gitea-nohash.path;

        settings = {
          server = {
            ROOT_URL = "https://${gitea_domain}";
            HTTP_PORT = 7000;
            DOMAIN = "${gitea_domain}";

            START_SSH_SERVER = false;
            BUILTIN_SSH_SERVER_USER = "git";
            SSH_PORT = 30;
            DISABLE_ROUTER_LOG = true;
            SSH_CREATE_AUTHORIZED_KEYS_FILE = true;
            LANDING_PAGE = "/explore/repos";
          };

          default.APP_NAME = "iztea";
          attachment.ALLOWED_TYPES = "*/*";
          service.DISABLE_REGISTRATION = true;

          ui = {
            DEFAULT_THEME = "catppuccin-mocha-sapphire";
            THEMES =
              builtins.concatStringsSep
              ","
              (["auto,forgejo-auto,forgejo-dark,forgejo-light,arc-gree,gitea"]
                ++ (map (name: lib.removePrefix "theme-" (lib.removeSuffix ".css" name))
                  (builtins.attrNames (builtins.readDir theme))));
          };

          actions = {
            ENABLED = true;
            DEFAULT_ACTIONS_URL = "https://code.forgejo.org";
          };

          database = {
            DB_TYPE = lib.mkForce "postgres";
            HOST = "/run/postgresql";
            NAME = "gitea";
            USER = "gitea";
            PASSWD = "gitea";
          };

          cache = {
            ENABLED = true;
            ADAPTER = "redis";
            HOST = "redis://:gitea@localhost:6371";
          };

          migrations.ALLOWED_DOMAINS = "github.com, *.github.com, gitlab.com, *.gitlab.com";
          packages.ENABLED = false;
          repository.PREFERRED_LICENSES = "MIT,GPL-3.0,GPL-2.0,LGPL-3.0,LGPL-2.1";

          "repository.upload" = {
            FILE_MAX_SIZE = 100;
            MAX_FILES = 10;
          };

          mailer = {
            ENABLED = true;
            PROTOCOL = "smtps";
            SMTP_ADDR = "mail.${domain}";
            USER = "git@${domain}";
          };
        };

        # backup
        dump = {
          enable = true;
          backupDir = "/srv/storage/forgejo/dump";
          interval = "06:00";
          type = "tar.zst";
        };
      };
    };
  };
}
