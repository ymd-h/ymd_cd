{
  description = "ymd_cd";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in rec {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "ymd_cd";
          src = ./.;
          phases = [ "unpackPhase" "installPhase" ];
          installPhase = ''
          mkdir -p $out
          cp $src/ymd_cd.sh $out
          '';
        };
        devShells.default = import ./shell.nix { inherit pkgs; };
      });
}
