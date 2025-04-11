# Route Configurations
#

{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.fishnet.enable {
    environment.systemPackages = with pkgs; [
      iptables
      cjdns
      cjdns-tools
      wireguard-tools
    ];

    networking = {
      nat = {
        # Always sync with devs in postUp & preDown.
        externalInterface = "tun0";
        internalInterfaces = [ "wg0" ];
      };

      wireguard.interfaces.wg0 = {
        postSetup = ''
          ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
          ${pkgs.lib.concatMapStrings (
            ip:
            let
              parts = pkgs.lib.splitString "/" ip;
              addr = pkgs.lib.elemAt parts 0;
              isV6 = pkgs.lib.hasInfix "::" addr;
              cmd = if isV6 then "ip6tables" else "iptables";
            in
            ''
              ${pkgs.iptables}/bin/${cmd} -t nat -A POSTROUTING -s ${ip} -o tun0 -j MASQUERADE
            ''
          ) config.networking.wireguard.interfaces.wg0.ips}
        '';
        preShutdown = ''
          ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
          ${pkgs.lib.concatMapStrings (
            ip:
            let
              parts = pkgs.lib.splitString "/" ip;
              addr = pkgs.lib.elemAt parts 0;
              isV6 = pkgs.lib.hasInfix "::" addr;
              cmd = if isV6 then "ip6tables" else "iptables";
            in
            ''
              ${pkgs.iptables}/bin/${cmd} -t nat -D POSTROUTING -s ${ip} -o tun0 -j MASQUERADE
            ''
          ) config.networking.wireguard.interfaces.wg0.ips}
        '';

      };
    };

    services = {
      cjdns = {
        extraConfig.router.interface.tunDevice = "tun0";
      };
    };
  };
}
