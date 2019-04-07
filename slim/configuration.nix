{
  network.description = "Multipurpose home server";
  network.enableRollback = true;

  slim =  { config, pkgs, ... }: {
    deployment.hasFastConnection = true;

    imports =
        [
          ./hardware-configuration.nix
          ../lib/media-nfs.nix
        ];
    
    boot.cleanTmpDir = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    boot.loader.grub.zfsSupport = true;
    boot.loader.grub.copyKernels = true;
    boot.loader.grub.device = "nodev";
    boot.loader.efi.efiSysMountPoint = "/efi";
    boot.initrd.checkJournalingFS = false;
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.supportedFilesystems = [ "zfs" ];
    
    networking.hostId = "7aeb7d41";
    networking.hostName = "slim";
    networking.firewall.enable = false;
    
    time.timeZone = "Europe/London";
    
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs; [
      file vim nfs-utils p7zip
    ];
    
    services.openssh.enable = true;
    
    security.sudo.enable = true;
    
    users.users.admin = {
      description = "Administrator";
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "tty"
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDI0ynIFxGh/vtMnReWNA0m0JVQHuP72vi3+jOUDvWZMU+rDX7uljyw8wAsD5u4D5G5GlDp+A0kUo2ASk+NMvz55885woLix/q7P63meeOKOepteIzwdHP6ZYdEzjlLZSCinvf9bumMyiTzqvA/cEFgmUfCz3LEQ9qzoo4b9y/W7J84cUJBTascE3VU6pdG3AIl7wR5VnXu6USuEQl/XVAPUV9y5w+7lwIfBLDXp4DaHnsP7Xc8gTovb/CpsLk7pknd0hPaIFsqTAUmVnplDxjSo/3E+MeCFbzqqt42HBCVQj+CHgwhsqIawll4B1FwnULJAiWhqFAzG6emprEYqN3x"
      ];
    };
    
    services.nginx ={
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      clientMaxBodySize = "100m";

      virtualHosts."slim.cmacr.ae" = {
        locations."/web" = {
          proxyPass = "http://127.0.0.1:32400";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            # Plex headers
            proxy_set_header X-Plex-Client-Identifier $http_x_plex_client_identifier;
            proxy_set_header X-Plex-Device $http_x_plex_device;
            proxy_set_header X-Plex-Device-Name $http_x_plex_device_name;
            proxy_set_header X-Plex-Platform $http_x_plex_platform;
            proxy_set_header X-Plex-Platform-Version $http_x_plex_platform_version;
            proxy_set_header X-Plex-Product $http_x_plex_product;
            proxy_set_header X-Plex-Token $http_x_plex_token;
            proxy_set_header X-Plex-Version $http_x_plex_version;
            proxy_set_header X-Plex-Nocache $http_x_plex_nocache;
            proxy_set_header X-Plex-Provides $http_x_plex_provides;
            proxy_set_header X-Plex-Device-Vendor $http_x_plex_device_vendor;
            proxy_set_header X-Plex-Model $http_x_plex_model;
          '';
        };

        locations."/sonarr" = {
          proxyPass = "http://127.0.0.1:8989";
        };

        locations."/radarr" = {
          proxyPass = "http://127.0.0.1:7878";
        };

        locations."/nzbget" = {
          proxyPass = "http://127.0.0.1:6789";
        };

        extraConfig = ''
          if ($http_referer ~ /plex/) {
		        rewrite ^/plex/web/(.*) /plex/web/$1? redirect;
	        }
        '';
      };
    };
  
    # NOTE: PR open for some fixes around user/group:
    #       https://github.com/NixOS/nixpkgs/pull/58928
    services.nzbget = {
      enable = true;
      user = "media";
      group = "media";
    };
  
    services.sonarr = {
      enable = true;
      user = "media";
      group = "media";
    };
  
    services.radarr = {
      enable = true;
      user = "media";
      group = "media";
    };

    services.plex = {
      enable = true;
      user = "media";
      group = "media";
    };

    system.stateVersion = "19.03";
  };
}
