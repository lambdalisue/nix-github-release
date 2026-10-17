# Carry the release tag into a flake through export-subst

Status: Accepted

## Context

The projects this serves release by publishing a GitHub Release, and the tag
is the only record of the version: manifests hold a placeholder that the
release workflow stamps. A flake is not built by that workflow. Fetched as
`github:owner/repo/vX.Y.Z`, it sees neither the tag nor `.git`, only the files
of the commit, so it built the placeholder.

## Decision

The tag reaches the flake as the content of an `export-subst` file that
GitHub fills with `git describe` when it serves the repository as an archive.
The flake reads the version from that file.

## Alternatives considered

- Commit the version before tagging. The release would no longer start from
  publishing a GitHub Release alone.
- Have the release workflow commit the stamped version and move the tag onto
  it. A tag that moves after it is published cannot be trusted, and immutable
  releases forbid it.
- Attach a stamped source archive to the release. A Nix user would have to
  fetch a release asset URL instead of the tag.

## Consequences

- A build from a checkout cannot learn the tag and names its commit instead.
- An untagged commit's archive changes when that commit is later tagged, so a
  lock file that pinned the commit fails its hash check on the next fetch.
- A cache only serves a build made from the archive, so CI builds from
  `github:` references rather than from its checkout.
- The approach lasts only as long as GitHub applies `export-subst` when it
  serves archives.
