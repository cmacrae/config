{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.tart;

  tartActivationScript = name: vm:
    let
      vmPath = "${config.home.homeDirectory}/.tart/vms/${name}";
    in
    ''
      if [ ! -d ${vmPath} ]; then
        mkdir -p ${vmPath}

        cp ${vm.pkg}/config.json ${vmPath}/config.json
        chmod +w ${vmPath}/config.json

        cp ${vm.pkg}/disk.img ${vmPath}/disk.img
        chmod +w ${vmPath}/disk.img

        cp ${vm.pkg}/nvram.bin ${vmPath}/nvram.bin
        chmod +w ${vmPath}/nvram.bin
      fi
    '';
in
{

  options.programs.tart = {
    enable = mkEnableOption "Tart VM management";

    vms = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          runAtLoad = mkOption {
            type = types.bool;
            default = false;
            description = "Whether the VM should run at load.";
          };

          vmRunArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "--rosetta=rosetta" "--no-graphics" ];
            description = "Additional arguments to pass to the tart run command for VMs.";
          };

          pkg = mkOption {
            type = types.package;
            description = "Package containing VM data.";
          };
        };
      }));
      default = { };
      description = "Tart VM configurations.";
    };
  };

  config = mkIf cfg.enable {

    home.packages = [ pkgs.tart ];

    # home.file = 
    #   pkgs.lib.mapAttrs' (name: vm: {
    #     name = ".tart/vms/${name}/config.json";
    #     value = { source = "${vm.pkg}/config.json"; };
    #   }) cfg.vms
    #   //
    #   pkgs.lib.mapAttrs' (name: vm: {
    #     name = ".tart/vms/${name}/disk.img";
    #     value = { source = "${vm.pkg}/disk.img"; };
    #   }) cfg.vms;

    home.activation.setupTartVMs = lib.hm.dag.entryAfter [ "writeBoundary" ] (lib.concatStringsSep "\n" (lib.mapAttrsToList tartActivationScript cfg.vms));

    launchd.agents = mapAttrs'
      (name: vm: {
        name = "tart-${name}";
        value = {
          enable = true;
          config = {
            Label = "ae.cmacr.tart-${name}";
            ProgramArguments = [
              "${pkgs.tart}/bin/tart"
              "run"
            ]
            ++ vm.vmRunArgs ++
            [ name ];
            RunAtLoad = vm.runAtLoad;
          };
        };
      })
      cfg.vms;

  };
}
