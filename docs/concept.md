# Concept

This document describes what nix-github-release is for and the ideas every
design decision rests on. It is rewritten in place as the concept evolves;
decisions built on it are recorded as ADRs.

## What it is

A Nix flake library and a set of GitHub reusable workflows that let a flake
fetched at a release tag — `github:owner/repo/vX.Y.Z` — build a package that
reports `X.Y.Z`, in projects whose only record of the version is the tag.

Such a project keeps a placeholder (`0.0.0`) in its manifests and has its
release workflow stamp the tag into them when a GitHub Release is published.
A flake is not built by that workflow, and it sees neither the tag it was
fetched at nor `.git`, so without help it builds the placeholder.

The way through is git's `export-subst`: a `VERSION` file holding a
`git describe` placeholder is filled in by GitHub whenever it serves the
repository as an archive, which is how Nix fetches `github:` and `git+https:`
references. The library reads that file and stamps the manifests the same way
the release workflow does. The workflows build the flake through the same
`github:` reference users install from, so the build is checked to report the
tag, and the cache holds the very build users look up.

## Who it is for

Maintainers of projects that:

- release by publishing a GitHub Release, with the tag as the only record of
  the version, and
- ship a Nix flake that users install by tag.

## Principles

- **The tag stays the only record.** Nothing asks the maintainer to commit a
  version before releasing, and nothing moves a tag after it is published.
- **One source of truth for each step.** The version logic and the stamping
  live here once; a project carries only the placeholder file it must carry.
- **Check what users get.** A build is verified from the `github:` reference,
  not from a checkout that users never fetch.
- **Library, not framework.** Functions take and return plain values and
  attribute sets, so a project composes them into the builder it already uses.

## What it does not do

- Build or publish release binaries, Homebrew formulae or registry packages.
- Decide when to release or generate release notes.
- Work for sources that are not served as a `git archive`, such as a plain
  checkout; those builds fall back to naming their commit.
