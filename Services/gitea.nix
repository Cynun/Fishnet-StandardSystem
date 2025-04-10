{ config, pkgs, ... }: {
  services = {

    nginx.virtualHosts."${config.services.gitea.settings.server.domain}" = {
      locations."/" = { proxyPass = "http://localhost:3000/"; };
    };

    postgresql = {
      initialScript = pkgs.writeText "init-sql-script" ''
        alter user gitea with password '${builtins.readFile ./gitea_dbpass}';
      ''; # TODO:config.sops.secrets."postgres/gitea_dbpass".path;

      ensureDatabases = [ config.services.gitea.database.name ];
      ensureUsers = [{
        name = config.services.gitea.database.name;
        ensureDBOwnership = true;
        ensureClauses = {
          createdb = true;
          createrole = true;
          login = true;
        };
      }];
    };

    gitea = {
      appName = "My awesome Gitea server"; # Give the site a name
      database = {
        name = "gitea";
        type = "postgres";
        password = "${builtins.readFile
          ./gitea_dbpass}"; # TODO:config.sops.secrets."postgres/gitea_dbpass".path;
      };
      settings.server = {
        domain = "git.my-domain.tld";
        rootUrl = "http://git.my-domain.tld/";
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
            options = "--dns 192.168.1.140 --dns 114.114.114.114"; #TODO:use refrence instead of hardcoded value
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
        tokenFile =
          "/root/gitea_runnertoken"; # TODO:config.sops.secrets."gitea_runnertoken".path;
      };
    };
  };
}

