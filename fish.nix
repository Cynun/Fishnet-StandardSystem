# Standard Fish Configuration File
# Based on Nixos 24.11
#
# Please modify the placeholder values according to your specific situation.
# Import this file into your Nixos profile to get it running.

{ config, pkgs, ... }: {

  imports = [ ./Route.nix /*./Storage.nix*/ ./Service.nix ];

  networking = {

    nat.enable = true;
    nat.enableIPv6 = true;

    wireguard.enable = true;
    wireguard.interfaces.wg0 = {
      ips = [ # Always sync with IPs in postUp & preDown.
        "10.100.0.1/24"
        "2001:db8::1/64"
      ];
      privateKeyFile = "path to private key file";
      peers = [{ # Don't forget to name your peers.
        # Public key of the peer (not a file path).
        publicKey = "{client public key}";
        # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
        allowedIPs = [ "10.100.0.2/32" "2001:db8::2/64" ];
      }
      # More peers can be added here.

        ];
    };
  };

  services = {

    # Remember to change cjdns keys and IPv6 address in /etc/cjdns.keys and /etc/cjdns.public!
    # Sadly we can't change the path or fileformat in nix conf for now :(
    cjdns = {
      enable=true;

      UDPInterface.bind = "IP:Port"; # Address and port to bind UDP tunnels to.

      # Any remote cjdns nodes that offer these passwords on connection will be allowed to route through this node.
      authorizedPasswords = [ "passwordpassword123" ];

      UDPInterface.connectTo = {
        "PeerIP:PeerPort" = {
          peerName = "Optional human-readable name for peer";
          hostname =
            "Optional hostname to add to /etc/hosts; prevents reverse lookup failures.";
          publicKey = "Public key at the opposite end of the tunnel.";
          login = "Optional name your peer has for you";
          password = "Authorized password to the opposite end of the tunnel.";
        };
      };
    };

    /*kubo = {
      enable = true;

      # See more at https://github.com/ipfs/kubo/blob/master/docs/config.md
      settings = {
        #Addresses.Gateway = "/ip4/0.0.0.0/tcp/8080";
        #Addresses.API = "/ip4/0.0.0.0/tcp/5001";
        #Identity.PrivKey = "";
        Bootstrap = [ ];
        Datastore.StorageMax = "10GB";
      };
    };*/

  };

}
