# Matrix&Element Configurations
#
# 

{ config, pkgs, lib, ... }:

{
  options.fishnet.Services = {
    matrix = {
      enable = lib.mkEnableOption "fishnet.Services.matrix";
      server.domain = lib.mkOption {
        description = "Domain of matrix server";
        example = "matrix.my-domain.tld";
        type = lib.types.string;
      };
      webclient.domain = lib.mkOption {
        description = "Domain of element";
        example = "element.my-domain.tld";
        type = lib.types.string;
      };
    };
  };

  config = lib.mkIf config.fishnet.Services.matrix.enable {
    services = {

      nginx = {
        enable = true;

        # See https://nixos.org/manual/nixos/stable/index.html#module-Services-matrix-element-web
        virtualHosts."${config.fishnet.Services.matrix.webclient.domain}" = {
          root = pkgs.element-web.override {
            # See https://github.com/element-hq/element-web/blob/develop/config.sample.json
            conf = {
              default_theme = "dark";
              "default_server_config" = {
                "m.homeserver" = {
                  "base_url" =
                    "http://${config.fishnet.Services.matrix.server.domain}";
                  "server_name" =
                    "${config.fishnet.Services.matrix.server.domain}";
                };
              };
            };
          };
        };

        virtualHosts."${config.fishnet.Services.matrix.server.domain}" = {
          locations."/" = { proxyPass = "http://localhost:8008/"; };
        };
      };

      # We can only use sqlite3 for matrix when "i18n.defaultLocale" is not "C"...
      postgresql = {
        ensureDatabases = [ "matrix-synapse" ];
        ensureUsers = [{
          name = "matrix-synapse";
          ensureDBOwnership = true;
          ensureClauses = {
            createdb = true;
            createrole = true;
            login = true;
          };
        }];
      };

      matrix-synapse = {
        enable = true;
        enableRegistrationScript = true;
        settings = {
          server_name = config.fishnet.Services.matrix.server.domain;
          registration_shared_secret =
            "svWfPnOGX6xkSDnn2wA2uaAgxPpplDyOvaxP1bklQd2l91J1QJpOWiyrqqSN3Pha";

          database.name = "psycopg2"; # "sqlite3";
          database.allow_unsafe_locale=true;
          extraConfig = ''
            max_upload_size: "50M"
          '';
        };
      };
    };
  };
}
