{ config, pkgs, inputs, ... }:

let
  inherit (config.networking) hostName;

in
{

  imports = with inputs; [
    "${self}/modules/shared"
    home-manager.darwinModules.home-manager
  ];

  # Recreate /run/current-system symlink after boot
  services.activate-system.enable = true;

  services.nix-daemon.enable = true;

  system.stateVersion = 5;

  users.users.cmacrae = {
    description = "Calum MacRae";
    shell = pkgs.zsh;
    home = "/Users/cmacrae";
  };

  networking.computerName = hostName;
  networking.localHostName = hostName;

  nix.configureBuildUsers = true;

  programs.bash.enable = false;

  security.pam.enableSudoTouchIdAuth = true;

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    dock.minimize-to-application = true;
    dock.show-recents = false;

    spaces.spans-displays = false;
    screencapture.location = "/tmp";

    finder.AppleShowAllExtensions = true;
    finder.FXEnableExtensionChangeWarning = false;
    finder.CreateDesktop = false;
    finder.FXPreferredViewStyle = "Nlsv"; # list view
    finder.ShowPathbar = true;

    loginwindow.GuestEnabled = false;

    CustomUserPreferences = {
      # 3 finger dragging
      "com.apple.AppleMultitouchTrackpad".DragLock = false;
      "com.apple.AppleMultitouchTrackpad".Dragging = false;
      "com.apple.AppleMultitouchTrackpad".TrackpadThreeFingerDrag = true;

      # Finder's default location upon open
      "com.apple.finder".NewWindowTargetPath = "file://${config.users.users.cmacrae.home}/";
    };

    NSGlobalDomain.AppleICUForce24HourTime = true;
    NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = true;
    NSGlobalDomain.AppleShowScrollBars = "WhenScrolling";
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
    NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
    NSGlobalDomain."com.apple.trackpad.scaling" = 3.0;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  ############
  # Homebrew #
  ############
  homebrew.enable = true;
  homebrew.onActivation.autoUpdate = true;
  homebrew.onActivation.upgrade = true;
  homebrew.onActivation.cleanup = "zap";
  homebrew.global.brewfile = true;
  homebrew.caskArgs.language = "en-GB";

  homebrew.casks = [
    "discord"
    "element"
    "figma"
    "firefox"
    "keepingyouawake"
    "notion"
    "spotify"
  ];

  # TODO: previously used this to keep casks up to date
  #       but it's not ideal...
  #       potentially look at using nix-homebrew?
  # system.activationScripts.postUserActivation.text = ''
  #   echo "Upgrading Homebrew Casks..."
  #   ${config.homebrew.brewPrefix}/brew upgrade --casks \
  #   ${pkgs.lib.concatStringsSep " " homebrew.casks}
  # '';

  homebrew.masApps = {
    WireGuard = 1451685025;
    YubicoAuthenticator = 1497506650;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    users.cmacrae = {
      imports = [ inputs.self.homeModules.default ];
    };
  };
}
