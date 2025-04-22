{ config, lib, pkgs, ... }:

{
  options = {
    fishnet.Services.gitea = {
      enable = lib.mkEnableOption "fishnet.Services.gitea";
      name = lib.mkOption {
        description = "Give the site a name";
        example = "My awesome Gitea server";
        default = "My Gitea server";
        type = lib.types.string;
      };
      domain = lib.mkOption {
        description = "Domain of gitea";
        example = "git.my-domain.tld";
        type = lib.types.string;
      };
      database = {
        name = lib.mkOption {
          description = "Postgresql database name for gitea";
          example = "gitea";
          default = "gitea";
          type = lib.types.string;
        };
        password = lib.mkOption {
          # TODO:config.sops.secrets."postgres/gitea_dbpass".path;
          description = "Postgresql database password for gitea";
          example = "builtins.readFile ./gitea_dbpass";
          type = lib.types.string;
        };
      };
      actionsRunnerEnable = lib.mkEnableOption "fishnet.Services.gitea-runner";
      actionsRunnerSettings = lib.mkOption {
        description = "settings for gitea actions runner";
        example = ''
          {
                      container = {
                        network = "bridge";
                        options = "--dns 192.168.1.140 --dns 114.114.114.114";
                      };
                    }'';
        default = { };
        type =
          lib.types.submodule { freeformType = (pkgs.formats.yaml { }).type; };
      };
    };
  };

  config = lib.mkIf config.fishnet.Services.gitea.enable {
    services = {

      postgresql = {
        enable = true;
        initialScript = pkgs.writeText "init-sql-script" ''
          alter user gitea with password '${config.fishnet.Services.gitea.database.password}';
        '';

        ensureDatabases = [ config.fishnet.Services.gitea.database.name ];
        ensureUsers = [{
          name = config.fishnet.Services.gitea.database.name;
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
        appName = config.fishnet.Services.gitea.name;
        database = {
          name = "gitea";
          type = "postgres";
          password = config.fishnet.Services.gitea.database.password;
        };
        settings.server = {
          domain = config.fishnet.Services.gitea.domain;
          rootUrl = "http://${config.fishnet.Services.gitea.domain}/";
          httpPort = 3000;
        };
      };

      gitea-actions-runner =
        lib.mkIf config.fishnet.Services.gitea.actionsRunnerEnable {
          instances."linux-host" = {
            name = "Linux";
            enable = true;
            url = "${config.services.gitea.settings.server.rootUrl}";
            labels = [
              "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-22.04"
              "native:host"
            ];
            settings = config.fishnet.Services.gitea.actionsRunnerSettings;
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
          };
        };
    };
  };
}
