# cjdns Configurations
# Remember to change the keys and IP address in /etc/cjdns.keys and /etc/cjdns.public

{ config, pkgs, ... }:{
    environment.systemPackages = with pkgs; [
        cjdns
        cjdns-tools
    ];

    services.cjdns = {
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
}