{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  users.users.cmacrae = {
    description = "Calum MacRae";
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "input" "tty" "video" "wheel" ];
  };

  # for nix-direnv
  nix.settings.keep-outputs = true;
  nix.settings.keep-derivations = true;
  environment.pathsToLink = [ "/share/nix-direnv" ];

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
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

    # TODO: look at using predicate
    nixpkgs.config.allowUnfree = true;

    home.stateVersion = "24.05";
    home.packages = with pkgs; [
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      bc
      ffmpeg
      gnumake
      gnupg
      gnused
      htop
      ipcalc
      jq
      just
      mpv
      nixd
      nixpkgs-fmt
      nix-prefetch-git
      nmap
      nodejs # for copilot
      pass
      podman
      python3
      pwgen
      ranger
      ripgrep
      rsync
      unzip
      up
      wget
      yt-dlp
    ];

    home.sessionVariables = {
      PAGER = "less -R";
      EDITOR = "emacsclient";
    };

    programs.git = {
      enable = true;
      userName = config.users.users.cmacrae.description;
      userEmail = "hi@cmacr.ae";
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

    services.gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      enableSshSupport = true;
      sshKeys = [ "4F39E235299187ED7B9A8049A85F3EE3488CF521" ];
      pinentryFlavor = "qt";
      extraConfig = ''
        allow-emacs-pinentry
        allow-loopback-pinentry
      '';
    };

    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
    programs.direnv.enableZshIntegration = true;

    programs.firefox.enable = true;
    programs.firefox.profiles.home = {
      id = 0;
      userChrome = builtins.readFile ../../conf.d/userChrome.css;
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        browserpass
        betterttv
        metamask
        reddit-enhancement-suite
        ublock-origin
        vimium
      ];

      search.default = "DuckDuckGo";
      search.force = true;

      settings = {
        "app.update.auto" = false;
        "app.normandy.enabled" = false;
        "beacon.enabled" = false;
        "browser.startup.homepage" = "https://lobste.rs";
        "browser.search.region" = "GB";
        "browser.search.countryCode" = "GB";
        "browser.search.hiddenOneOffs" = "Google,Amazon.com,Bing";
        "browser.search.isUS" = false;
        "browser.ctrlTab.recentlyUsedOrder" = false;
        "browser.newtabpage.enabled" = false;
        "browser.bookmarks.showMobileBookmarks" = true;
        "browser.uidensity" = 1;
        "browser.urlbar.update" = true;
        "datareporting.healthreport.service.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "distribution.searchplugins.defaultLocale" = "en-GB";
        "extensions.getAddons.cache.enabled" = false;
        "extensions.getAddons.showPane" = false;
        "extensions.pocket.enabled" = false;
        "extensions.webservice.discoverURL" = "";
        "general.useragent.locale" = "en-GB";
        "identity.fxaccounts.account.device.name" = config.networking.hostName;
        "privacy.donottrackheader.enabled" = true;
        "privacy.donottrackheader.value" = 1;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.cryptomining.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;
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
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.rejected" = true;
        "toolkit.telemetry.updatePing.enabled" = false;
      };
    };

    # my emacs configuration composed into a package.
    # defined here: `nix/packages/cmacraeEmacs`
    programs.emacs.enable = true;
    programs.emacs.package = pkgs.cmacraeEmacs;

    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;

    programs.browserpass.enable = true;
    programs.browserpass.browsers = [ "firefox" ];

    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      defaultKeymap = "emacs";
      sessionVariables = {
        DIRENV_LOG_FORMAT = null;
      };

      shellAliases = {
        t = "cd $(mktemp -d)";
      };

      oh-my-zsh.enable = true;

      plugins = [
        {
          name = "autopair";
          file = "share/zsh/zsh-autopair/autopair.zsh";
          src = pkgs.zsh-autopair;
        }
        {
          name = "fast-syntax-highlighting";
          file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
          src = pkgs.zsh-fast-syntax-highlighting;
        }
        {
          name = "z";
          file = "share/zsh-z/zsh-z.plugin.zsh";
          src = pkgs.zsh-z;
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

    programs.tmux = {
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
      '';
    };
  };
}

