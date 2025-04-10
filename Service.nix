# Service Configurations
#
#

{ config, pkgs, ... }: {
  imports = [ ./Services/gitea.nix ./Services/matrix.nix ];

  environment.systemPackages = with pkgs; [ ];

  services.dnsmasq = {
    settings = {
      address = [
        "/git.my-domain.tld/192.168.1.140"
        "/matrix.my-domain.tld/192.168.1.140"
      ]; # TODO:use refrence instead of hardcoded value
      domain-needed = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

}
