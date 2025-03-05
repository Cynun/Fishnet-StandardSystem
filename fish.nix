# Standard Fish Configuration File
# Based on Nixos 24.11
#
# Please modify the placeholder values according to your specific situation.
# Import this file into your Nixos profile to get it running.

{ config, pkgs, ... }:{
    
  imports = [ 
      ./Route.nix
  ];
  
  services = {
    cjdns.enable=true;
  };

  networking = {
    nat.enable = true;
    nat.enableIPv6 = true;
    wireguard.enable = true;
  }
}