# Service Configurations
#
#

{ config, pkgs, ... }: {
  imports = [
    ./Services/gitea.nix
  ];

  environment.systemPackages = with pkgs; [ ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  services.postgresql = { enable = true; };

  virtualisation.docker = { enable = true; };

}
