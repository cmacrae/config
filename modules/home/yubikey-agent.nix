# TODO: will be contributing this to upstream home-manager when ready :)
# TODO: test on NixOS
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.yubikey-agent;

  darwinSocketDir = "${config.home.homeDirectory}/Library/Caches/yubikey-agent";

in
{
  options = {
    services.yubikey-agent = {
      enable = mkEnableOption "Yubikey SSH agent service";

      package = mkOption {
        type = types.package;
        default = pkgs.yubikey-agent;
        description = "The yubikey-agent package to use.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];
    }

    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.yubikey-agent = {
        Unit = {
          Description = "Yubikey SSH agent";
          Documentation = "man:yubikey-agent(1)";
          Requires = "yubikey-agent.socket";
          After = "yubikey-agent.socket";
          RefuseManualStart = true;
        };

        Service = {
          ExecStart = "${cfg.package}/bin/yubikey-agent -l %t/yubikey-agent/yubikey-agent.sock";
          Type = "simple";
        };
      };

      systemd.user.sockets.yubikey-agent = {
        Unit = {
          Description = "Unix domain socket for Yubikey SSH agent";
          Documentation = "man:yubikey-agent(1)";
        };

        Socket = {
          ListenStream = "%t/yubikey-agent/yubikey-agent.sock";
          RuntimeDirectory = "yubikey-agent";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install = { WantedBy = [ "sockets.target" ]; };
      };

      home.sessionVariables = {
        SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/yubikey-agent/yubikey-agent.sock";
      };
    })

    (mkIf pkgs.stdenv.isDarwin {
      # Create the socket directory
      home.file."Library/Caches/yubikey-agent/.keep".text = "";

      launchd.agents.yubikey-agent = {
        enable = true;
        config = {
          ProgramArguments = [
            "${cfg.package}/bin/yubikey-agent"
            "-l"
            "${darwinSocketDir}/yubikey-agent.sock"
          ];

          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          ProcessType = "Background";
          Sockets = {
            Listener = {
              SockPathName = "${darwinSocketDir}/yubikey-agent.sock";
              SockPathMode = 384; # 0600 in decimal
            };
          };
        };
      };

      home.sessionVariables = {
        SSH_AUTH_SOCK = "${darwinSocketDir}/yubikey-agent.sock";
      };
    })
  ]);
}
