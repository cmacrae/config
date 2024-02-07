{ ... }: {

  lollypops.deployment = {
    sudo.enable = true;
    ssh.user = "admin";
  };

  services.openssh.enable = true;

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
    openssh.authorizedKeys.keyFiles = [
      (builtins.fetchurl {
        url = "https://github.com/cmacrae.keys";
        sha256 = "0rdmkxxzy8q3qcz1cmd5b2469nvzd05cjdks1arm1avalzhaif1q";
      })
    ];
    initialHashedPassword = "$6$kRpI1h4RlNelJ/u$lYJmNiQ03B.Q7jfdOvWLN6jv9aPf53geVa9RHsQ1t5WWDqOgjCFgh1or.03YXT1JGI7ySUXLyR1Eyscqq5vXZ/";
  };

  documentation.enable = false;
}
