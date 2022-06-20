{
  description = "Big Neovim Energy";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    flake-utils.url = github:numtide/flake-utils;
    nur.url = github:nix-community/NUR;

    neovim = {
      url = github:neovim/neovim?dir=contrib;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    vim-plugins-overlay = {
      url = github:vi-tality/vim-plugins-overlay;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, neovim, flake-utils, nur, vim-plugins-overlay, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          overlays = [
            vim-plugins-overlay.overlay
            neovim.overlay
            nur.overlay
            (final: prev: {
              python = prev.python3;
            })
          ];
        };
        customNeovim = import ./config.nix { inherit pkgs; };
      in
      {
        packages = {default = customNeovim.neovim;};
      }
    );
}
