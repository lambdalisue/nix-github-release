# Library

What the flake's `lib` output promises to a flake that uses it.

## The VERSION file

A project carries one file, `VERSION` at the root of its flake by default,
holding exactly this line:

```
$Format:%(describe:tags,match=v[0-9]*)$
```

and marks it in `.gitattributes`:

```
VERSION export-subst
```

Both are the project's to write; nothing here can supply them, because GitHub
fills the file in only for files of the repository it is archiving. The tags
it describes are `v` followed by the version.

## The version a flake builds as

`lib.version { inherit self; }` names the version of the flake `self`:

- fetched at a release tag `vX.Y.Z`, it is `X.Y.Z`;
- fetched at a commit past a tag, it is that tag's version with the distance
  and the commit after it, as `git describe` writes them;
- from a checkout, or a commit no tag precedes, it is the placeholder followed
  by the commit, so such a build never passes for a release.

## Stamping a Cargo build

`lib.stampCargo { inherit pkgs version; } attrs` returns the attributes of a
crane or rustPlatform build that builds as `version`: the derivation carries
it, and the workspace's own packages are stamped with it in `Cargo.toml` and
`Cargo.lock` before the build, so `CARGO_PKG_VERSION` and `--locked` agree
with it. Registry packages in the lock are never changed. Whatever the
attributes already held in `postPatch` and `nativeBuildInputs` still applies.
