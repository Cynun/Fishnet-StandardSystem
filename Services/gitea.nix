{ config, pkgs, ... }: {
  services = {

    nginx.virtualHosts."git.my-domain.tld" = {
      locations."/" = { proxyPass = "http://localhost:3000/"; };
    };

    postgresql = {
      initialScript = pkgs.writeText "init-sql-script" ''
        alter user gitea with password '${builtins.readFile ./gitea_dbpass}';
      ''; # config.sops.secrets."postgres/gitea_dbpass".path;

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
      enable = true;
      appName = "My awesome Gitea server"; # Give the site a name
      database = {
        name = "gitea";
        type = "postgres";
        password = "${builtins.readFile
          ./gitea_dbpass}"; # config.sops.secrets."postgres/gitea_dbpass".path;
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
        settings = { container = { network = "bridge"; }; };
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
          "/root/gitea_runnertoken"; # config.sops.secrets."gitea_runnertoken".path;
      };
    };
  };
}

