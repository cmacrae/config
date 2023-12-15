{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv) isDarwin;
  mailAddr = name: domain: "${name}@${domain}";
  primaryEmail = mailAddr "hi" "cmacr.ae";
  secondaryEmail = mailAddr "account" "cmacr.ae";
  fullName = "Calum MacRae";

in
{
  users.users.cmacrae.shell = pkgs.zsh;
  users.users.cmacrae.home =
    if isDarwin then
      "/Users/cmacrae"
    else
      "/home/cmacrae";

  # for nix-direnv
  nix.settings.keep-outputs = true;
  nix.settings.keep-derivations = true;
  environment.pathsToLink = [ "/share/nix-direnv" ];

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    eb-garamond
    emacs-all-the-icons-fonts
    etBook
    fira-code
    font-awesome
    nerdfonts
    roboto
    roboto-mono
  ];

  home-manager.users.cmacrae = {

    imports = [ ../modules/gpg-agent.nix ];

    nixpkgs.config.allowUnfree = true;

    home.stateVersion = "23.05";
    home.packages = with pkgs; [
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      bc
      clang
      ffmpeg
      gnumake
      gnupg
      gnused
      htop
      hugo
      ipcalc
      jq
      mpv
      nix-prefetch-git
      nmap
      nodejs # for copilot
      # FIXME: Broken on macOS amd64 right now
      # open-policy-agent
      pass
      podman
      python3
      pwgen
      ranger
      ripgrep
      rnix-lsp
      rsync
      sops
      terraform
      terraform-ls
      unzip
      up
      vim
      wget
      youtube-dl

      # Go
      go
      gocode
      godef
      gotools
      # FIXME: Broken on macOS amd64 right now
      # golangci-lint
      golint
      go2nix
      errcheck
      gopls
      go-tools
    ];

    home.sessionVariables = {
      PAGER = "less -R";
      EDITOR = "emacsclient";
    };

    programs.git = {
      enable = true;
      userName = fullName;
      userEmail = primaryEmail;
      signing.key = "CED5DD2923023B37!";
      signing.signByDefault = true;
      extraConfig.github.user = "cmacrae";
    };

    programs.gpg = {
      enable = true;
      mutableKeys = false;
      mutableTrust = false;
      publicKeys = [{
        trust = 5;
        source = builtins.fetchurl {
          url = "https://github.com/cmacrae.gpg";
          sha256 = "sha256-Y+r7YOdUu/DSwnexV/b890g3N94mmOjx6vfsdqdfuBA=";
        };
      }];
      settings = {
        personal-cipher-preferences = "AES256 AES192 AES";
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
        cert-digest-algo = "SHA512";
        s2k-digest-algo = "SHA512";
        s2k-cipher-algo = "AES256";
        charset = "utf-8";
        fixed-list-mode = "";
        no-comments = "";
        no-emit-version = "";
        no-greeting = "";
        keyid-format = "0xlong";
        list-options = "show-uid-validity";
        verify-options = "show-uid-validity";
        with-fingerprint = "";
        require-cross-certification = "";
        no-symkey-cache = "";
        use-agent = "";
        throw-keyids = "";
      };
    };

    services.my-gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      enableSshSupport = true;
      sshKeys = [ "4F39E235299187ED7B9A8049A85F3EE3488CF521" ];
      extraConfig = ''
        allow-emacs-pinentry
        allow-loopback-pinentry
      '';
    };

    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
    programs.direnv.enableZshIntegration = true;

    ###########
    # Firefox #
    ###########
    programs.firefox.enable = true;
    programs.firefox.package =
      if isDarwin then
      # Handled by the Homebrew module
      # This populates a dummy package to satsify the requirement
        pkgs.runCommand "firefox-0.0.0" { } "mkdir $out"
      else
        pkgs.firefox;

    programs.firefox.profiles =
      let
        userChrome = builtins.readFile ../conf.d/userChrome.css;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          browserpass
          betterttv
          metamask
          reddit-enhancement-suite
          ublock-origin
          vimium
        ];

        settings = {
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
          "reader.color_scheme" = "auto";
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
          inherit userChrome settings extensions;
          id = 0;
        };

        work = pkgs.lib.mkIf (config.networking.hostName == "workbook") {
          id = 1;
          inherit userChrome extensions;
          settings = settings // {
            "browser.startup.homepage" = "about:blank";
            "browser.urlbar.placeholderName" = "Google";
          };
        };
      };

    programs.emacs.enable = true;
    programs.emacs.package =
      let
        # TODO: derive 'name' from assignment
        elPackage = name: src:
          pkgs.runCommand "${name}.el" { } ''
            mkdir -p  $out/share/emacs/site-lisp
            cp -r ${src}/* $out/share/emacs/site-lisp/
          '';
      in
      (
        pkgs.emacsWithPackagesFromUsePackage {
          alwaysEnsure = true;
          alwaysTangle = true;
          package =
            if isDarwin then
              pkgs.emacs-pgtk.overrideAttrs
                (o: {
                  patches = o.patches ++ [
                    ../pkgs/emacs-config/fix-window-role.patch
                    ../pkgs/emacs-config/round-undecorated-frame.patch
                    ../pkgs/emacs-config/system-appearance.patch
                  ];
                })
            else pkgs.emacs-pgtk;

          defaultInitFile = pkgs.callPackage ../pkgs/emacs-config { };
          config = ../pkgs/emacs-config/readme.org;

          override = epkgs: epkgs // {
            copilot = elPackage "copilot" (pkgs.fetchFromGitHub {
              owner = "zerolfx";
              repo = "copilot.el";
              rev = "85999e64845a746c78c6e578d1517ccf7b1a6765";
              sha256 = "1j2ng15x4c8i5zgqx73899jlq6vxal3r1fzx1wjv3fsrc8ryhrzk";
            });

            nano-dialog = elPackage "nano-dialog" (pkgs.fetchFromGitHub {
              owner = "rougier";
              repo = "nano-dialog";
              rev = "4127d8feceeed4ceabbe16190dae3f4609f2fdb4";
              sha256 = "sha256-R5+6Zwe8CMFEVg1RUSJT64lTDeHSsQ0FrDZRVA9tPIA=";
            });
          };
        }
      );

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
      sessionVariables = {
        DIRENV_LOG_FORMAT = null;
      };

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
        PROMPT='%{$fg_bold[blue]%}$(get_pwd)%{$reset_color%} ''${prompt_suffix}'
        local prompt_suffix="%(?:%{$fg_bold[green]%}❯ :%{$fg_bold[red]%}❯%{$reset_color%} "
        RPROMPT=

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
          # set -g status-left "#  "
          set -g status-right-length 100
          set -g status-right "#[fg=red,bg=default] %b %d #[fg=blue,bg=default] %R "
          set -g status-bg default
          setw -g window-status-format "#[fg=blue,bg=black] #I #[fg=blue,bg=black] #W "
          setw -g window-status-current-format "#[fg=blue,bg=default] #I #[fg=red,bg=default] #W "

          run-shell ${tmuxYank}/yank.tmux
        '';
      };
  };
}
