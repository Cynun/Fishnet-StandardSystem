{ config, lib, pkgs, ... }:

{
  options = {
    fishnet.services.gitea = {
      enable = lib.mkEnableOption "fishnet.services.gitea";
      name = lib.mkOption {
        description = "Give the site a name";
        example = "My awesome Gitea server";
        type = lib.types.string;
      };
      domain = lib.mkOption {
        descriptin = "Domain of gitea";
        example = "git.my-domain.tld";
        type = lib.types.string;
      };
      dbpass = lib.mkOption {
        # TODO:config.sops.secrets."postgres/gitea_dbpass".path;
        description = "Postgresql database password";
        example = "builtins.readFile ./gitea_dbpass";
        type = lib.types.string;
      };
    };
  };

  config = lib.mkIf config.fishnet.services.gitea.enable {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services = {
      dnsmasq.settings = {
        address = [ "/${config.fishnet.services.gitea.domain}/192.168.1.140" ]; # TODO:use refrence instead of hardcoded value
      };

      nginx = {
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."${config.fishnet.services.gitea.domain}" = {
          locations."/" = {
            proxyPass = "http://localhost:3000/";
          };
        };
      };

      postgresql = {
        initialScript = pkgs.writeText "init-sql-script" ''
          alter user gitea with password '${config.fishnet.services.gitea.dbpass}';
      '';

        ensureDatabases = [ config.services.gitea.database.name ];
        ensureUsers = [
          {
            name = config.services.gitea.database.name;
            ensureDBOwnership = true;
            ensureClauses = {
              createdb = true;
              createrole = true;
              login = true;
            };
          }
        ];
      };

      gitea = {
        appName = config.fishnet.services.gitea.name;
        database = {
          name = "gitea";
          type = "postgres";
          password = config.fishnet.services.gitea.dbpass;
        };
        settings.server = {
          domain = config.fishnet.services.gitea.domain;
          rootUrl = "http://${config.fishnet.services.gitea.domain}/";
          httpPort = 3000;
        };
      };

      gitea-actions-runner = {
        instances."linux-host" = {
          name = "Linux";
          enable = true;
          url = "${config.services.gitea.settings.server.rootUrl}";
          labels = [
            "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-22.04"
            "native:host"
          ];
          settings = {
            container = {
              network = "bridge";
              options = "--dns 192.168.1.140 --dns 114.114.114.114"; # TODO:use refrence instead of hardcoded value
            };
          };
          hostPackages = with pkgs; [
            bash
            coreutils
            curl
            gawk
            gitMinimal
            gnused
            nodejs
            rsync
            wget
          ];
          tokenFile = "/root/gitea_runnertoken"; # TODO:config.sops.secrets."gitea_runnertoken".path;
        };
      };
    };
  };
}
