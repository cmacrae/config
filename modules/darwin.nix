{ config, lib, pkgs, ... }:
let
  cfg = config.local.darwin;

  homeDir = builtins.getEnv("HOME");

in with lib;
{
  options = {
    local.darwin.machine = mkOption {
      type = types.str;
      description = "Target system to build.";
    };
 };

  config = {
    system.stateVersion = 4;
    nix.maxJobs = 8;
    nix.buildCores = 0;
    nix.package = pkgs.nix;
    services.nix-daemon.enable = true;

    nixpkgs.overlays = [ (import ../overlays) ];

    environment.shells = [ pkgs.zsh ];
    programs.bash.enable = false;
    programs.zsh.enable = true;
    environment.darwinConfig = "${homeDir}/dev/config/machines/${cfg.machine}/configuration.nix";

    networking.hostName = cfg.machine;
    
    environment.systemPackages = [ pkgs.gcc ];

    system.defaults = {
      dock = {
        autohide = true;
        mru-spaces = false;
        minimize-to-application = true;
      };

      screencapture.location = "/tmp";

      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        FXEnableExtensionChangeWarning = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };

      NSGlobalDomain._HIHideMenuBar = true;
    };

    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    services.skhd.enable = true;
    launchd.user.agents.skhd.serviceConfig.ProgramArguments = [
      "${config.services.skhd.package}/bin/skhd" "-c" "${homeDir}/.config/skhd/skhdrc"
    ];

    home-manager.users.cmacrae.xdg.configFile."skhd/skhdrc" = {
      source = pkgs.substituteAll {
        name = "skhdrc";
        src = ../conf.d/skhd.conf;
      };
      onChange = ''
        launchctl stop org.nixos.skhd
        launchctl start org.nixos.skhd
      '';
    };

    home-manager.users.cmacrae.xdg.configFile."alacritty/light.yml".text =
      let lightColours = {
            colors = {
              primary.background = "0xfdf6e3";
              primary.foreground = "0x586e75";

              normal = {
                black = "0x073642";
                red = "0xdc322f";
                green = "0x859900";
                yellow = "0xb58900";
                blue = "0x268bd2";
                magenta = "0xd33682";
                cyan = "0x2aa198";
                white = "0xeee8d5";
              };

              bright = {
                black = "0x002b36";
                red = "0xcb4b16";
                green = "0x586e75";
                yellow = "0x657b83";
                blue = "0x839496";
                magenta = "0x6c71c4";
                cyan = "0x93a1a1";
                white = "0xfdf6e3";
              };
            };
          }; in
        replaceStrings [ "\\\\" ] [ "\\" ]
          (builtins.toJSON (
            config.home-manager.users.cmacrae.programs.alacritty.settings
            // lightColours
          ));

    # For use with nighthook:
    # If there's no 'live.yml' alacritty config initially, copy it
    # from the default config
    environment.extraInit = ''
      test -f ${homeDir}/.config/alacritty/live.yml || \
        cp ${homeDir}/.config/alacritty/alacritty.yml \
        ${homeDir}/.config/alacritty/live.yml
    '';

    launchd.user.agents.nighthook = {
      serviceConfig = {
        Label = "ae.cmacr.nighthook";
        WatchPaths = [ "${homeDir}/Library/Preferences/.GlobalPreferences.plist" ];
        EnvironmentVariables = {
          PATH = (replaceStrings ["$HOME"] [homeDir] config.environment.systemPath);
        };
        ProgramArguments =  [
          ''${pkgs.writeShellScript "nighthook-action" ''
                if defaults read -g AppleInterfaceStyle &>/dev/null ; then
                  MODE="dark"
                else
                  MODE="light"
                fi
                
                emacsSwitchTheme () {
                  if pgrep -q Emacs; then
                	  if [[  $MODE == "dark"  ]]; then
                	      emacsclient --eval "(cm/switch-theme 'doom-one)"
                	  elif [[  $MODE == "light"  ]]; then
                	      emacsclient --eval "(cm/switch-theme 'doom-solarized-light)"
                	  fi
                  fi
                }
                
                spacebarSwitchTheme() {
                  if pgrep -q spacebar; then
                	  if [[  $MODE == "dark"  ]]; then
                	      spacebar -m config background_color 0xff202020
                	      spacebar -m config foreground_color 0xffa8a8a8
                	  elif [[  $MODE == "light"  ]]; then
                	      spacebar -m config background_color 0xffeee8d5
                	      spacebar -m config foreground_color 0xff073642
                	  fi
                  fi 
                }
                
                
                alacrittySwitchTheme() {
                  DIR=/Users/cmacrae/.config/alacritty
                  if [[  $MODE == "dark"  ]]; then
                	  cp -f $DIR/alacritty.yml $DIR/live.yml
                  elif [[  $MODE == "light"  ]]; then
                	  cp -f $DIR/light.yml $DIR/live.yml
                  fi
                }
          
                yabaiSwitchTheme() {
                  if [[  $MODE == "dark"  ]]; then
                    yabai -m config active_window_border_color "0xff5c7e81"
                    yabai -m config normal_window_border_color "0xff505050"
                    yabai -m config insert_window_border_color "0xffd75f5f"
                  elif [[  $MODE == "light"  ]]; then
                    yabai -m config active_window_border_color "0xff2aa198"
                    yabai -m config normal_window_border_color "0xff839496 "
                    yabai -m config insert_window_border_color "0xffdc322f"
                  fi
                }
                
                emacsSwitchTheme $@
                spacebarSwitchTheme $@
                alacrittySwitchTheme $@
                yabaiSwitchTheme $@
          ''}''
        ];
      };
    };

    services.yabai = {
      enable = true;
      enableScriptingAddition = true;
      config = {
        focus_follows_mouse          = "autoraise";
        mouse_follows_focus          = "off";
        window_placement             = "second_child";
        window_opacity               = "off";
        window_opacity_duration      = "0.0";
        window_border                = "on";
        window_border_placement      = "inset";
        window_border_width          = 2;
        window_border_radius         = 3;
        active_window_border_topmost = "off";
        window_topmost               = "on";
        window_shadow                = "float";
        active_window_border_color   = "0xff5c7e81";
        normal_window_border_color   = "0xff505050";
        insert_window_border_color   = "0xffd75f5f";
        active_window_opacity        = "1.0";
        normal_window_opacity        = "1.0";
        split_ratio                  = "0.50";
        auto_balance                 = "on";
        mouse_modifier               = "fn";
        mouse_action1                = "move";
        mouse_action2                = "resize";
        layout                       = "bsp";
        top_padding                  = 36;
        bottom_padding               = 10;
        left_padding                 = 10;
        right_padding                = 10;
        window_gap                   = 10;
      };

      extraConfig = ''
        # rules
        yabai -m rule --add app='System Preferences' manage=off
        yabai -m rule --add app='Live' manage=off

        # events
        # Evaluate gaps/borders for various events
        for e in application_launched application_terminated window_created window_destroyed
        do
        yabai -m signal --add event=$e action="${pkgs.writeShellScript "yabai-smart-gaps" ''
          spaceData=$(yabai -m query --spaces --space)
          spaceWindows=( $(echo $spaceData | ${pkgs.jq}/bin/jq '.windows | .[]') )
          spaceIndex=$(echo $spaceData | ${pkgs.jq}/bin/jq '.index')
          windowCount=$(yabai -m query --windows \
          | ${pkgs.jq}/bin/jq "[.[]|select(.role==\"AXWindow\" and .space==$spaceIndex)]|length")
          if [[ $windowCount -eq 1 ]]; then
              if [[ $(yabai -m query --windows --window | ${pkgs.jq}/bin/jq '.border') -eq 1 ]]; then
                  yabai -m window $${spaceWindows[0]} --toggle border
              fi
              yabai -m space --padding abs:26:0:0:0
              yabai -m space --gap abs:0
          elif [[ $windowCount -gt 1 ]]; then
              if [[ $(yabai -m query --windows --window $${spaceWindows[0]} | ${pkgs.jq}/bin/jq '.border') -eq 0 ]]; then
                  yabai -m window $${spaceWindows[0]} --toggle border
              fi
              yabai -m space --padding abs:36:10:10:10
              yabai -m space --gap abs:10
          fi

        echo "yabai config loaded"
        ''}"
        done
      '';
    };

    services.spacebar.enable = true;
    services.spacebar.config = {
      clock_format     = "%R";
      space_icon_strip = "        ";
      text_font        = ''"Helvetica Neue:Bold:12.0"'';
      icon_font        = ''"FontAwesome:Regular:12.0"'';
      background_color = "0xff202020";
      foreground_color = "0xffa8a8a8";
      power_icon_strip = " ";
      space_icon       = "";
      clock_icon       = "";
    };

    # Recreate /run/current-system symlink after boot
    services.activate-system.enable = true;
  };
}
