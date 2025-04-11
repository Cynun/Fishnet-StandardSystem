# Service Configurations
#
#

{ ... }:

{
  imports = [ ./gitea.nix ./matrix.nix ];

  services.dnsmasq.settings.domain-needed = true;
}
