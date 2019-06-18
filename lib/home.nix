{ config, lib, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.zsh ];
  users.users.cmacrae.shell = pkgs.zsh;
  users.users.cmacrae.home = if pkgs.stdenv.isDarwin
    then "/Users/cmacrae"
    else "/home/cmacrae";
  home-manager.users.cmacrae = {
    home.packages = import ./packages.nix { inherit pkgs; };

    home.sessionVariables = {
      PAGER = "less -R";
      EDITOR = "emacsclient";
    };

    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;
    programs.fzf.defaultOptions = if pkgs.stdenv.isDarwin then [
      "--color fg:240,bg:230,hl:33,fg+:241,bg+:221,hl+:33"
      "--color info:33,prompt:33,pointer:166,marker:166,spinner:33"
    ] else [];

    programs.browserpass.enable = true;
    programs.browserpass.browsers = [ "chrome" "chromium" ];

    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      defaultKeymap = "emacs";
      history = {
        extended = true;
        ignoreDups = true;
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
      ];
    };

    programs.tmux = {
      enable = true;
      shortcut = "q";
      keyMode = "vi";
      clock24 = true;
      terminal = "screen-256color";
      customPaneNavigationAndResize = true;
      extraConfig = ''
        unbind [
        unbind ]
        
        bind ] next-window
        bind [ previous-window
        bind Escape copy-mode
        
        bind-key -r C-k resize-pane -U
        bind-key -r C-j resize-pane -D
        bind-key -r C-h resize-pane -L
        bind-key -r C-l resize-pane -R
        
        bind-key -r C-M-k resize-pane -U 5
        bind-key -r C-M-j resize-pane -D 5
        bind-key -r C-M-h resize-pane -L 5
        bind-key -r C-M-l resize-pane -R 5
        
        set -g pane-border-fg black
        set -g pane-active-border-fg red
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
        setw -g window-status-fg white
        setw -g window-status-attr none
        
        set -g status-left ""
        set -g status-right "#[fg=red,bg=default] %b %d #[fg=blue,bg=default] %R "
        set -g status-right-length 100
        set -g status-bg default
        setw -g window-status-format "#[fg=blue,bg=black] #I #[fg=blue,bg=black] #W "
        setw -g window-status-current-format "#[fg=blue,bg=default] #I #[fg=red,bg=default] #W "
      '';
    };
  };
}
