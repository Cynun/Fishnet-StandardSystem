# Route Configurations
#

{ config, pkgs, ... }: {
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
    cjdns = {
      extraConfig.router.interface.tunDevice = "tun0";
    };
  };

}
