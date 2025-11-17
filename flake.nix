{
  description = "cmacrae's systems configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    ez-configs.url = "github:ehllie/ez-configs";
    ez-configs.inputs.nixpkgs.follows = "nixpkgs";
    ez-configs.inputs.flake-parts.follows = "flake-parts";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # NOTE: currently private, working on releasing soon :)
    limani.url = "github:cmacrae/limani";
    limani.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    # Emacs
    # TODO: switch back to upstream once PR is accepted:
    #       https://github.com/emacs-twist/twist.nix/pull/192
    twist.url = "github:emacs-twist/twist.nix";
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

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.ez-configs.flakeModule ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem =
        {
          config,
          pkgs,
          system,
          emacs-env,
          emacs-early-init,
          ...
        }:
        {
          _module.args = {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                allowUnfreePredicate = _: true;
              };
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

          formatter = pkgs.nixfmt-tree;
        };

      ezConfigs = {
        globalArgs = { inherit inputs; };
      }
      // builtins.listToAttrs (
        map
          (name: {
            inherit name;
            value = {
              modulesDirectory = ./. + "/modules/${name}";
              configurationsDirectory = ./. + "/configurations/${name}";
            };
          })
          [
            "home"
            "darwin"
            "nixos"
          ]
      );
    };
}
