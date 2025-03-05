# Route Configurations
#

{ config, pkgs, ... }:{
    environment.systemPackages = with pkgs; [
        iptables
        cjdns
        cjdns-tools
        wireguard-tools
    ];

    networking = {
        nat = { # Always sync with devs in postUp & preDown.
            externalInterface = "tun0";
            internalInterfaces = [ "wg0" ];
        };

        wireguard.interfaces.wg0 = {
            ips = [ "10.100.0.1/24" "2001:db8::1/64"]; # Always sync with IPs in postUp & preDown.
            privateKeyFile = "path to private key file";
            peers = [
                { # Don't forget to name your peers.
                    # Public key of the peer (not a file path).
                    publicKey = "{client public key}";
                    # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
                    allowedIPs = [ "10.100.0.2/32" "2001:db8::2/64"];
                }
                # More peers can be added here.
            ];

            listenPort = 51820;
            postUp = ''
                ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
                ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.1/24 -o tun0 -j MASQUERADE
                ${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
                ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s 2001:db8::1/64 -o tun0 -j MASQUERADE
            '';
            preDown = ''
                ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
                ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.1/24 -o tun0 -j MASQUERADE
                ${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
                ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s 2001:db8::1/64 -o tun0 -j MASQUERADE
            '';

        };
    };

    services = {
        cjdns = { # Remember to change the keys and IP address in /etc/cjdns.keys and /etc/cjdns.public!
            UDPInterface.bind = "IP:Port"; # Address and port to bind UDP tunnels to.

            # Any remote cjdns nodes that offer these passwords on connection will be allowed to route through this node.
            authorizedPasswords = [
                "passwordpassword123"
            ];

            UDPInterface.connectTo = {
                "PeerIP:PeerPort" = {
                    peerName = "Optional human-readable name for peer";
                    hostname = "Optional hostname to add to /etc/hosts; prevents reverse lookup failures.";
                    publicKey = "Public key at the opposite end of the tunnel.";
                    login = "Optional name your peer has for you";
                    password = "Authorized password to the opposite end of the tunnel.";
                };
            };
        };


    };

}