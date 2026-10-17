{
  description = "A package that reports the version nix-github-release gives it";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
  };

  outputs =
    { self, nixpkgs }:
    let
      # The library of the commit under test, not a released one.
      nix-github-release = import ../../lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      version = nix-github-release.version { inherit self; };
    in
    {
      packages = nixpkgs.lib.genAttrs systems (system: {
        default =
          (nixpkgs.legacyPackages.${system}.writeShellScriptBin "example" ''
            echo "example ${version}"
          '').overrideAttrs
            { inherit version; };
      });
    };
}
