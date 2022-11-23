{ config, pkgs, ... }: {
  system.stateVersion = "23.05";

  nix.settings.auto-optimise-store = true;
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.gc.options = "--delete-older-than 14d";
  nix.settings.trusted-users = [ "root" "@wheel" ];
  nix.settings.max-jobs = "auto";

  # Free up to 1GiB whenever there is less than 100MiB left.
  nix.extraOptions = ''
    min-free = ${toString (100 * 1024 * 1024)}
    max-free = ${toString (1024 * 1024 * 1024)}
  '';

  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/London";
  environment.systemPackages = with pkgs; [ file rsync vim ];

  services.openssh.enable = true;

  # services.prometheus.exporters.node = {
  #   enable = true;
  #   enabledCollectors = [ "systemd" ];
  # };

  # services.promtail = {
  #   enable = true;
  #   configuration = {
  #     server.http_listen_port = 28183;
  #     positions.filename = "/tmp/positions.yaml";
  #     clients = [{
  #       url = "http://compute1.cmacr.ae:3100/loki/api/v1/push";
  #     }];
  #     scrape_configs = [{
  #       job_name = "journal";
  #       journal = {
  #         max_age = "12h";
  #         labels.job = "systemd-journal";
  #         labels.host = config.networking.hostName;
  #       };
  #       relabel_configs = [{
  #         source_labels = [ "__journal__systemd_unit" ];
  #         target_label = "unit";
  #       }];
  #     }];
  #   };
  # };

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  users.groups.admin.gid = 1001;
  users.users.admin = {
    description = "Administrator";
    isNormalUser = true;
    uid = 1001;
    group = "admin";
    extraGroups = [
      "tty"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDI0ynIFxGh/vtMnReWNA0m0JVQHuP72vi3+jOUDvWZMU+rDX7uljyw8wAsD5u4D5G5GlDp+A0kUo2ASk+NMvz55885woLix/q7P63meeOKOepteIzwdHP6ZYdEzjlLZSCinvf9bumMyiTzqvA/cEFgmUfCz3LEQ9qzoo4b9y/W7J84cUJBTascE3VU6pdG3AIl7wR5VnXu6USuEQl/XVAPUV9y5w+7lwIfBLDXp4DaHnsP7Xc8gTovb/CpsLk7pknd0hPaIFsqTAUmVnplDxjSo/3E+MeCFbzqqt42HBCVQj+CHgwhsqIawll4B1FwnULJAiWhqFAzG6emprEYqN3x" ];
    initialHashedPassword = "$6$kRpI1h4RlNelJ/u$lYJmNiQ03B.Q7jfdOvWLN6jv9aPf53geVa9RHsQ1t5WWDqOgjCFgh1or.03YXT1JGI7ySUXLyR1Eyscqq5vXZ/";
  };

  documentation.enable = false;
}
