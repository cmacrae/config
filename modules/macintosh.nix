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

  fonts.enableFontDir = true;
  fonts.fonts = with pkgs; [ emacs-all-the-icons-fonts fira-code font-awesome roboto roboto-mono ];

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  services.skhd.enable = true;
  services.skhd.skhdConfig = builtins.readFile ../conf.d/skhd.conf;

  services.yabai = {
    enable = true;
    package = pkgs.yabai;
    enableScriptingAddition = true;
    config = {
      window_border              = "on";
      window_border_width        = 5;
      active_window_border_color = "0xff81a1c1";
      normal_window_border_color = "0xff3b4252";
      focus_follows_mouse        = "autoraise";
      mouse_follows_focus        = "off";
      window_placement           = "second_child";
      window_opacity             = "off";
      window_topmost             = "on";
      window_shadow              = "float";
      active_window_opacity      = "1.0";
      normal_window_opacity      = "1.0";
      split_ratio                = "0.50";
      auto_balance               = "on";
      mouse_modifier             = "fn";
      mouse_action1              = "move";
      mouse_action2              = "resize";
      layout                     = "bsp";
      top_padding                = 10;
      bottom_padding             = 10;
      left_padding               = 10;
      right_padding              = 10;
      window_gap                 = 10;
      external_bar               = "all:26:0";
    };

    extraConfig = mkDefault ''
      # rules
      yabai -m rule --add app='System Preferences' manage=off
      yabai -m rule --add app='Live' manage=off
    '';
  };

  services.spacebar.enable = true;
  services.spacebar.package = pkgs.spacebar;
  services.spacebar.config = {
    debug_output       = "on";
    position           = "top";
    clock_format       = "%R";
    space_icon_strip   = "   ";
    text_font          = ''"Roboto Mono:Regular:12.0"'';
    icon_font          = ''"FontAwesome:Regular:12.0"'';
    background_color   = "0xff2e3440";
    foreground_color   = "0xffd8dee9";
    space_icon_color   = "0xff81a1c1";
    dnd_icon_color     = "0xff81a1c1";
    clock_icon_color   = "0xff81a1c1";
    power_icon_color   = "0xff81a1c1";
    battery_icon_color = "0xff81a1c1";
    power_icon_strip   = " ";
    space_icon         = "";
    clock_icon         = "";
    dnd_icon           = "";
  };

  launchd.user.agents.spacebar.serviceConfig.StandardErrorPath = "/tmp/spacebar.err.log";
  launchd.user.agents.spacebar.serviceConfig.StandardOutPath = "/tmp/spacebar.out.log";

  # Recreate /run/current-system symlink after boot
  services.activate-system.enable = true;

  home-manager.users.cmacrae = {
    home.packages = (import ./packages.nix { inherit pkgs; });

    home.sessionVariables = {
      PAGER = "less -R";
      EDITOR = "emacsclient";
    };

    programs.git.enable = true;
    programs.git.lfs.enable = true;
    programs.git.userName = mkDefault "cmacrae";
    programs.git.userEmail = mkDefault ''${builtins.replaceStrings [" <at> " " <dot> "] ["@" "."] "hi <at> cmacr <dot> ae"}'';
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
            tabLineColour = "#5e81ac";
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
            tabLineColour = "#d08770";
          }));
        };
      };

    programs.emacs.enable = true;
    programs.emacs.package = pkgs.emacsMacport.overrideAttrs (o: {
      patches = o.patches ++ [ ../patches/borderless-emacs.patch ];
    });

    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;

    programs.browserpass.enable = true;
    programs.browserpass.browsers = [ "firefox" ];

    programs.alacritty = {
      enable = true;
      settings = {
        window.padding.x = 24;
        window.padding.y = 24;
        window.decorations = "buttonless";
        window.dynamic_title = false;
        scrolling.history = 100000;
        live_config_reload = true;
        selection.save_to_clipboard = true;
        mouse.hide_when_typing = true;

        font = {
          normal.family = "Roboto Mono";
          size = 12;
        };

        colors = {
          primary.background = "#2e3440";
          primary.foreground = "#d8dee9";

          normal = {
            black   = "#3b4252";
            red     = "#bf616a";
            green   = "#a3be8c";
            yellow  = "#ebcb8b";
            blue    = "#81a1c1";
            magenta = "#b48ead";
            cyan    = "#88c0d0";
            white   = "#e5e9f0";
          };

          bright = {
            black   = "#4c566a";
            red     = "#bf616a";
            green   = "#a3be8c";
            yellow  = "#ebcb8b";
            blue    = "#81a1c1";
            magenta = "#b48ead";
            cyan    = "#8fbcbb";
            white   = "#eceff4";
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
