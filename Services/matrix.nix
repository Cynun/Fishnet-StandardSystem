# Matrix&Element Configurations
#
# Woomy

{ config, pkgs, lib, ... }:

{
  options = {
    fishnet.Services.matrix = {
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
    Services = {
      # See https://nixos.org/manual/nixos/stable/index.html#module-Services-matrix-element-web
      nginx.virtualHosts."${config.fishnet.Services.matrix.webclient.domain}" = {
        root = pkgs.element-web.override {
          # See https://github.com/element-hq/element-web/blob/develop/config.sample.json
          conf = {
            default_theme = "dark";
            "default_server_config" = {
              "m.homeserver" = {
                "base_url" = "http://${config.fishnet.Services.matrix.server.domain}";
                "server_name" = "${config.fishnet.Services.matrix.server.domain}";
              };
            };
          };
        };
      };

      nginx.virtualHosts."${config.fishnet.Services.matrix.server.domain}" = {
        locations."/" = {
          proxyPass = "http://localhost:8008/";
        };
      };

      # We can only use sqlite3 for matrix when "i18n.defaultLocale" is not "C"...
      # postgresql = {
      #   ensureDatabases = [ "matrix-synapse" ];
      #   ensureUsers = [{
      #     name = "matrix-synapse";
      #     ensureDBOwnership = true;
      #     ensureClauses = {
      #       createdb = true;
      #       createrole = true;
      #       login = true;
      #     };
      #   }];
      # };

      matrix-synapse = {
        settings = {
          server_name = config.fishnet.Services.matrix.server.domain;
          registration_shared_secret = "svWfPnOGX6xkSDnn2wA2uaAgxPpplDyOvaxP1bklQd2l91J1QJpOWiyrqqSN3Pha";

          database.name = "sqlite3"; # "psycopg2";

          extraConfig = ''
            max_upload_size: "50M"
          '';
        };
      };
    };
  };
}
