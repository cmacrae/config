{ config, pkgs, lib, ... }:

let
  domain = "cmacr.ae";
  vpnAddressSpace = "10.100.0.0/24";

  ipReservations = {
    net1.ip = "10.0.0.2";
    net1.mac = "dc:a6:32:77:ea:98";

    erl.ip = "10.0.0.1";
    erl.mac = "80:2a:a8:4d:05:4e";

    managed-switch.ip = "10.0.0.3";
    managed-switch.mac = "f4:f2:6d:93:39:c5";

    tradfri.ip = "10.0.0.4";
    tradfri.mac = "44:91:60:25:44:db";

    compute1.ip = "10.0.10.1";
    compute1.mac = "b8:ae:ed:7d:1b:7e";
    compute2.ip = "10.0.10.2";
    compute2.mac = "b8:ae:ed:7d:19:06";
    compute3.ip = "10.0.10.3";
    compute3.mac = "b8:ae:ed:7d:1a:09";

    ds1819.ip = "10.0.1.1";
    ds1819.mac = "00:11:32:cf:10:eb";

    macbook-wired.ip = "10.0.1.2";
    macbook-wired.mac = "64:4b:f0:2b:0e:03";
    macbook-wifi.ip = "10.0.1.3";
    macbook-wifi.mac = "a4:83:e7:8b:f2:fd";

    ps4.ip = "10.0.1.4";
    ps4.mac = "f8:46:1c:39:f4:97";
    xbox.ip = "10.0.1.5";
    xbox.mac = "98:5f:d3:f6:87:b1";
  };

in
  with pkgs.lib; {
    boot.cleanTmpDir = true;
    boot.kernelPackages = pkgs.linuxPackages_rpi4;
    boot.kernelParams = [ "cma=64M" "console=tty0" ];
    boot.loader.raspberryPi.enable = true;
    boot.loader.raspberryPi.version = 4;
    boot.initrd.checkJournalingFS = false;
    boot.loader.grub.enable = false;
    boot.initrd.availableKernelModules = [ "usbhid" ];
    hardware.enableRedistributableFirmware = true;

    swapDevices = [
      {
        device = "/swapfile";
        size = 2048;
      }
    ];

    nix.maxJobs = "auto";

    powerManagement.cpuFreqGovernor = "ondemand";

    fileSystems."/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };

    networking = {
      hostName = "net1";
      domain = "cmacr.ae";
      dhcpcd.enable = false;
      defaultGateway = "10.0.0.1";
      useDHCP = false;
      wireless.enable = false;

      interfaces.eth0.ipv4.addresses = [
        {
          address = ipReservations.net1.ip;
          prefixLength = 16;
        }
      ];

      nat.enable = true;
      nat.externalInterface = "eth0";
      # nat.internalInterfaces = [ "wg0" ];
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
        allowedUDPPorts = [ 53 51820 ];

        extraCommands = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${vpnAddressSpace} -o eth0 -j MASQUERADE
        '';
      };

      wireguard.interfaces = {
        wg0 = {
          listenPort = 51820;
          ips = [ "10.100.0.1/24" ];

          privateKeyFile = config.sops.secrets.net1_wireguard_privatekey.path;

          peers = [
            {
              # iPhone
              publicKey = "p01WeSnCip/0WawSYcQAnFq+0xlnfLwoRrBc0Un1Pmg=";
              allowedIPs = [ "10.100.0.2/32" ];
            }
            {
              # iPad
              publicKey = "pi78Qv0OdKHt/KUc9+VaZ5nOU64HB1Tf7KBIX4yJIGw=";
              allowedIPs = [ "10.100.0.3/32" ];
            }
            {
              # MacBook
              publicKey = "FUCNqeSNgMdpSEatYd/RL9MG3rF7mR006lwU8JQTE0k=";
              allowedIPs = [ "10.100.0.4/32" ];
            }
          ];
        };
      };
    };

    services.timesyncd.enable = true;

    services.dhcpd4 = {
      enable = true;
      extraConfig = ''
        ddns-update-style none;
        shared-network local {
            option routers ${ipReservations.erl.ip};
            option domain-name "${domain}";
            option domain-name-servers ${ipReservations.net1.ip};
            option domain-search "${domain}";
            option time-servers ${concatStringsSep ", " config.networking.timeServers};
            subnet 10.0.0.0 netmask 255.255.0.0 {
                range 10.0.20.1 10.0.20.254;
            }
        }
      '';

      machines = mapAttrsToList (
        machine: attributes:
          {
            hostName = "${machine}.${domain}";
            ethernetAddress = builtins.toString (catAttrs "mac" (singleton attributes));
            ipAddress = builtins.toString (catAttrs "ip" (singleton attributes));
          }
      ) ipReservations;
    };

    services.unbound = {
      enable = true;
      settings.server = {
        interface = [ "0.0.0.0" ];

        prefetch = "yes";
        prefetch-key = "yes";
        harden-glue = "yes";
        hide-version = "yes";
        hide-identity = "yes";
        use-caps-for-id = "yes";
        val-clean-additional = "yes";
        harden-dnssec-stripped = "yes";
        cache-min-ttl = "3600";
        cache-max-ttl = "86400";
        unwanted-reply-threshold = "10000";

        verbosity = "2";
        log-queries = "yes";

        tls-cert-bundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

        num-threads = "4";
        infra-cache-slabs = "4";
        key-cache-slabs = "4";
        msg-cache-size = "131721898";
        msg-cache-slabs = "4";
        num-queries-per-thread = "4096";
        outgoing-range = "8192";
        rrset-cache-size = "263443797";
        rrset-cache-slabs = "4";
        minimal-responses = "yes";
        serve-expired = "yes";
        so-reuseport = "yes";

        private-address = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
        ];

        access-control = [
          "127.0.0.0/8 allow"
          "10.0.0.0/8 allow"
        ];

        local-zone = [
          ''"localhost." static''
          ''"127.in-addr.arpa." static''

          ''"${domain}" transparent''
        ];

        local-data = [
          ''"localhost. 10800 IN NS localhost."''
          ''"localhost. 10800 IN SOA localhost. nobody.invalid. 1 3600 1200 604800 10800"''

          ''"localhost. 10800 IN A 127.0.0.1"''
          ''"127.in-addr.arpa. 10800 IN NS localhost."''
          ''"127.in-addr.arpa. 10800 IN SOA localhost. nobody.invalid. 2 3600 1200 604800 10800"''
          ''"1.0.0.127.in-addr.arpa. 10800 IN PTR localhost."''
        ] ++ (
          mapAttrsToList (
            name: attributes:
              ''"${name}.${domain}. IN A ${builtins.toString (catAttrs "ip" (singleton attributes))}"''
          ) ipReservations
        );

        private-domain = [
          ''"${domain}."''
          ''"pantheon.${domain}."''
        ];

        domain-insecure = ''"pantheon.${domain}."'';
      };

      settings.stub-zone = {
        name = "consul.";
        stub-addr = [
          "${ipReservations.compute1.ip}@8600"
          "${ipReservations.compute2.ip}@8600"
          "${ipReservations.compute3.ip}@8600"
        ];
      };

      settings.forward-zone = {
        name = ".";
        forward-tls-upstream = "yes";
        forward-addr = [
          "1.1.1.1@853"
          "1.0.0.1@853"
        ];
      };
    };
  }
