{ config, pkgs, ... }:

{
  nix.trustedUsers = [ "root" "@wheel" ];

  time.timeZone = "Europe/London";

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ vim nfs-utils ];
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts
      dina-font
      proggyfonts
      emacs-all-the-icons-fonts
    ];
   };

  services.illum.enable = true;

  services.openssh.enable = true;

  services.emacs.enable = true;
  services.emacs.install = true;
  services.emacs.defaultEditor = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;

  security.sudo.enable = true;

  programs.tmux = {
    enable = true;
    shortcut = "b";
    keyMode = "vi";
    clock24 = true;
    extraTmuxConf = ''
      unbind [
      unbind ]
      unbind p
      unbind n
      
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
      
      set -g prefix C-q
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
}

