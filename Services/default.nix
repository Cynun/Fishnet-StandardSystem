# Service Configurations
#
#

{ ... }:

{
  imports = [ ./gitea.nix ./matrix.nix ];

  Services.dnsmasq.settings.domain-needed = true;
}
