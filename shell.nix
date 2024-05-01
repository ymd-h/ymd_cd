{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.bashInteractive
  ];

  shellHook = ''
  . ./ymd_cd.sh
  '';
}
