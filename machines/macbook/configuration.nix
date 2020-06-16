{ lib, config, pkgs, ...}:
with lib; {
  imports = attrValues (import ../../modules);
  networking.hostName = "macbook";

  nix.distributedBuilds = true;
  nix.buildMachines =
    let
      linuxHost = {
        hostName = "compute";
        sshUser = "root";
        sshKey = "${builtins.getEnv("HOME")}/.ssh/id_rsa";
        systems = [ "x86_64-linux" ];
        maxJobs = 16;
      };
    in
      forEach (range 1 3) (n:
        linuxHost // {
          hostName = "compute${builtins.toString n}";
        }) ++ [
          (linuxHost // {
            hostName = "10.0.0.2";
            systems = [ "aarch64-linux" ];
            maxJobs = 4;
          })
        ];
}
