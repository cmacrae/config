{ pkgs }:

with pkgs; [
  ansible
  bc
  bind
  ffmpeg-full
  gnumake
  gnupg
  htop
  jq
  mpv
  nixops
  nix-prefetch-git
  nmap
  p7zip
  pass
  python3
  ranger
  ripgrep
  rsync
  terraform
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
  golangci-lint
  golint
  go2nix
  errcheck
  gotags

  # Docker
  docker
  docker-machine
  docker-machine-driver-hyperkit
  hyperkit

  # k8s
  fluxctl
  kubectl
  kubectx
  kube-prompt
  kubernetes-helm
  kustomize
]
