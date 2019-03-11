{ config, pkgs, ... }:

{
  nix.nixPath =
    [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/cmacrae/dev/nix/air/configuration.nix:/nix/var/nix/profiles/per-user/root/channels"
    ];
  imports =
    [
      ./hardware-configuration.nix
      ./wayland.nix
      ./users.nix
    ];

  boot.cleanTmpDir = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.checkJournalingFS = false;
  boot.initrd.kernelModules = [ "fbcon" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ 
    "i915.enable_fbc=1"
  ];

  sound.enable = true;
  hardware.enableAllFirmware = true;
  hardware.bluetooth.enable = false;
  hardware.pulseaudio.enable = true;
  
  powerManagement.enable = true;

  networking = {
    hostName = "air";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/London";

  nixpkgs.config.allowUnfree = true;

  services.openssh.enable = true;
  services.emacs.enable = true;
  services.emacs.install = true;
  services.emacs.defaultEditor = true;
  services.illum.enable = true;
  security.sudo.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    promptInit = "autoload -Uz promptinit && promptinit";
    interactiveShellInit = ''
      autoload -Uz zutil
      autoload -Uz complist
      autoload -Uz colors && colors

      setopt   correct always_to_end notify
      setopt   nobeep autolist autocd print_eight_bit
      setopt   append_history share_history globdots
      setopt   pushdtohome cdablevars recexact longlistjobs
      setopt   autoresume histignoredups pushdsilent noclobber
      setopt   autopushd pushdminus extendedglob rcquotes
      unsetopt bgnice autoparamslash

      # Emacs bindings
      bindkey -e

      # Prompts
      if [[ ! -n $INSIDE_EMACS ]]; then
          export "PROMPT=
      %{$fg[blue]%}%n %{$fg[red]%}$ %{$reset_color%}"
          export "RPROMPT=%{$fg[blue]%}%~%f%b"
      else
          export "PROMPT=
      %{$fg[blue]%}%~ %{$fg[red]%}$ %f%b"
      fi

      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    '';
  };

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

  system.stateVersion = "18.09";
}
