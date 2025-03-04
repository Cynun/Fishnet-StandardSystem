# Standard Fish Configuration File
# Based on Nixos 24.11
#
# Please modify the placeholder values according to your specific situation.
# Import this file into your Nixos profile to get it running.

{ config, pkgs, ... }:{
    
  imports = [ 
    ./cjdns.nix
  ];
  
  services = {
      cjdns.enable=true;
  };
}