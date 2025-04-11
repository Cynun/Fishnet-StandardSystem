# Storage Configurations
#
# This is acturally optional

{ config, lib, pkgs, ... }:

let
  cfg = config.fishnet;
in
{
  options = {
    fishnet.storage.enable = lib.mkEnableOption "fishnet.storage";
  };

  config = lib.mkIf cfg.storage.enable {
    environment.systemPackages = with pkgs; [ kubo ];

    services.kubo = {
      settings = {
        Addresses = {
          API = "/ip4/127.0.0.1/tcp/5001";
          Gateway = lib.mkDefault "/ip4/127.0.0.1/tcp/8080";
          Swarm = [
            "/ip4/0.0.0.0/tcp/4001"
            "/ip6/::/tcp/4001"
            "/ip4/0.0.0.0/udp/4001/quic-v1"
            "/ip4/0.0.0.0/udp/4001/quic-v1/webtransport"
            "/ip6/::/udp/4001/quic-v1"
            "/ip6/::/udp/4001/quic-v1/webtransport"
          ];
        };
      };
      autoMount = true;
    };
  };
}
