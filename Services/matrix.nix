# Matrix&Element Configurations
#
# Woomy

{ config, pkgs, lib, ... }: {
  services = {
    # See https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-element-web
    nginx.virtualHosts."${config.services.matrix-synapse.settings.server_name}" = {
      root = pkgs.element-web.override {
        # See https://github.com/element-hq/element-web/blob/develop/config.sample.json
        conf = { default_theme = "dark"; };
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
        server_name = "matrix.my-domain.tld";
        registration_shared_secret =
          "svWfPnOGX6xkSDnn2wA2uaAgxPpplDyOvaxP1bklQd2l91J1QJpOWiyrqqSN3Pha";

        database.name = "sqlite3"; # "psycopg2";

        extraConfig = ''
          max_upload_size: "50M"
        '';
      };
    };
  };
}
