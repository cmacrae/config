{ config, lib, pkgs, ... }:

let
  cfg = config.local.home;

in with pkgs.stdenv; with lib; {
  options.local.home = with types; {
    git.userName = mkOption {
      type = str;
      default = "cmacrae";
      description = "Username for Git";
    };

    git.userEmail = mkOption {
      type = str;
      default = "hi@cmacr.ae";
      description = "User e-mail for Git";
    };
  };

  config = {
    time.timeZone = "Europe/London";
    nix.trustedUsers = [ "root" "cmacrae" ];
    nixpkgs.config.allowUnfree = true;
    nix.extraOptions = ''
      plugin-files = ${pkgs.nix-plugins.override {
               nix = config.nix.package; }}/lib/nix/plugins/libnix-extra-builtins.so
    '';

    nixpkgs.config.packageOverrides = pkgs: {
      nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
      };
    };

    environment.systemPackages = [ pkgs.zsh ];
    users.users.cmacrae.shell = pkgs.zsh;
    users.users.cmacrae.home = builtins.getEnv("HOME");

    home-manager.users.cmacrae = {
      home.packages = (import ./packages.nix { inherit pkgs; });

      home.sessionVariables = {
        PAGER = "less -R";
        EDITOR = "emacsclient";
      };

      programs.git.enable = true;
      programs.git.userName = cfg.git.userName;
      programs.git.userEmail = cfg.git.userEmail;

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
              "browser.urlbar.update1" = true;
              "distribution.searchplugins.defaultLocale" = "en-GB";
              "general.useragent.locale" = "en-GB";
              "identity.fxaccounts.account.device.name" = config.networking.hostName;
              "privacy.trackingprotection.enabled" = true;
              "privacy.trackingprotection.socialtracking.enabled" = true;
              "privacy.trackingprotection.socialtracking.annotate.enabled" = true;
              "services.sync.declinedEngines" = "addons,passwords,prefs";
              "services.sync.engine.addons" = false;
              "services.sync.engineStatusChanged.addons" = true;
              "services.sync.engine.passwords" = false;
              "services.sync.engine.prefs" = false;
              "services.sync.engineStatusChanged.prefs" = true;
              "signon.rememberSignons" = false;
            };
        in {
          home = {
            id = 0;
            settings = defaultSettings // {
              "browser.urlbar.placeholderName" = "DuckDuckGo";
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };
            userChrome = builtins.readFile ../conf.d/userChrome.css;
          };

          work = {
            id = 1;
            settings = defaultSettings // {
              "browser.startup.homepage" = "about:blank";
            };
          };
      };

      programs.emacs.enable = true;
      programs.emacs.package = pkgs.Emacs; # custom overlay

      programs.fzf.enable = true;
      programs.fzf.enableZshIntegration = true;

      programs.browserpass.enable = true;
      programs.browserpass.browsers = [ "firefox" ];

      programs.alacritty = {
        enable = true;
        settings = {
          window.padding.x = 15;
          window.padding.y = 15;
          window.decorations = "buttonless";
          scrolling.history = 100000;
          live_config_reload = true;
          selection.save_to_clipboard = true;
          dynamic_title = false;
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
  };
}
