# Standard Fish Configuration File
# Based on Nixos 24.11
#
# Please modify the placeholder values according to your specific situation.
# Import this file into your Nixos profile to get it running.

{ config, lib, ... }:

let
  cfg = config.fishnet;
in
{
  imports = [
    ./Route.nix
    ./Storage.nix
    ./Service
  ];

  options = {
    fishnet = {
      enable = lib.mkEnableOption "fishnet"; # The description will be expanded to "Whether to enable fishnet."
      wireguard = lib.mkOption {
        description = "Wireguard-related options";
        default = { };
        type = lib.types.submodule {
          options = {
            privateKeyFile = lib.mkOption {
              description = "Path to private key file";
              type = lib.types.string;
            };
            peers = lib.mkOption {
              description = "Peers (See https://search.nixos.org/options?channel=24.11&show=networking.wireguard.interfaces.%3Cname%3E.peers&from=0&size=50&sort=relevance&type=packages&query=networking.wireguard)";
              default = [ ];
              example = ''[ {
                # Don't forget to name your peers.
                # Public key of the peer (not a file path).
                publicKey = "{client public key}";
                # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
                allowedIPs = [
                  "10.100.0.2/32"
                  "2001:db8::2/64"
                ];
              } ]'';
              type = lib.types.listOf lib.types.attrs;
            };
          };
        };
      };
      cjdns = lib.mkOption {
        description = "cjdns-related options";
        default = { };
        type = lib.types.submodule {
          options = {
            UDPInterface = lib.mkOption {
              description = "UDP Interface config of cjdns";
              default = { };
              type = lib.types.submodule {
                options = {
                  bind = lib.mkOption {
                    description = "Address and port to bind UDP tunnels to";
                    example = "IP:Port";
                    type = lib.types.string;
                  };
                  connectTo = lib.mkOption {
                    description = "ConnectTo (See https://search.nixos.org/options?channel=24.11&show=services.cjdns.UDPInterface.connectTo&from=0&size=50&sort=relevance&type=packages&query=services.cjdns)";
                    type = lib.types.attrsOf lib.types.attrs;
                  };
                };
              };
            };
            authorizedPasswords = lib.mkOption {
              description = "Any remote cjdns nodes that offer these passwords on connection will be allowed to route through this node";
              example = [ "passwordpassword123" ];
              type = lib.types.listOf lib.types.string;
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      nat.enable = true;
      nat.enableIPv6 = true;

      wireguard.enable = true;
      wireguard.interfaces.wg0 = {
        ips = [
          # Always sync with IPs in postUp & preDown.
          "10.100.0.1/24"
          "2001:db8::1/64"
        ];
        privateKeyFile = cfg.fishnet.wireguard.privateKeyFile;
        peers = cfg.fishnet.wireguard.peers;
      };
    };

    services = {
      # Remember to change cjdns keys and IPv6 address in /etc/cjdns.keys and /etc/cjdns.public!
      # Sadly we can't change the path or fileformat in nix conf for now :(
      cjdns = {
        enable = true;

        UDPInterface.bind = config.fishnet.cjdns.UDPInterface.bind;

        authorizedPasswords = config.fishnet.cjdns.authorizedPasswords;

        UDPInterface.connectTo = config.fishnet.cjdns.UDPInterface.connectTo;
      };


      /*
        kubo = {
          enable = true;

          # See more at https://github.com/ipfs/kubo/blob/master/docs/config.md
          settings = {
            #Addresses.Gateway = "/ip4/0.0.0.0/tcp/8080";
            #Addresses.API = "/ip4/0.0.0.0/tcp/5001";
            #Identity.PrivKey = "";
            Bootstrap = [ ];
            Datastore.StorageMax = "10GB";
          };
        };
      */

    };
  };
}
