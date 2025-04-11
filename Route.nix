# Route Configurations
#

{ config, lib, pkgs, ... }:

{
  options = {
    fishnet = {
      Route = lib.mkOption {
        description = "fishnet Route layer options";
        type = lib.types.submodule {
          options = {
            enable = lib.mkEnableOption "enable fishnet Route layer";
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
                    description =
                      "Peers (See https://search.nixos.org/options?channel=24.11&show=networking.wireguard.interfaces.%3Cname%3E.peers&from=0&size=50&sort=relevance&type=packages&query=networking.wireguard)";
                    default = [ ];
                    example = ''
                      [ {
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
                          description =
                            "Address and port to bind UDP tunnels to";
                          example = "IP:Port";
                          type = lib.types.string;
                        };
                        connectTo = lib.mkOption {
                          description =
                            "ConnectTo (See https://search.nixos.org/options?channel=24.11&show=services.cjdns.UDPInterface.connectTo&from=0&size=50&sort=relevance&type=packages&query=services.cjdns)";
                          type = lib.types.attrsOf lib.types.attrs;
                        };
                      };
                    };
                  };
                  authorizedPasswords = lib.mkOption {
                    description =
                      "Any remote cjdns nodes that offer these passwords on connection will be allowed to route through this node";
                    example = [ "passwordpassword123" ];
                    type = lib.types.listOf lib.types.string;
                  };
                };
              };
            };
          };
        };
      };

    };
  };

  config = lib.mkIf config.fishnet.Route.enable {
    networking = {
      nat = {
        enable = true;
        enableIPv6 = true;
        # Always sync with devs in postUp & preDown.
        externalInterface = "tun0";
        internalInterfaces = [ "wg0" ];
      };

      wireguard.enable = true;
      wireguard.interfaces.wg0 = {

        ips = [
          # Always sync with IPs in postUp & preDown.
          "10.100.0.1/24"
          "2001:db8::1/64"
        ];
        privateKeyFile = config.fishnet.Route.wireguard.privateKeyFile;
        peers = config.fishnet.Route.wireguard.peers;

        postSetup = ''
          ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
          ${pkgs.lib.concatMapStrings (ip:
            let
              parts = pkgs.lib.splitString "/" ip;
              addr = pkgs.lib.elemAt parts 0;
              isV6 = pkgs.lib.hasInfix "::" addr;
              cmd = if isV6 then "ip6tables" else "iptables";
            in ''
              ${pkgs.iptables}/bin/${cmd} -t nat -A POSTROUTING -s ${ip} -o tun0 -j MASQUERADE
            '') config.networking.wireguard.interfaces.wg0.ips}
        '';
        preShutdown = ''
          ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
          ${pkgs.lib.concatMapStrings (ip:
            let
              parts = pkgs.lib.splitString "/" ip;
              addr = pkgs.lib.elemAt parts 0;
              isV6 = pkgs.lib.hasInfix "::" addr;
              cmd = if isV6 then "ip6tables" else "iptables";
            in ''
              ${pkgs.iptables}/bin/${cmd} -t nat -D POSTROUTING -s ${ip} -o tun0 -j MASQUERADE
            '') config.networking.wireguard.interfaces.wg0.ips}
        '';

      };
    };

    services = {
      # Remember to change cjdns keys and IPv6 address in /etc/cjdns.keys and /etc/cjdns.public!
      # Sadly we can't change the path or fileformat in nix conf for now :(
      cjdns = {
        enable = true;

        UDPInterface.bind = config.fishnet.Route.cjdns.UDPInterface.bind;

        authorizedPasswords = config.fishnet.Route.cjdns.authorizedPasswords;

        UDPInterface.connectTo =
          config.fishnet.Route.cjdns.UDPInterface.connectTo;

        extraConfig.router.interface.tunDevice = "tun0";
      };

      /* kubo = {
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
