{
  description = "Vendo, a vending machine software running on a Raspberry Pi";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    target.url = "github:nixos/nixpkgs/1b7a6a6e57661d7d4e0775658930059b77ce94a4";
    flutter-elinux = {
      url = "github:hfxbse/nixos-config?ref=derivation/flutter-elinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flutter-elinux, target, nixpkgs }:
  let
    defaultSystems = [ "x86_64-linux" ];

    forAllSystems = systems: function: nixpkgs.lib.genAttrs systems (system: function system);
    forAllDefaultSystems = forAllSystems defaultSystems;
  in
  {
    packages = forAllDefaultSystems (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      targetPkgs = (import target {
        localSystem = system;
        overlays = [
          (final: prev: {
            libgbm = prev.mesa;
            systemdLibs = prev.systemd;
          })
        ];
      });

      sdk = flutter-elinux.packages.${system}.flutter-elinux.override {
        clang = targetPkgs.clang;
        pkgsCross = targetPkgs.pkgsCross;
      };
    in
    {
      # Links the flutter-elinux SDK into working directory to allow IntelliJ to find it
      # Workaround till IntelliJ supports direnv or similar
      install-sdk = pkgs.writeShellScriptBin "install-sdk" ''
        set -e;
        rm .sdk;
        ln -s ${sdk}/opt/flutter-elinux .sdk;
      '';

      flutter-elinux = sdk;
    });

    apps = forAllDefaultSystems (system: let
      pkgs = self.packages.${system};
    in
    {
      dart = {
        type = "app";
        program = "${pkgs.flutter-elinux}/opt/flutter-elinux/flutter/bin/dart";
      };
   });

   devShells = forAllDefaultSystems (system:
   let
    pkgs = nixpkgs.legacyPackages.${system};
    flutter-elinux = self.packages.${system}.flutter-elinux;
   in
   {
      default = pkgs.mkShell {
        nativeBuildInputs = [ flutter-elinux ];
      };
   });
  };
}
