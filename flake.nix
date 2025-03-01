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
        packages.default = pkgs.writeTextFile {
          name = "ymd_cd";
          text = builtins.readFile ./ymd_cd.sh;
          destination = "/ymd_cd.sh";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.bashInteractive
          ];

          shellHook = ''
            . ${packages.default}/ymd_cd.sh
          '';
        };
      });
}
