{ config, pkgs, lib, ... }:

let
  cfg = config.compute;

in
  with pkgs.lib; {
    options = {
      compute = {

        efiBlockId = mkOption {
          type = types.str;
          description = "EFI block device ID to map in filesystems configuration.";
        };

        id = mkOption {
          type = types.int;
          default = 0;
          description = ''
            Numerical ID to assign to each compute node.
            This will be used in the hostname and static IP address assignment.
          '';
        };

        domain = mkOption {
          type = types.str;
          description = "DNS domain for compute nodes.";
        };

        hostId = mkOption {
          type = types.str;
          description = "Unique network host ID for ZFS support.";
        };
      };
    };

    config = {
      # Boot
      boot.cleanTmpDir = true;
      boot.loader.grub.efiSupport = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.grub.zfsSupport = true;
      boot.loader.grub.copyKernels = true;
      boot.loader.grub.device = "nodev";
      boot.loader.efi.efiSysMountPoint = "/boot";
      boot.initrd.checkJournalingFS = false;
      boot.supportedFilesystems = [ "zfs" ];
      boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
      boot.kernelModules = [
        "kvm-intel"

        # NOTE: Required by cilium
        "ebtable_nat"
        "ebtable_broute"
        "bridge"
        "ip6table_nat"
        "nf_nat_ipv6"
        "ip6table_mangle"
        "ip6table_raw"
        "ip6table_security"
        "iptable_nat"
        "nf_nat_ipv4"
        "iptable_mangle"
        "iptable_raw"
        "iptable_security"
        "ebtable_filter"
        "ebtables"
        "ip6table_filter"
        "ip6_tables"
        "iptable_filter"
        "ip_tables"
        "x_tables"
        "xt_socket"
      ];

      boot.extraModulePackages = [];

      # aarch64 emulation
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      fileSystems."/" =
        {
          device = "rpool/root";
          fsType = "zfs";
        };

      fileSystems."/home" =
        {
          device = "rpool/home";
          fsType = "zfs";
        };

      fileSystems."/boot" =
        {
          device = "/dev/disk/by-uuid/${cfg.efiBlockId}";
          fsType = "vfat";
        };

      swapDevices = [];

      nix.maxJobs = "auto";
      powerManagement.cpuFreqGovernor = "ondemand";

      # NFS Mounts
      fileSystems."/media" = {
        device = "ds1819.${cfg.domain}:/volume1/media";
        fsType = "nfs";
      };

      # Network
      networking = {
        hostName = "compute${builtins.toString cfg.id}";
        hostId = cfg.hostId;
        domain = cfg.domain;
        dhcpcd.enable = false;
        defaultGateway = "10.0.0.1";
        firewall.enable = false;
        nameservers = [ "10.0.0.2" ];
        interfaces.enp0s25.ipv4.addresses = [
          {
            address = "10.0.10.${builtins.toString cfg.id}";
            prefixLength = 16;
          }
        ];
      };

      boot.kernel.sysctl = {
        # Needed for packet routing on the 'cilium_host' interface
        # NOTE: This is a workaround for the following issue
        # https://github.com/cilium/cilium/issues/10645
        "net.ipv4.conf.lxc*.rp_filter" = 0;
        "net.ipv4.conf.cilium_*.rp_filter" = 0;

        # NOTE: Various parameters usually set by cilium agent at startup
        "net.core.bpf_jit_enable" = 1;
        "net.ipv4.conf.all.rp_filter" = 0;
        "kernel.unprivileged_bpf_disabled" = 1;
        "kernel.timer_migration" = 0;
      };

      # System packages
      environment.systemPackages = with pkgs; [ kubectl nfs-utils iptables ];

      # nix-serve
      services.nix-serve.enable = true;
      services.nix-serve.secretKeyFile =
        config.sops.secrets."${config.networking.hostName}_store_privatekey".path;
      systemd.services.nix-serve = {
        serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
      };

      ##############
      # Kubernetes #
      ##############

      # nixpkgs.overlays = [
      #   (self: super: {
      #     kube-autojoin = super.callPackage ../utils/nixos-kube-autojoin;
      #   })
      # ];

      # kube-autojoin
      # TODO: Get overlay working here
      # systemd.services."kube-autojoin" =
      #   let
      #     kube-autojoin = pkgs.callPackage ../../utils/nixos-kube-autojoin { inherit (pkgs) lib; };
      #   in mkMerge [
      #     {
      #       description = "Autojoin kubernetes clusters";
      #       after = if (cfg.id == 1) then ["etcd.service"] else ["kubernetes.target"];
      #       wantedBy = ["kubernetes.target"];
      #       serviceConfig = {
      #         Restart = if (cfg.id == 1) then "always" else "on-failure";
      #         Type = "simple";
      #         ExecStart =
      #           if (cfg.id == 1)
      #           then "${kube-autojoin}/bin/nixos-kube-autojoin -server -no-kube-proxy -no-flannel"
      #           else "${kube-autojoin}/bin/nixos-kube-autojoin -no-kube-proxy -no-flannel -endpoint http://${config.services.kubernetes.masterAddress}:3000";
      #       };
      #     }

      #     (mkIf (cfg.id != 0) {
      #       unitConfig.ConditionFileNotEmpty = "!/var/lib/kubernetes/secrets/apitoken.secret";
      #     })
      #   ];


      # # CRI-O
      # virtualisation.docker.enable = false;
      # virtualisation.cri-o.enable = true;
      # virtualisation.cri-o.storageDriver = "zfs";
      # virtualisation.cri-o.extraPackages = [ pkgs.conntrack-tools pkgs.iptables ];
      # systemd.services.kubelet.path = with pkgs; [ zfs conntrack-tools ];

      # ###########################
      # # Cluster bootstrap fixes #
      # ###########################
      # # etcd
      # # NOTE: Workaround for initial deployment failure
      # systemd.services.etcd.preStart = ''${pkgs.writeShellScript "etcd-wait" ''
      #   while [ ! -f /var/lib/kubernetes/secrets/etcd.pem ]; do sleep 1; done
      # ''}'';

      # # kubelet
      # # NOTE: Workaround for initial deployment failure
      # systemd.services.kubelet.preStart = mkAfter ''
      #   while [ ! -f /var/lib/kubernetes/secrets/ca.pem ]; do sleep 1; done
      #   while [ ! -f /var/lib/kubernetes/secrets/kubelet-client.pem ]; do sleep 1; done
      # '';

      # # kube-apiserver
      # # NOTE: Workaround for initial deployment failure
      # systemd.services.kube-apiserver.preStart = mkAfter ''
      #   while [ ! -f /var/lib/kubernetes/secrets/kube-apiserver.pem ]; do sleep 1; done
      # '';

      # services.kubernetes = {
      #   easyCerts = true;

      #   masterAddress = "k8s.${cfg.domain}";
      #   apiserverAddress = "https://${config.services.kubernetes.masterAddress}:6443";
      #   addonManager.enable = false;
      #   apiserver.serviceClusterIpRange = "10.2.0.0/24";
      #   apiserver.extraSANs =
      #     optional (builtins.elem "master" config.services.kubernetes.roles)
      #       "10.0.10.${builtins.toString cfg.id}";

      #   apiserver.authorizationMode = [ "AlwaysAllow" ];
      #   # NOTE: allow-privileged is needed for cilium
      #   apiserver.extraOpts = ''
      #     --allow-privileged=true
      #     --requestheader-client-ca-file=${config.services.kubernetes.apiserver.clientCaFile}
      # # # #     --requestheader-allowed-names=front-proxy-client
      #     --requestheader-extra-headers-prefix=X-Remote-Extra-
      #     --requestheader-group-headers=X-Remote-Group
      #     --requestheader-username-headers=X-Remote-User
      #   '';


      #   # More CRI-O
      #   kubelet.cri.runtime = "cri-o";
      #   kubelet.extraOpts = ''
      #     --cgroup-driver systemd \
      #   '';

      #   # CNI configuration
      #   proxy.enable = false;
      #   flannel.enable = false;
      #   kubelet.networkPlugin = "cni";
      #   kubelet.cni.configDir = "/etc/cni/net.d";
      #   kubelet.clusterDns = "10.2.0.254";
      #   controllerManager.allocateNodeCIDRs = true;
      #   controllerManager.clusterCidr = "10.1.0.0/16";
      # };

      # pantheon = {
      #   iscsi.enable = true;
      #   iscsi.initiatorPrefix = "iqn.2000-01.ae.cmacr";
      #   iscsi.portal = "10.0.1.1";
      # };

    };
  }
