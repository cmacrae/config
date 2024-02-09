{ config, pkgs, modulesPath, inputs, ... }:

let
  inherit (pkgs) lib;
  inherit (config.networking) domain;

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

with lib;
with builtins;

{
  imports = [
    inputs.self.nixosModules.common
    inputs.self.nixosModules.server

    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.initrd.kernelModules = [ ];
  boot.initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
  # TODO: use vendor kernel while waiting for it to be upstreamed
  boot.kernelPackages = inputs.nix-rpi5.legacyPackages.aarch64-linux.linuxPackages_rpi5;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  powerManagement.cpuFreqGovernor = "ondemand";

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/ecb26648-686e-403c-a415-406ac554653d";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/0CAE-25FE";
      fsType = "vfat";
    };

  zramSwap.enable = true;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "23.11";

  lollypops.secrets.files."net1/wireguard-privatekey" = { };
  lollypops.secrets.files."net1/acme-dnsimple-envfile" = { };

  # FIXME: seem to be having issues with signing key trust for
  #        derivations built on other systems.
  #        TODO: circle back to this later
  # lollypops.tasks = [ "deploy-secrets" "rebuild" ];
  # lollypops.deployment.local-evaluation = true;
  # lollypops.extraTasks.rebuild =
  #   let
  #     inherit (config.networking) hostName;
  #     inherit (config.lollypops.deployment.ssh) user;
  #   in
  #   {
  #     dir = ".";
  #     deps = [ "check-vars" ];
  #     desc = "Local build & swtich for: ${hostName}";
  #     cmds = [
  #       ''
  #         set -e
  #         BPATH=$(mktemp -d)
  #         cd $BPATH
  #         nix build -L \
  #         ${inputs.self}#nixosConfigurations.${hostName}.config.system.build.toplevel
  #         REAL_PATH=$(realpath ./result)
  #         nix copy -s --to ssh://${user}@${hostName} $REAL_PATH 2>&1
  #         ssh ${user}@${hostName} \
  #         "sudo nix-env -p /nix/var/nix/profiles/system --set $REAL_PATH && \
  #         sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch"
  #         rm -rf $BPATH
  #       ''
  #     ];
  #   };

  networking = {
    hostName = "net1";
    dhcpcd.enable = false;
    defaultGateway = "10.0.0.1";
    useDHCP = false;
    wireless.enable = false;

    interfaces.end0.ipv4.addresses = [
      {
        address = ipReservations.net1.ip;
        prefixLength = 16;
      }
    ];

    nat.enable = true;
    nat.externalInterface = "end0";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 853 9100 ];
      allowedUDPPorts = [ 53 51820 ];

      extraCommands = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${vpnAddressSpace} -o end0 -j MASQUERADE
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

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      rebind-timer = 2000;
      renew-timer = 1000;
      valid-lifetime = 4000;

      interfaces-config.interfaces = [ "end0" ];

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

  services.blocky.enable = true;
  services.blocky.settings = {
    upstreams.groups.default = [
      "tcp-tls:1.1.1.1:853"
      "tcp-tls:1.0.0.1:853"
    ];

    customDNS = {
      customTTL = "1h";
      filterUnmappedTypes = false;
      mapping =
        mapAttrs'
          (name: value:
            nameValuePair (name + ".${domain}") value.ip)
          ipReservations //
        mapAttrs'
          (name: _:
            nameValuePair (name + ".${domain}") ipReservations.net1.ip)
          proxyServices;
    };

    blocking = {
      blackLists = {
        ads = [
          "http://sysctl.org/cameleon/hosts"
          "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
          "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
          "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        ];
        special = [
          "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts"
        ];
      };
      clientGroupsBlock = {
        default = [ "ads" "special" ];
      };
      blockType = "nxDomain";
      blockTTL = "1m";
      loading = {
        refreshPeriod = "24h";
        downloads = {
          timeout = "60s";
          attempts = 5;
          cooldown = "10s";
        };
        concurrency = 16;
        strategy = "failOnError";
        maxErrorsPerSource = 5;
      };
    };
    caching = {
      minTime = "5m";
      prefetching = true;
    };
    clientLookup.clients = mapAttrs
      (name: value: [ value.ip ])
      ipReservations;

    minTlsServeVersion = "1.3";
    bootstrapDns = [
      "tcp+udp:1.1.1.1"
      "https://1.1.1.1/dns-query"
    ];
    ports = {
      dns = 53;
      tls = 853;
    };
    log = {
      level = "warn";
      format = "text";
      timestamp = false;
      privacy = false;
    };
    ede.enable = true;
    specialUseDomains.rfc6762-appendixG = true;
  };

  security.acme.acceptTerms = true;
  security.acme.defaults = {
    email = "account@${domain}";
    dnsProvider = "dnsimple";
    reloadServices = [ "nginx" ];
    credentialFiles = {
      "DNSIMPLE_OAUTH_TOKEN_FILE" = config.lollypops.secrets.files."net1/acme-dnsimple-envfile".path;
    };
  };

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
          acmeRoot = null;
          locations."/" = {
            proxyPass = "http://${attr.host}.${domain}:${toString attr.port}";
            extraConfig = "proxy_pass_header Authorization;";
          };
        })
      proxyServices;
  };
}
