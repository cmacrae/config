{
  description = "cmacrae's darwin systems configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    home.url = "github:nix-community/home-manager";
    nur.url = "github:nix-community/NUR";
    emacs.url = "github:cmacrae/emacs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    rnix-lsp.url = "github:nix-community/rnix-lsp";
    spacebar.url = "github:cmacrae/spacebar";

    # Follows
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home.inputs.nixpkgs.follows = "nixpkgs";
    rnix-lsp.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, home, nur, emacs, emacs-overlay, rnix-lsp, spacebar }:
    let
      commonConfig = [
        ./macintosh.nix
        ./modules/mbsync.nix
        home.darwinModules.home-manager

        {
          nixpkgs.overlays = [
            nur.overlay
            emacs.overlay
            emacs-overlay.overlay
            spacebar.overlay
          ];
        }
      ];

      mailIndicator = mailbox: ''"mu find 'm:/${mailbox}/inbox' flag:unread | wc -l | tr -d \"[:blank:]\""'';
    in
      {
        darwinConfigurations.macbook = darwin.lib.darwinSystem {
          modules = commonConfig ++ [
            (
              { pkgs, config, ... }: {
                networking.hostName = "macbook";

                services.spacebar.config.right_shell_command = mailIndicator "fastmail";

                nix.distributedBuilds = true;
                nix.buildMachines =
                  pkgs.lib.forEach (pkgs.lib.range 1 3) (
                    n:
                      {
                        hostName = "compute${builtins.toString n}";
                        sshUser = "root";
                        sshKey = "${config.users.users.cmacrae.home}/.ssh/id_rsa";
                        systems = [ "aarch64-linux" "x86_64-linux" ];
                        maxJobs = 16;
                      }
                  );

                homebrew.masApps = {
                  Xcode = 497799835;
                };

                homebrew.brews = [ "ios-deploy" ];
              }
            )
          ];
        };

        darwinConfigurations.workbook = darwin.lib.darwinSystem {
          modules = commonConfig ++ [
            (
              { pkgs, ... }: {
                networking.hostName = "workbook";

                services.spacebar.config.right_shell_command = mailIndicator "work";

                home-manager.users.cmacrae = {
                  home.packages = with pkgs; [
                    awscli
                    aws-iam-authenticator
                    vault
                  ];

                  accounts.email.accounts.fastmail.primary = false;
                  accounts.email.accounts.work =
                    let
                      mailAddr = name: domain: "${name}@${domain}";
                    in
                      rec {
                        mu.enable = true;
                        msmtp.enable = true;
                        primary = true;
                        address = mailAddr "calum.macrae" "nutmeg.com";
                        userName = address;
                        realName = "Calum MacRae";

                        mbsync = {
                          enable = true;
                          create = "both";
                          expunge = "both";
                          remove = "both";
                        };

                        imap.host = "outlook.office365.com";
                        smtp.host = "smtp.office365.com";
                        smtp.port = 587;
                        smtp.tls.useStartTls = true;
                        # Office365 IMAP requires an App Password to be created
                        # https://account.activedirectory.windowsazure.com/AppPasswords.aspx
                        passwordCommand = "${pkgs.writeShellScript "work-mbsyncPass" ''
                          ${pkgs.pass}/bin/pass Nutmeg/office.com | ${pkgs.gawk}/bin/awk -F: '/mbsync/{gsub(/ /,""); print$NF}'
                        ''}";
                      };
                };
              }
            )
          ];
        };
      };
}
