{
  description = "cmacrae's systems configuration";

  nixConfig = {
    extra-substituters = [
      "https://cmacrae.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cmacrae.cachix.org-1:5Mp1lhT/6baI3eAqnEvruhLrrXE9CKe27SbnXqjwXfg="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    ez-configs.url = "github:ehllie/ez-configs";
    ez-configs.inputs.nixpkgs.follows = "nixpkgs";
    ez-configs.inputs.flake-parts.follows = "flake-parts";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    # FIXME: tracking a fork until issues discussed here are addressed 
    #        https://github.com/nix-community/home-manager/issues/3864
    # url = "github:nix-community/home-manager/release-24.05";
    home-manager.url = "github:cmacrae/home-manager/fix/gpg-agent_launchd";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs";

    # Emacs
    # FIXME: move back to default branch once this is merged
    #        https://github.com/emacs-twist/twist.nix/pull/183
    #        the elisp-helpers follow can go after the merge also.
    elisp-helpers.url = "github:emacs-twist/elisp-helpers";
    twist.url = "github:emacs-twist/twist.nix/non-overlay-api";
    twist.inputs.elisp-helpers.follows = "elisp-helpers";
    org-babel.url = "github:emacs-twist/org-babel";
    emacs.url = "github:emacs-mirror/emacs";
    emacs.flake = false;
    melpa.url = "github:melpa/melpa";
    melpa.flake = false;
    gnu-elpa.url = "github:elpa-mirrors/elpa";
    gnu-elpa.flake = false;
    nongnu-elpa.url = "github:elpa-mirrors/nongnu";
    nongnu-elpa.flake = false;
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.ez-configs.flakeModule ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem = { config, pkgs, system, emacs-env, emacs-early-init, ... }: {
        _module.args = {
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.emacs-overlay.overlays.emacs
              inputs.org-babel.overlays.default
            ];
          };

          emacs-env = import ./configurations/emacs {
            inherit inputs pkgs;
          };

          emacs-early-init =
            let
              org = inputs.org-babel.lib;
            in
            (pkgs.tangleOrgBabelFile "early-init.el" ./configurations/emacs/README.org {
              processLines = org.selectHeadlines (org.tag "early");
            });

          config.extraSpecialArgs = {
            inherit emacs-env emacs-early-init;
          };
        };

        packages = {
          inherit emacs-env emacs-early-init;
        };

        apps = emacs-env.makeApps {
          lockDirName = "configurations/emacs/.lock";
        };
      };

      ezConfigs = {
        globalArgs = { inherit inputs; };
      } // builtins.listToAttrs (map
        (name: {
          inherit name;
          value = {
            modulesDirectory = ./. + "/modules/${name}";
            configurationsDirectory = ./. + "/configurations/${name}";
          };
        }) [ "home" "darwin" "nixos" ]);
    };
}
