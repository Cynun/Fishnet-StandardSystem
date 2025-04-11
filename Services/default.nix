# Service Configurations
#
#

{ config, lib, ... }:

{
  imports = [ ./gitea.nix ./matrix.nix ];

  config = {
    services.dnsmasq.settings.domain-needed = true;
    services.nginx = {
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };
  };
}
