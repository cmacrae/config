{
  imports = [ ../../modules/darwin.nix ];
  local.darwin.machine = "macbook";
  local.darwin.skhd.extraBindings = ''
    cmd + ctrl - f : open  -n ~/.nix-profile/Applications/Firefox.app --args -P home
    cmd + shift + ctrl - f : open -n ~/.nix-profile/Applications/Firefox.app --args -P work
  '';

  # Remote builder for linux
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "compute1";
      sshUser = "root";
      sshKey = "$HOME/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
    }
    {
      hostName = "compute2";
      sshUser = "root";
      sshKey = "$HOME/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
    }
    {
      hostName = "compute3";
      sshUser = "root";
      sshKey = "$HOME/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
    }
    {
      hostName = "10.0.0.2";
      sshUser = "root";
      sshKey = "$HOME/.ssh/id_rsa";
      systems = [ "aarch64-linux" ];
      maxJobs = 4;
    }
  ];
}
