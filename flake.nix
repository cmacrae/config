{
  description = "cmacrae's darwin systems configuration";

  inputs = {
    # TODO: Move to 20.09 when stdenv fix on Big Sur is backported
    # nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-${release}-darwin";
    nixpkgs.url = "github:nixos/nixpkgs";
    # TODO: Move back to upstream nix-darwin when done with local dev
    # darwin.url = "github:lnl7/nix-darwin/master";
    darwin.url = "/Users/cmacrae/src/github.com/cmacrae/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    # TODO: Move back to release branch when msmtp passwordCommand no longer
    #       uses appended 'echo'
    # home.url = "github:nix-community/home-manager/release-20.09";
    home.url = "github:nix-community/home-manager";
    home.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
    emacs.url = "github:nix-community/emacs-overlay";
  };

  outputs = { self, nixpkgs, darwin, home, nur, emacs }: {
    darwinConfigurations.macbook = darwin.lib.darwinSystem {
      modules = [
        ./macintosh.nix
        home.darwinModules.home-manager

        {
          nixpkgs.overlays = [
            nur.overlay
            emacs.overlay
          ];
        }

        ({pkgs, config, ...}: {
          networking.hostName = "macbook";

          nix.distributedBuilds = true;
          nix.buildMachines =
            pkgs.lib.forEach (pkgs.lib.range 1 3) (n:
              {
                hostName = "compute${builtins.toString n}";
                sshUser = "root";
                sshKey = "${config.users.users.cmacrae.home}/.ssh/id_rsa";
                systems = [ "aarch64-linux" "x86_64-linux" ];
                maxJobs = 16;
              });
        })
      ];
    };

    darwinConfigurations.workbook = darwin.lib.darwinSystem {
      modules = [
        ./macintosh.nix
        home.darwinModules.home-manager

        {
          nixpkgs.overlays = [
            nur.overlay
            emacs.overlay
          ];
        }

        ({ pkgs, ... }: {
          networking.hostName = "workbook";
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
              in rec {
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
        })
      ];
    };
  };
}
