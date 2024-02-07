{ config, lib, pkgs, inputs, ... }:
with builtins;
with pkgs.lib;

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
    build1.ip = "10.0.10.4";
    build1.mac = "e2:fc:13:e6:cc:aa";

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

  # TODO: Restructure this so it's like:
  # proxyServices = {
  #   compute1 = {
  #     nzbget = 6789;
  #     sonarr = 8989; 
  #   };
  #   compute2 = {
  #     radarr = 6789;
  #     blahhh = 8989; 
  #   }; 
  # }
  proxyServices = {
    nzbget.port = 6789;
    nzbget.host = "compute1";
    sonarr.port = 8989;
    sonarr.host = "compute2";
    radarr.port = 7878;
    radarr.host = "compute2";
    prowlarr.host = "compute2";
    prowlarr.port = 9696;
    plex.port = 32400;
    plex.host = "compute3";
  };

in
{
  imports = [
    inputs.self.nixosModules.common
    inputs.self.nixosModules.server
  ];

  boot.tmp.useTmpfs = true;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.initrd.checkJournalingFS = false;
  boot.initrd.availableKernelModules = [ "usbhid" "usb_storage" "vc4" "pcie_brcmstb" "reset-raspberrypi" ];
  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  boot.kernelParams = [
    "cma=64M"
    "8250.nr_uarts=1"
    "console=tty1"
    "console=ttyAMA0,115200"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  lollypops.secrets.files."net1/wireguard-privatekey" = { };
  lollypops.secrets.files."net1/acme-dnsimple-envfile" = { };
  lollypops.tasks = [ "deploy-secrets" "rebuild" ];
  lollypops.deployment.local-evaluation = true;
  lollypops.extraTasks.rebuild =
    let
      inherit (config.networking) hostName;
      inherit (config.lollypops.deployment.ssh) user;
    in
    {
      dir = ".";
      deps = [ "check-vars" ];
      desc = "Local build & swtich for: ${hostName}";
      cmds = [
        ''
          set -e
          BPATH=$(mktemp -d)
          cd $BPATH
          nix build -L \
          ${inputs.self}#nixosConfigurations.${hostName}.config.system.build.toplevel
          REAL_PATH=$(realpath ./result)
          nix copy -s --to ssh://${user}@${hostName} $REAL_PATH 2>&1
          ssh ${user}@${hostName} \
          "sudo nix-env -p /nix/var/nix/profiles/system --set $REAL_PATH && \
          sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch"
          rm -rf $BPATH
        ''
      ];
    };

  system.stateVersion = "21.05";
  nixpkgs.hostPlatform = "aarch64-linux";

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

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
      allowedTCPPorts = [ 22 80 443 9100 ];
      allowedUDPPorts = [ 53 51820 ];

      extraCommands = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${vpnAddressSpace} -o eth0 -j MASQUERADE
      '';
    };

    wireguard.interfaces = {
      wg0 = {
        listenPort = 51820;
        ips = [ "10.100.0.1/24" ];

        privateKeyFile = config.lollypops.secrets.files."net1/wireguard-privatekey".path;

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

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      rebind-timer = 2000;
      renew-timer = 1000;
      valid-lifetime = 4000;

      interfaces-config.interfaces = [ "eth0" ];

      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };

      option-data = mapAttrsToList (name: attr: attr) (mapAttrs'
        (name: value: nameValuePair name { inherit name; data = value; })
        {
          routers = ipReservations.erl.ip;
          domain-name = domain;
          domain-search = domain;
          domain-name-servers = ipReservations.net1.ip;
          time-servers = "82.219.4.30, 85.199.214.98, 193.150.34.2, 129.250.35.251";
        });

      subnet4 = [{
        subnet = "10.0.0.0/16";
        pools = [{
          pool = "10.0.20.1 - 10.0.20.254";
        }];

        reservations = mapAttrsToList
          (machine: attributes:
            {
              hw-address = toString (catAttrs "mac" (singleton attributes));
              ip-address = toString (catAttrs "ip" (singleton attributes));
            }
          )
          ipReservations;
      }];
    };
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
        mapAttrsToList
          (
            name: attributes:
              ''"${name}.${domain}. IN A ${toString (catAttrs "ip" (singleton attributes))}"''
          )
          ipReservations
      ) ++ (
        mapAttrsToList
          (
            name: _:
              ''"${name}.${domain} CNAME net1.${domain}"''
          )
          proxyServices
      );

      private-domain = [
        ''"${domain}."''
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

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "account@${domain}";
  security.acme.defaults.dnsProvider = "dnsimple";
  security.acme.defaults.dnsPropagationCheck = true;
  security.acme.defaults.reloadServices = [ "nginx" ];
  security.acme.defaults.credentialsFile = config.lollypops.secrets.files."net1/acme-dnsimple-envfile".path;
  security.acme.certs = mapAttrs'
    (service: _:
      nameValuePair "${service}.${domain}" { }
    )
    proxyServices;

  # TODO: Figure out how to stop nginx from checking upstream DNS.
  #       This causes it to fail when we're adding a new service and the
  #       record doesn't exist yet.
  users.users.nginx.extraGroups = [ "acme" ];
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = mapAttrs'
      (host: attr:
        let fullName = "${host}.${domain}";
        in
        nameValuePair fullName {
          forceSSL = true;
          enableACME = true;
          sslCertificate = "/var/lib/acme/${fullName}/cert.pem";
          sslCertificateKey = "/var/lib/acme/${fullName}/key.pem";
          locations."/" = {
            proxyPass = "http://${attr.host}.${domain}:${toString attr.port}";
            extraConfig = "proxy_pass_header Authorization;";
          };
        })
      proxyServices;
  };
}
