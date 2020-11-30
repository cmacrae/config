{ config, lib, pkgs, ... }:

let
  homeDir = builtins.getEnv("HOME");

in with pkgs.stdenv; with lib; {
  system.stateVersion = 4;
  nix.maxJobs = 8;
  nix.buildCores = 0;
  nix.package = pkgs.nix;
  services.nix-daemon.enable = true;

  nixpkgs.overlays = [ (import ../overlays) ];
  nix.trustedUsers = [ "root" "cmacrae" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  environment.shells = [ pkgs.zsh ];
  environment.systemPackages = [ pkgs.zsh pkgs.gcc ];
  programs.bash.enable = false;
  programs.zsh.enable = true;
  environment.darwinConfig = mkDefault "${homeDir}/src/github.com/cmacrae/config/machines/${config.networking.hostName}/configuration.nix";

  time.timeZone = "Europe/London";
  users.users.cmacrae.shell = pkgs.zsh;
  users.users.cmacrae.home = homeDir;

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
  services.skhd.skhdConfig = (builtins.readFile (pkgs.substituteAll {
    name = "homeUserChrome";
    src = ../conf.d/skhd.conf;
    vt220 = pkgs.writeShellScript "vt220OpenOrSelect" ''
      WIN=$(${pkgs.yabai}/bin/yabai -m query --windows | ${pkgs.jq}/bin/jq '[.[]|select(.title=="vt220")]|unique_by(.id)')
      if [[ $WIN != '[]' ]]; then
        ID=$(echo $WIN | ${pkgs.jq}/bin/jq '.[].id')
        FOCUSED=$(echo $WIN | ${pkgs.jq}/bin/jq '.[].focused')
        if [[ $FOCUSED == 1 ]]; then
          ${pkgs.yabai}/bin/yabai -m window --focus recent || \
          ${pkgs.yabai}/bin/yabai -m space --focus recent
        else
          ${pkgs.yabai}/bin/yabai -m window --focus $ID
        fi
      else
        open -n ~/.nix-profile/Applications/Alacritty.app \
        --args --live-config-reload \
        --config-file $HOME/.config/alacritty/live.yml \
        -t vt220 --dimensions 80 24 --position 10000 10000 \
        -e ${pkgs.tmux}/bin/tmux a -t vt
      fi
    '';
  }));

  environment.etc.gettytab.text = builtins.readFile (pkgs.substituteAll {
    name = "gettytab";
    src = ../conf.d/gettytab;
    autoLogin = pkgs.writeShellScript "gettyAutoLogin" ''
      ARGS=("$@")
      exec /usr/bin/login "''${ARGS[@]}" \
      ${pkgs.tmux}/bin/tmux \
      -f ${builtins.getEnv("HOME")}/.tmux.conf \
      new-session -A -s vt 'TERM=vt220 ${pkgs.zsh}/bin/zsh'
    '';
  });

  launchd.daemons.serialconsole = {
    command = "/usr/libexec/getty std.ttyUSB cu.usbserial";
    serviceConfig = {
      Label = "ae.cmacr.vt220";
      KeepAlive = true;
      EnvironmentVariables = {
        PATH = (lib.replaceStrings ["$HOME"] [( builtins.getEnv("HOME") )] config.environment.systemPath);
      };
    };
  };

  services.yabai = {
    enable = true;
    package = pkgs.yabai;
    enableScriptingAddition = true;
    config = {
      window_border                = "on";
      window_border_width          = 4;
      active_window_border_color   = "0xff00afaf";
      normal_window_border_color   = "0xff505050";
      focus_follows_mouse          = "autoraise";
      mouse_follows_focus          = "off";
      window_placement             = "second_child";
      window_opacity               = "off";
      window_opacity_duration      = "0.0";
      active_window_border_topmost = "off";
      window_topmost               = "on";
      window_shadow                = "float";
      active_window_opacity        = "1.0";
      normal_window_opacity        = "1.0";
      split_ratio                  = "0.50";
      auto_balance                 = "on";
      mouse_modifier               = "fn";
      mouse_action1                = "move";
      mouse_action2                = "resize";
      layout                       = "bsp";
      top_padding                  = 10;
      bottom_padding               = 10;
      left_padding                 = 10;
      right_padding                = 10;
      window_gap                   = 10;
      external_bar                 = "all:0:26";
    };

    extraConfig = ''
      # rules
      yabai -m rule --add app='System Preferences' manage=off
      yabai -m rule --add app='Live' manage=off
      yabai -m rule --add label=vt220 title=vt220 sticky=on border=off manage=off opacity=0.0001
    '';
  };

  services.spacebar.enable = true;
  services.spacebar.package = pkgs.spacebar;
  services.spacebar.config = {
    debug_output       = "on";
    position           = "bottom";
    clock_format       = "%R";
    space_icon_strip   = "   ";
    text_font          = ''"Menlo:Bold:12.0"'';
    icon_font          = ''"FontAwesome:Regular:12.0"'';
    background_color   = "0xff202020";
    foreground_color   = "0xffa8a8a8";
    space_icon_color   = "0xff14b1ab";
    dnd_icon_color     = "0xfffcf7bb";
    clock_icon_color   = "0xff99d8d0";
    power_icon_color   = "0xfff69e7b";
    battery_icon_color = "0xffffbcbc";
    power_icon_strip   = " ";
    space_icon         = "";
    clock_icon         = "";
    dnd_icon           = "";
  };

  launchd.user.agents.spacebar.serviceConfig.StandardErrorPath = "/tmp/spacebar.err.log";
  launchd.user.agents.spacebar.serviceConfig.StandardOutPath = "/tmp/spacebar.out.log";

  # Recreate /run/current-system symlink after boot
  services.activate-system.enable = true;

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

  home-manager.users.cmacrae = {
    home.packages = (import ./packages.nix { inherit pkgs; });

    home.sessionVariables = {
      PAGER = "less -R";
      EDITOR = "emacsclient";
    };

    programs.git.enable = true;
    programs.git.lfs.enable = true;
    programs.git.userName = mkDefault "cmacrae";
    programs.git.userEmail = mkDefault "hi@cmacr.ae";
    programs.git.signing.key = mkDefault "54A14F5D";
    programs.git.signing.signByDefault = mkDefault true;

    programs.firefox.enable = true;
    programs.firefox.package = pkgs.Firefox; # custom overlay
    programs.firefox.extensions =
      with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        browserpass
        vimium
      ];

    programs.firefox.profiles =
      let defaultSettings = {
            "app.update.auto" = false;
            "browser.startup.homepage" = "https://lobste.rs";
            "browser.search.region" = "GB";
            "browser.search.countryCode" = "GB";
            "browser.search.isUS" = false;
            "browser.ctrlTab.recentlyUsedOrder" = false;
            "browser.newtabpage.enabled" = false;
            "browser.bookmarks.showMobileBookmarks" = true;
            "browser.uidensity" = 1;
            "browser.urlbar.placeholderName" = "DuckDuckGo";
            "browser.urlbar.update1" = true;
            "distribution.searchplugins.defaultLocale" = "en-GB";
            "general.useragent.locale" = "en-GB";
            "identity.fxaccounts.account.device.name" = config.networking.hostName;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "privacy.trackingprotection.socialtracking.annotate.enabled" = true;
            "reader.color_scheme" = "sepia";
            "services.sync.declinedEngines" = "addons,passwords,prefs";
            "services.sync.engine.addons" = false;
            "services.sync.engineStatusChanged.addons" = true;
            "services.sync.engine.passwords" = false;
            "services.sync.engine.prefs" = false;
            "services.sync.engineStatusChanged.prefs" = true;
            "signon.rememberSignons" = false;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          };
      in {
        home = {
          id = 0;
          settings = defaultSettings;
          userChrome = (builtins.readFile (pkgs.substituteAll {
            name = "homeUserChrome";
            src = ../conf.d/userChrome.css;
            tabLineColour = "#2aa198";
          }));
        };

        work = {
          id = 1;
          settings = defaultSettings // {
            "browser.startup.homepage" = "about:blank";
            "browser.urlbar.placeholderName" = "Google";
          };
          userChrome = (builtins.readFile (pkgs.substituteAll {
            name = "workUserChrome";
            src = ../conf.d/userChrome.css;
            tabLineColour = "#cb4b16";
          }));
        };
      };

    programs.emacs.enable = true;
    programs.emacs.package = pkgs.emacsMacport;

    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;

    programs.browserpass.enable = true;
    programs.browserpass.browsers = [ "firefox" ];

    xdg.configFile."alacritty/light.yml".text =
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

    programs.alacritty = {
      enable = true;
      settings = {
        window.padding.x = 15;
        window.padding.y = 15;
        window.decorations = "buttonless";
        window.dynamic_title = false;
        scrolling.history = 100000;
        live_config_reload = true;
        selection.save_to_clipboard = true;
        mouse.hide_when_typing = true;

        font = {
          normal.family = "Menlo";
          size = 12;
        };

        colors = {
          primary.background = "0x282c34";
          primary.foreground = "0xabb2bf";

          normal = {
            black = "0x282c34";
            red = "0xe06c75";
            green = "0x98c379";
            yellow = "0xd19a66";
            blue = "0x61afef";
            magenta = "0xc678dd";
            cyan = "0x56b6c2";
            white = "0xabb2bf";
          };

          bright = {
            black = "0x5c6370";
            red = "0xe06c75";
            green = "0x98c379";
            yellow = "0xd19a66";
            blue = "0x61afef";
            magenta = "0xc678dd";
            cyan = "0x56b6c2";
            white = "0xffffff";
          };
        };

        key_bindings = [
          { key = "V"; mods = "Command"; action = "Paste"; }
          { key = "C"; mods = "Command"; action = "Copy";  }
          { key = "Q"; mods = "Command"; action = "Quit";  }
          { key = "Q"; mods = "Control"; chars = "\\x11"; }
          { key = "F"; mods = "Alt"; chars = "\\x1bf"; }
          { key = "B"; mods = "Alt"; chars = "\\x1bb"; }
          { key = "D"; mods = "Alt"; chars = "\\x1bd"; }
          { key = "Slash"; mods = "Control"; chars = "\\x1f"; }
          { key = "Period"; mods = "Alt"; chars = "\\e-\\e."; }
          { key = "N"; mods = "Command"; command = {
              program = "open";
              args = ["-nb" "io.alacritty"];
            };
          }
        ];
      };
    } ;

    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      defaultKeymap = "emacs";
      sessionVariables = { RPROMPT = ""; };

      shellAliases = {
        k = "kubectl";
        kp = "kube-prompt";
        kc = "kubectx";
        kn = "kubens";
        t = "cd $(mktemp -d)";
      };

      oh-my-zsh.enable = true;

      plugins = [
        {
          name = "autopair";
          file = "autopair.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "hlissner";
            repo = "zsh-autopair";
            rev = "4039bf142ac6d264decc1eb7937a11b292e65e24";
            sha256 = "02pf87aiyglwwg7asm8mnbf9b2bcm82pyi1cj50yj74z4kwil6d1";
          };
        }
        {
          name = "fast-syntax-highlighting";
          file = "fast-syntax-highlighting.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "zdharma";
            repo = "fast-syntax-highlighting";
            rev = "v1.28";
            sha256 = "106s7k9n7ssmgybh0kvdb8359f3rz60gfvxjxnxb4fg5gf1fs088";
          };
        }
        {
          name = "pi-theme";
          file = "pi.zsh-theme";
          src = pkgs.fetchFromGitHub {
            owner = "tobyjamesthomas";
            repo = "pi";
            rev = "96778f903b79212ac87f706cfc345dd07ea8dc85";
            sha256 = "0zjj1pihql5cydj1fiyjlm3163s9zdc63rzypkzmidv88c2kjr1z";
          };
        }
        {
          name = "z";
          file = "zsh-z.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "agkozak";
            repo = "zsh-z";
            rev = "41439755cf06f35e8bee8dffe04f728384905077";
            sha256 = "1dzxbcif9q5m5zx3gvrhrfmkxspzf7b81k837gdb93c4aasgh6x6";
          };
        }
      ];
    };

    programs.tmux =
      let
        kubeTmux = pkgs.fetchFromGitHub {
          owner = "jonmosco";
          repo = "kube-tmux";
          rev = "7f196eeda5f42b6061673825a66e845f78d2449c";
          sha256 = "1dvyb03q2g250m0bc8d2621xfnbl18ifvgmvf95nybbwyj2g09cm";
        };

        tmuxYank = pkgs.fetchFromGitHub {
          owner = "tmux-plugins";
          repo = "tmux-yank";
          rev = "ce21dafd9a016ef3ed4ba3988112bcf33497fc83";
          sha256 = "04ldklkmc75azs6lzxfivl7qs34041d63fan6yindj936r4kqcsp";
        };


      in {
        enable = true;
        shortcut = "q";
        keyMode = "vi";
        clock24 = true;
        terminal = "screen-256color";
        customPaneNavigationAndResize = true;
        secureSocket = false;
        extraConfig = ''
          unbind [
          unbind ]

          bind ] next-window
          bind [ previous-window

          bind Escape copy-mode
          bind P paste-buffer
          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi y send-keys -X copy-selection
          bind-key -T copy-mode-vi r send-keys -X rectangle-toggle
          set -g mouse on

          bind-key -r C-k resize-pane -U
          bind-key -r C-j resize-pane -D
          bind-key -r C-h resize-pane -L
          bind-key -r C-l resize-pane -R

          bind-key -r C-M-k resize-pane -U 5
          bind-key -r C-M-j resize-pane -D 5
          bind-key -r C-M-h resize-pane -L 5
          bind-key -r C-M-l resize-pane -R 5

          set -g display-panes-colour white
          set -g display-panes-active-colour red
          set -g display-panes-time 1000
          set -g status-justify left
          set -g set-titles on
          set -g set-titles-string 'tmux: #T'
          set -g repeat-time 100
          set -g renumber-windows on
          set -g renumber-windows on

          setw -g monitor-activity on
          setw -g automatic-rename on
          setw -g clock-mode-colour red
          setw -g clock-mode-style 24
          setw -g alternate-screen on

          set -g status-left-length 100
          set -g status-left "#(${pkgs.bash}/bin/bash ${kubeTmux}/kube.tmux 250 green colour3)  "
          set -g status-right-length 100
          set -g status-right "#[fg=red,bg=default] %b %d #[fg=blue,bg=default] %R "
          set -g status-bg default
          setw -g window-status-format "#[fg=blue,bg=black] #I #[fg=blue,bg=black] #W "
          setw -g window-status-current-format "#[fg=blue,bg=default] #I #[fg=red,bg=default] #W "

          run-shell ${tmuxYank}/yank.tmux
        '';
      };

    # Global Emacs keybindings
    home.file."Library/KeyBindings/DefaultKeyBinding.dict".text = ''
      {
          /* Ctrl shortcuts */
          "^l"        = "centerSelectionInVisibleArea:";  /* C-l          Recenter */
          "^/"        = "undo:";                          /* C-/          Undo */
          "^_"        = "undo:";                          /* C-_          Undo */
          "^ "        = "setMark:";                       /* C-Spc        Set mark */
          "^\@"       = "setMark:";                       /* C-@          Set mark */
          "^w"        = "deleteToMark:";                  /* C-w          Delete to mark */

          /* Meta shortcuts */
          "~f"        = "moveWordForward:";               /* M-f          Move forward word */
          "~b"        = "moveWordBackward:";              /* M-b          Move backward word */
          "~<"        = "moveToBeginningOfDocument:";     /* M-<          Move to beginning of document */
          "~>"        = "moveToEndOfDocument:";           /* M->          Move to end of document */
          "~v"        = "pageUp:";                        /* M-v          Page Up */
          "~/"        = "complete:";                      /* M-/          Complete */
          "~c"        = ( "capitalizeWord:",              /* M-c          Capitalize */
                          "moveForward:",
                          "moveForward:");
          "~u"        = ( "uppercaseWord:",               /* M-u          Uppercase */
                          "moveForward:",
                          "moveForward:");
          "~l"        = ( "lowercaseWord:",               /* M-l          Lowercase */
                          "moveForward:",
                          "moveForward:");
          "~d"        = "deleteWordForward:";             /* M-d          Delete word forward */
          "^~h"       = "deleteWordBackward:";            /* M-C-h        Delete word backward */
          "~\U007F"   = "deleteWordBackward:";            /* M-Bksp       Delete word backward */
          "~t"        = "transposeWords:";                /* M-t          Transpose words */
          "~\@"       = ( "setMark:",                     /* M-@          Mark word */
                          "moveWordForward:",
                          "swapWithMark");
          "~h"        = ( "setMark:",                     /* M-h          Mark paragraph */
                          "moveToEndOfParagraph:",
                          "swapWithMark");

          /* C-x shortcuts */
          "^x" = {
              "u"     = "undo:";                          /* C-x u        Undo */
              "k"     = "performClose:";                  /* C-x k        Close */
              "^f"    = "openDocument:";                  /* C-x C-f      Open (find file) */
              "^x"    = "swapWithMark:";                  /* C-x C-x      Swap with mark */
              "^m"    = "selectToMark:";                  /* C-x C-m      Select to mark*/
              "^s"    = "saveDocument:";                  /* C-x C-s      Save */
              "^w"    = "saveDocumentAs:";                /* C-x C-w      Save as */
          };
      }
    '';
  };
}
