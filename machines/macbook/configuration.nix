{ lib, config, pkgs, ...}:
let
  homeDir = builtins.getEnv("HOME");

in {
  imports = lib.attrValues (import ../../modules);
  local.darwin.machine = "macbook";

  # Remote builder for linux
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "compute1";
      sshUser = "root";
      sshKey = "${homeDir}/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
    }
    {
      hostName = "compute2";
      sshUser = "root";
      sshKey = "${homeDir}/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
    }
    {
      hostName = "compute3";
      sshUser = "root";
      sshKey = "${homeDir}/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
    }
    {
      hostName = "10.0.0.2";
      sshUser = "root";
      sshKey = "${homeDir}/.ssh/id_rsa";
      systems = [ "aarch64-linux" ];
      maxJobs = 4;
    }
  ];
}
