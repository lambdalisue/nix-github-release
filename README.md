# nix-github-release

Let a Nix flake fetched at a GitHub release tag build as that release.

```console
$ nix run github:you/tool/v1.4.0 -- --version
tool 1.4.0
```

For projects whose only record of the version is the tag: manifests hold a
placeholder such as `0.0.0`, and publishing a GitHub Release is what makes a
release. A flake fetched at the tag sees neither the tag nor `.git`, so on its
own it builds the placeholder. nix-github-release carries the tag in through
git's `export-subst`, which GitHub applies whenever it serves the repository
as an archive — the way Nix fetches `github:` references.

## Usage

### 1. Add the VERSION file

```console
$ printf '%s\n' '$Format:%(describe:tags,match=v[0-9]*)$' > VERSION
$ echo 'VERSION export-subst' >> .gitattributes
```

Commit both as they are. GitHub fills the file in only in the archives it
serves; in the repository it stays the placeholder.

### 2. Take the version in the flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
    nix-github-release = {
      url = "github:lambdalisue/nix-github-release/vX.Y.Z";
      # The library needs no nixpkgs of its own.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, crane, nix-github-release }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      craneLib = crane.mkLib pkgs;
      # 1.4.0 at the tag v1.4.0, 1.4.0-3-gabc1234 three commits past it, and
      # 0.0.0-<commit> from a checkout.
      version = nix-github-release.lib.version { inherit self; };
      build = {
        pname = "tool";
        src = craneLib.cleanCargoSource ./.;
      };
    in
    {
      packages.${system}.default = craneLib.buildPackage (
        nix-github-release.lib.stampCargo { inherit pkgs version; } (
          build // { cargoArtifacts = craneLib.buildDepsOnly build; }
        )
      );
    };
}
```

`stampCargo` stamps the placeholder in `Cargo.toml` and in the lock entries of
the workspace's own packages before the build, so `CARGO_PKG_VERSION` — and so
`--version` — reports the release. The dependency layer is built from the
unstamped sources and stays cached across releases.

Without Cargo, pass `version` to whatever the build reads it from.

### 3. Build from GitHub in CI

```yaml
# .github/workflows/ci.yml — on every push to main and every pull request
jobs:
  nix:
    uses: lambdalisue/nix-github-release/.github/workflows/build.yml@vX.Y.Z
    with:
      cachix-cache: tool
    secrets:
      cachix-auth-token: ${{ secrets.CACHIX_AUTH_TOKEN }}
```

```yaml
# .github/workflows/release.yml — on: release: types: [published]
jobs:
  nix:
    uses: lambdalisue/nix-github-release/.github/workflows/build.yml@vX.Y.Z
    with:
      ref: ${{ github.event.release.tag_name }}
      cachix-cache: tool
      cachix-pin: release
    secrets:
      cachix-auth-token: ${{ secrets.CACHIX_AUTH_TOKEN }}
```

The workflow builds the `github:` reference, not a checkout: only the archive
has VERSION filled in, so only that build is the one users get from the cache.
Called with a release tag, it fails unless the package reports that release.

## Caveat

The archive of an untagged commit changes when that commit is tagged later. A
lock file that pinned such a commit then fails its hash check the next time it
is fetched; `nix flake update` fixes it. Pins to a tag are never affected.

## Development

Enter the development shell with `nix develop` (or copy `.envrc.sample` to
`.envrc` and `direnv allow`), then:

```sh
just fmt   # format every source
just ci    # everything CI runs: format check, tests
```

The design lives in [docs/concept.md](docs/concept.md), the decisions behind it
in [docs/adr/](docs/adr/), and the behaviour it promises in
[docs/spec/](docs/spec/).

## License

MIT. See [LICENSE](LICENSE).
