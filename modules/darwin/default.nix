{ config, pkgs, inputs, ... }:

let
  inherit (config.networking) hostName;

in
{

  imports = with inputs; [
    "${self}/modules/shared"
    home-manager-darwin.darwinModules.home-manager
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
    "claude"
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
      imports = [
        inputs.self.homeModules.default
        inputs.self.homeModules.aerospace
        inputs.self.homeModules.jankyborders
      ];

      programs.aerospace.enable = true;
      programs.aerospace.config = {
        enable-normalization-flatten-containers = true;
        enable-normalization-opposite-orientation-for-nested-containers = true;
        accordion-padding = 30;
        default-root-container-layout = "tiles";
        default-root-container-orientation = "auto";
        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
        automatically-unhide-macos-hidden-apps = true;

        key-mapping = {
          preset = "qwerty";
        };

        gaps =
          let
            pad = 15;
          in
          {
            inner.horizontal = pad;
            inner.vertical = pad;
            outer = {
              left = pad;
              bottom = pad;
              top = pad;
              right = pad;
            };
          };

        mode = {
          main.binding =
            let
              mkWorkspaceBindings = prefix: action:
                builtins.listToAttrs (map
                  (i: {
                    name = "${prefix}${toString i}";
                    value = "${action} ${toString i}";
                  })
                  (builtins.genList (x: x + 1) 9));

              directionBindings = builtins.listToAttrs (builtins.concatMap
                (dir: [
                  { name = "cmd-ctrl-${dir.key}"; value = "focus ${dir.name}"; }
                  { name = "cmd-ctrl-shift-${dir.key}"; value = "move ${dir.name}"; }
                ])
                [
                  { key = "h"; name = "left"; }
                  { key = "j"; name = "down"; }
                  { key = "k"; name = "up"; }
                  { key = "l"; name = "right"; }
                ]);

            in
            {
              "cmd-ctrl-slash" = "layout tiles horizontal vertical";
              "cmd-ctrl-comma" = "layout accordion horizontal vertical";
              "cmd-ctrl-n" = "workspace next";
              "cmd-ctrl-p" = "workspace prev";
              "cmd-ctrl-shift-n" = "move-node-to-workspace next";
              "cmd-ctrl-shift-p" = "move-node-to-workspace prev";
              "cmd-ctrl-minus" = "resize smart -50";
              "cmd-ctrl-equal" = "resize smart +50";
              "cmd-ctrl-tab" = "workspace-back-and-forth";
              "cmd-ctrl-shift-tab" = "move-workspace-to-monitor --wrap-around next";
              "cmd-ctrl-f" = "layout floating tiling";
              "cmd-ctrl-semicolon" = "mode service";
              "cmd-ctrl-a" = "mode apps";
              "cmd-ctrl-r" = "mode resize";
            }
            // directionBindings
            // mkWorkspaceBindings "cmd-ctrl-" "workspace"
            // mkWorkspaceBindings "cmd-ctrl-shift-" "move-node-to-workspace";

          apps.binding = {
            "e" = [ "exec-and-forget zsh -c /etc/profiles/per-user/cmacrae/bin/emacs" "mode main" ];
            "f" = [ "exec-and-forget open -a /Applications/Firefox.app --args '--profile ~/Library/Application\ Support/Firefox/Profiles/home'" "mode main" ];
          };

          service.binding = {
            "a" = [ "layout accordion" "mode main" ];
            "r" = [ "flatten-workspace-tree" "mode main" ];
            "f" = [ "layout floating tiling" "mode main" ];
            "backspace" = [ "close-all-windows-but-current" "mode main" ];
            "cmd-ctrl-shift-h" = [ "join-with left" "mode main" ];
            "cmd-ctrl-shift-j" = [ "join-with down" "mode main" ];
            "cmd-ctrl-shift-k" = [ "join-with up" "mode main" ];
            "cmd-ctrl-shift-l" = [ "join-with right" "mode main" ];
          };

          resize.binding = {
            h = "resize width -50";
            j = "resize height +50";
            k = "resize height -50";
            l = "resize width +50";
            b = [ "balance-sizes" "mode main" ];
            enter = "mode main";
            esc = "mode main";
          };
        };
      };

      programs.jankyborders.enable = true;
      programs.jankyborders.config = {
        active_color = "0xffcdedfd";
        inactive_color = "0xff494d64";
        width = 8.0;
      };
    };
  };
}
