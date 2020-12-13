{ pkgs }:

with pkgs; [
  awscli
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
  nixops
  nix-prefetch-git
  nmap
  opa
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
]
