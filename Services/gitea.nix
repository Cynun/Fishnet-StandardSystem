{ config, lib, pkgs, ... }:

{
  options = {
    fishnet.Services.gitea = {
      enable = lib.mkEnableOption "fishnet.Services.gitea";
      name = lib.mkOption {
        description = "Give the site a name";
        example = "My awesome Gitea server";
        type = lib.types.string;
      };
      domain = lib.mkOption {
        description = "Domain of gitea";
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

  config = lib.mkIf config.fishnet.Services.gitea.enable {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    Services = {
      dnsmasq.settings = {
        address = [ "/${config.fishnet.Services.gitea.domain}/192.168.1.140" ]; # TODO:use refrence instead of hardcoded value
      };

      nginx = {
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."${config.fishnet.Services.gitea.domain}" = {
          locations."/" = {
            proxyPass = "http://localhost:3000/";
          };
        };
      };

      postgresql = {
        initialScript = pkgs.writeText "init-sql-script" ''
          alter user gitea with password '${config.fishnet.Services.gitea.dbpass}';
      '';

        ensureDatabases = [ config.Services.gitea.database.name ];
        ensureUsers = [
          {
            name = config.Services.gitea.database.name;
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
        appName = config.fishnet.Services.gitea.name;
        database = {
          name = "gitea";
          type = "postgres";
          password = config.fishnet.Services.gitea.dbpass;
        };
        settings.server = {
          domain = config.fishnet.Services.gitea.domain;
          rootUrl = "http://${config.fishnet.Services.gitea.domain}/";
          httpPort = 3000;
        };
      };

      gitea-actions-runner = {
        instances."linux-host" = {
          name = "Linux";
          enable = true;
          url = "${config.Services.gitea.settings.server.rootUrl}";
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
