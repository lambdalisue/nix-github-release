let
  # The version a `git describe` result names: `v1.2.3` is 1.2.3, and a commit
  # past it, `v1.2.3-4-gabc1234`, keeps the distance and the commit as a
  # prerelease suffix. Anything else — the placeholder GitHub did not fill in,
  # or nothing because no tag precedes the commit — names the commit instead.
  fromDescribe =
    {
      described,
      rev,
      placeholder ? "0.0.0",
    }:
    let
      matched = builtins.match "v([0-9][^[:space:]]*)[[:space:]]*" described;
    in
    if matched == null then "${placeholder}-${rev}" else builtins.head matched;
in
{
  inherit fromDescribe;

  # The version of the flake `self`, read from the export-subst file GitHub
  # fills with `git describe` when it serves the repository as an archive.
  version =
    {
      self,
      file ? "${self}/VERSION",
      placeholder ? "0.0.0",
    }:
    fromDescribe {
      described = builtins.readFile file;
      rev = self.shortRev or self.dirtyShortRev or "unknown";
      inherit placeholder;
    };

  # Adds to a crane or rustPlatform build what makes it build as `version`:
  # the derivation's version, and a postPatch that stamps the placeholder in
  # Cargo.toml and in the lock entries of the workspace's own packages, which
  # are the ones without a `source`. Stamping both keeps `--locked` satisfied.
  #
  # Cargo.toml is stamped wherever a `version` key holds the placeholder. A
  # registry dependency written as `{ version = "0.0.0" }` would be stamped
  # too; a bare `name = "0.0.0"` is not.
  stampCargo =
    {
      pkgs,
      version,
      placeholder ? "0.0.0",
    }:
    attrs:
    let
      from = builtins.replaceStrings [ "." ] [ "\\." ] placeholder;
    in
    attrs
    // {
      inherit version;
      nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ [ pkgs.perl ];
      # The version reaches perl through the environment, so no version text
      # is ever read as part of the program.
      postPatch = ''
        export NIX_GITHUB_RELEASE_VERSION=${pkgs.lib.escapeShellArg version}
        perl -pi -e 's/(\bversion\s*=\s*)"${from}"/$1"$ENV{NIX_GITHUB_RELEASE_VERSION}"/g' Cargo.toml
        perl -0pi -e 's/(\nversion = )"${from}"(?=\n(?!source))/$1"$ENV{NIX_GITHUB_RELEASE_VERSION}"/g' Cargo.lock
        unset NIX_GITHUB_RELEASE_VERSION
      ''
      + (attrs.postPatch or "");
    };
}
