{
  description = "cmacrae's systems configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
    stylix.url = "github:danth/stylix";
    lollypops.url = "github:pinpox/lollypops";

    # TODO: move to nixpkgs provided kernel once vendor patches
    #       are available upstream
    nix-rpi5.url = "gitlab:vriska/nix-rpi5";

    flakelight = {
      url = "github:nix-community/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { flakelight, ... }@inputs:
    flakelight ./. {
      inherit inputs;
      withOverlays = with inputs; [
        emacs-overlay.overlays.package
        emacs-overlay.overlays.emacs
        nixos-apple-silicon.overlays.apple-silicon-overlay
        nur.overlay
      ];

      apps.default = { system, ... }:
        inputs.lollypops.apps.${system}.default {
          configFlake = inputs.self;
        };

      formatter = pkgs: pkgs.nixpkgs-fmt;

      checks.statix = pkgs:
        let
          conf = pkgs.writers.writeTOML "statix.toml" {
            disabled = [ "empty_pattern" "repeated_keys" ];
            ignore = [ "result" ".direnv" ];
          };
        in
        "${pkgs.statix}/bin/statix check --config ${conf}";
      checks.deadnix = pkgs: "${pkgs.deadnix}/bin/deadnix -f -_ -l --exclude result .direnv";
    };
} 
