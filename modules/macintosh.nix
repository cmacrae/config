{ config, pkgs, ... }:

let
  mailAddr = name: domain: "${name}@${domain}";
  primaryEmail = mailAddr "hi" "cmacr.ae";
  secondaryEmail = mailAddr "account" "cmacr.ae";
  fullName = "Calum MacRae";

in
{
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = 4;
  nix.maxJobs = "auto";
  nix.buildCores = 0;
  services.nix-daemon.enable = true;

  nixpkgs.overlays = [
    (import ../overlays)
  ];

  nix.trustedUsers = [ "root" "cmacrae" ];

  nix.binaryCaches = [
    # Personal cache
    "https://cachix.org/api/v1/cache/cmacrae"
    # Nightly Emacs build cache for github.com/cmacrae/emacs
    "https://cachix.org/api/v1/cache/emacs"
    # Binary cache for the srokell/deploy-rs binary
    "https://cachix.org/api/v1/cache/deploy-rs"
    "https://cachix.org/api/v1/cache/nix-community"
  ];

  nix.binaryCachePublicKeys = [
    "cmacrae.cachix.org-1:5Mp1lhT/6baI3eAqnEvruhLrrXE9CKe27SbnXqjwXfg="
    "emacs.cachix.org-1:b1SMJNLY/mZF6GxQE+eDBeps7WnkT0Po55TAyzwOxTY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "deploy-rs.cachix.org-1:M+ZN++7fdqZFeIsvJyqeQrgnAbgsPNuv8z93uAJO43w="
  ];

  nix.trustedBinaryCaches = config.nix.binaryCaches;

  nixpkgs.config.allowUnfree = true;

  environment.shells = [ pkgs.zsh ];
  environment.systemPackages = [ pkgs.zsh pkgs.gcc ];
  programs.bash.enable = false;
  programs.zsh.enable = true;

  time.timeZone = "Europe/London";
  users.users.cmacrae.shell = pkgs.zsh;
  users.users.cmacrae.home = "/Users/cmacrae";
  users.nix.configureBuildUsers = true;

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

  ############
  # Homebrew #
  ############
  homebrew.enable = true;
  homebrew.autoUpdate = true;
  homebrew.cleanup = "zap";
  homebrew.global.brewfile = true;
  homebrew.global.noLock = true;
  homebrew.extraConfig = ''
    cask "firefox", args: { language: "en-GB" }
  '';

  homebrew.taps = [
    "homebrew/core"
    "homebrew/cask"
  ];

  homebrew.casks = [
    "firefox"
    "discord"
  ];

  services.skhd.enable = true;
  services.skhd.skhdConfig = builtins.readFile ../conf.d/skhd.conf;

  services.yabai = {
    enable = true;
    package = pkgs.yabai;
    enableScriptingAddition = true;
    config = {
      window_border = "on";
      window_border_width = 5;
      active_window_border_color = "0xffd9adad";
      normal_window_border_color = "0xff3b4252";
      focus_follows_mouse = "autoraise";
      mouse_follows_focus = "off";
      mouse_drop_action = "stack";
      window_placement = "second_child";
      window_opacity = "off";
      window_topmost = "on";
      window_shadow = "float";
      active_window_opacity = "1.0";
      normal_window_opacity = "1.0";
      split_ratio = "0.50";
      auto_balance = "on";
      mouse_modifier = "fn";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      layout = "bsp";
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
      window_gap = 10;
      external_bar = "main:26:0";
    };

    extraConfig = pkgs.lib.mkDefault ''
      # rules
      yabai -m rule --add app='System Preferences' manage=off
      yabai -m rule --add app='Live' manage=off
      yabai -m rule --add app='Xcode' manage=off
      yabai -m rule --add app='Emacs' title='.*Minibuf.*' manage=off border=off
    '';
  };

  launchd.user.agents.yabai.serviceConfig.StandardErrorPath = "/tmp/yabai.log";
  launchd.user.agents.yabai.serviceConfig.StandardOutPath = "/tmp/yabai.log";

  services.spacebar.enable = true;
  services.spacebar.package = pkgs.spacebar;
  services.spacebar.config = {
    debug_output = "on";
    display = "main";
    position = "top";
    clock_format = "%R";
    text_font = ''"Roboto Mono:Regular:12.0"'';
    icon_font = ''"Font Awesome 5 Free:Solid:12.0"'';
    background_color = "0xff222222";
    foreground_color = "0xffd8dee9";
    space_icon_color = "0xffffab91";
    dnd_icon_color = "0xffd8dee9";
    clock_icon_color = "0xffd8dee9";
    power_icon_color = "0xffd8dee9";
    battery_icon_color = "0xffd8dee9";
    power_icon_strip = " ";
    space_icon = "•";
    space_icon_strip = "1 2 3 4 5 6 7 8 9 10";
    spaces_for_all_displays = "on";
    display_separator = "on";
    display_separator_icon = "";
    space_icon_color_secondary = "0xff78c4d4";
    space_icon_color_tertiary = "0xfffff9b0";
    clock_icon = "";
    dnd_icon = "";
    right_shell = "on";
    right_shell_icon = "";
    right_shell_icon_color = "0xffd8dee9";
  };

  launchd.user.agents.spacebar.serviceConfig.EnvironmentVariables.PATH = pkgs.lib.mkForce
    (builtins.replaceStrings [ "$HOME" ] [ config.users.users.cmacrae.home ] config.environment.systemPath);
  launchd.user.agents.spacebar.serviceConfig.StandardErrorPath = "/tmp/spacebar.err.log";
  launchd.user.agents.spacebar.serviceConfig.StandardOutPath = "/tmp/spacebar.out.log";

  # Recreate /run/current-system symlink after boot
  services.activate-system.enable = true;

  services.mbsync.enable = true;
  services.mbsync.postExec = ''
    if pgrep -f 'mu server'; then
        ${config.home-manager.users.cmacrae.programs.emacs.package}/bin/emacsclient \
          -e '(mu4e-update-index)'
    else
        ${pkgs.mu}/bin/mu index --nocolor
    fi
  '';
  launchd.user.agents.mbsync.serviceConfig.StandardErrorPath = "/tmp/mbsync.log";
  launchd.user.agents.mbsync.serviceConfig.StandardOutPath = "/tmp/mbsync.log";

  home-manager.users.cmacrae = {
    home.stateVersion = "21.05";
    home.packages = with pkgs; [
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      bc
      bind
      clang
      ffmpeg-full
      gnumake
      gnupg
      gnused
      htop
      hugo
      jq
      mpv
      nix-prefetch-git
      nmap
      open-policy-agent
      pass
      python3
      ranger
      ripgrep
      rnix-lsp
      rsync
      terraform
      terraform-ls
      unzip
      up
      vim
      wget
      wireguard-tools
      youtube-dl

      # Go
      go
      gocode
      godef
      gotools
      golangci-lint
      golint
      go2nix
      errcheck
      gotags
      gopls

      # Docker
      docker

      # k8s
      argocd
      kind
      kubectl
      kubectx
      kubeval
      kube-prompt
      kubernetes-helm
      kustomize
    ];

    home.sessionVariables = {
      PAGER = "less -R";
      EDITOR = "emacsclient";
    };

    programs.git = {
      enable = true;
      userName = fullName;
      userEmail = primaryEmail;
      signing.key = "54A14F5D";
      signing.signByDefault = true;
      extraConfig.github.user = "cmacrae";
    };

    #########
    # Email #
    #########
    programs.mu.enable = true;
    programs.mbsync.enable = true;
    programs.msmtp.enable = true;
    accounts.email.maildirBasePath = ".mail";
    accounts.email.accounts.fastmail = {
      mu.enable = true;
      msmtp.enable = true;
      primary = pkgs.lib.mkDefault true;
      address = primaryEmail;
      aliases = [ secondaryEmail ];
      userName = primaryEmail;
      realName = fullName;

      mbsync = {
        enable = true;
        create = "both";
        expunge = "both";
        remove = "both";
      };

      imap.host = "imap.fastmail.com";
      smtp.host = "smtp.fastmail.com";
      smtp.port = 465;

      passwordCommand = "${pkgs.writeShellScript "fastmail-mbsyncPass" ''
        ${pkgs.pass}/bin/pass Tech/fastmail.com | ${pkgs.gawk}/bin/awk -F: '/mbsync/{gsub(/ /,""); print$NF}'
      ''}";
    };

    ###########
    # Firefox #
    ###########
    programs.firefox.enable = true;
    # Handled by the Homebrew module
    # This populates a dummy package to satsify the requirement
    programs.firefox.package = pkgs.runCommand "firefox-0.0.0" {} "mkdir $out";
    programs.firefox.extensions =
      with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        browserpass
        vimium
      ];

    programs.firefox.profiles =
      let
        defaultSettings = {
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
      in
        {
          home = {
            id = 0;
            settings = defaultSettings;
            userChrome = (
              builtins.readFile (
                pkgs.substituteAll {
                  name = "homeUserChrome";
                  src = ../conf.d/userChrome.css;
                  tabLineColour = "#5e81ac";
                }
              )
            );
          };

          work = {
            id = 1;
            settings = defaultSettings // {
              "browser.startup.homepage" = "about:blank";
              "browser.urlbar.placeholderName" = "Google";
            };
            userChrome = (
              builtins.readFile (
                pkgs.substituteAll {
                  name = "workUserChrome";
                  src = ../conf.d/userChrome.css;
                  tabLineColour = "#d08770";
                }
              )
            );
          };
        };

    #########
    # Emacs #
    #########
    programs.emacs.enable = true;
    home.file.".emacs.d/init.el".text = ''
      ;;; init.el --- Where all the magic begins
      ;;
      ;;; Commentary:
      ;; This file loads Org-mode and then loads the rest of the Emacs initialization from Emacs Lisp
      ;; embedded in the literate Org-mode file: emacs.org
      ;;
      ;;; Code:

      (setq emacs-dir (file-name-directory (or (buffer-file-name) load-file-name)))

      ;; load up Org-mode and Org-babel
      (require 'org-install)
      (require 'ob-tangle)

      ;; load up all literate org-mode files in this directory
      (mapc #'org-babel-load-file (directory-files emacs-dir t "\\.org$"))

      ;;; init.el ends here
    '';
    home.file.".emacs.d/emacs.org".source = ../conf.d/emacs.org;

    programs.emacs.package =
      let
        # TODO: derive 'name' from assignment
        elPackage = name: src:
          pkgs.runCommand "${name}.el" {} ''
            mkdir -p  $out/share/emacs/site-lisp
            cp -r ${src}/* $out/share/emacs/site-lisp/
          '';
      in
        (
          pkgs.emacsWithPackagesFromUsePackage {
            alwaysEnsure = true;
            alwaysTangle = true;

            # Custom overlay derived from 'emacs' flake input
            package = pkgs.emacs;
            config = ../conf.d/emacs.org;

            override = epkgs: epkgs // {
              nano-emacs = elPackage "nano-emacs" (
                pkgs.fetchFromGitHub {
                  # NOTE: Using my own fork whilst I work on features
                  #       'emhancements' branch
                  # owner = "rougier";
                  owner = "cmacrae";
                  repo = "nano-emacs";
                  rev = "01a51d2a8e18ef5a4e8540a01d110ae4e8d693e9";
                  sha256 = "1cc8bbxjmyfgwiq01y0zin5l31qclyr9vjp0f8d9xr4wv5d1cap4";
                }
              );

              mu4e-dashboard = elPackage "mu4e-dashboard" (
                pkgs.fetchFromGitHub {
                  owner = "rougier";
                  repo = "mu4e-dashboard";
                  rev = "143e87a770689d9402addaeb43ff48efcc5ce40c";
                  sha256 = "13ximpz77fbgwl4a91nh8wy9qm83q7s11hbnlx3bi04pcgz4cchj";
                }
              );

              mu4e-thread-folding = elPackage "mu4e-thread-folding" (
                pkgs.fetchFromGitHub {
                  owner = "rougier";
                  repo = "mu4e-thread-folding";
                  rev = "db0fadeb1f7262cf43cfe98c3b1d08682f9c5f25";
                  sha256 = "1rgvnqxkiparslk7n76h5iad0xq4pdjici21c94l7rpxsp9vsrvh";
                }
              );
            };

            extraEmacsPackages = epkgs: with epkgs; [
              nano-emacs
              mu4e-dashboard
              mu4e-thread-folding
            ];
          }
        );

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
        window.dynamic_title = true;
        scrolling.history = 100000;
        live_config_reload = true;
        selection.save_to_clipboard = true;
        mouse.hide_when_typing = true;
        use_thin_strokes = true;

        font = {
          size = 12;
          normal.family = "Roboto Mono";
        };

        colors = {
          cursor.cursor = "#81a1c1";
          primary.background = "#2e3440";
          primary.foreground = "#d8dee9";

          normal = {
            black = "#3b4252";
            red = "#bf616a";
            green = "#a3be8c";
            yellow = "#ebcb8b";
            blue = "#81a1c1";
            magenta = "#b48ead";
            cyan = "#88c0d0";
            white = "#e5e9f0";
          };

          bright = {
            black = "#4c566a";
            red = "#bf616a";
            green = "#a3be8c";
            yellow = "#ebcb8b";
            blue = "#81a1c1";
            magenta = "#b48ead";
            cyan = "#8fbcbb";
            white = "#eceff4";
          };
        };

        key_bindings = [
          { key = "V"; mods = "Command"; action = "Paste"; }
          { key = "C"; mods = "Command"; action = "Copy"; }
          { key = "Q"; mods = "Command"; action = "Quit"; }
          { key = "Q"; mods = "Control"; chars = "\\x11"; }
          { key = "F"; mods = "Alt"; chars = "\\x1bf"; }
          { key = "B"; mods = "Alt"; chars = "\\x1bb"; }
          { key = "D"; mods = "Alt"; chars = "\\x1bd"; }
          { key = "Key3"; mods = "Alt"; chars = "#"; }
          { key = "Slash"; mods = "Control"; chars = "\\x1f"; }
          { key = "Period"; mods = "Alt"; chars = "\\e-\\e."; }
          {
            key = "N";
            mods = "Command";
            command = {
              program = "open";
              args = [ "-nb" "io.alacritty" ];
            };
          }
        ];
      };
    };

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

      initExtra = ''
          PROMPT=' %{$fg_bold[blue]%}$(get_pwd)%{$reset_color%} ''${prompt_suffix}'
          local prompt_suffix="%(?:%{$fg_bold[green]%}❯ :%{$fg_bold[red]%}❯%{$reset_color%} "

          function get_pwd(){
              git_root=$PWD
              while [[ $git_root != / && ! -e $git_root/.git ]]; do
                  git_root=$git_root:h
              done
              if [[ $git_root = / ]]; then
                  unset git_root
                  prompt_short_dir=%~
              else
                  parent=''${git_root%\/*}
                  prompt_short_dir=''${PWD#$parent/}
              fi
              echo $prompt_short_dir
                                      }

          vterm_printf(){
              if [ -n "$TMUX" ]; then
                  # Tell tmux to pass the escape sequences through
                  # (Source: http://permalink.gmane.org/gmane.comp.terminal-emulators.tmux.user/1324)
                  printf "\ePtmux;\e\e]%s\007\e\\" "$1"
              elif [ "''${TERM%%-*}" = "screen" ]; then
                  # GNU screen (screen, screen-256color, screen-256color-bce)
                  printf "\eP\e]%s\007\e\\" "$1"
              else
                  printf "\e]%s\e\\" "$1"
              fi
        }
      '';
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


      in
        {
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
