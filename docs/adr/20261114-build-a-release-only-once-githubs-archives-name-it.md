# Build a release only once GitHub's archives name it

Status: Accepted

## Context

The tag reaches a flake through `export-subst`
(20261017-carry-the-release-tag-into-a-flake-through-export-subst.md), so a
build is the release only when GitHub generated the archive after the commit
was tagged. GitHub keeps serving an archive it generated earlier for a while
after the tag exists — tens of minutes have been seen, with no bound given —
and every release has such an archive: CI builds each commit from its
`github:` reference before it can be tagged. Nix fetches a tag as its commit's
archive, from one of two endpoints that GitHub keeps apart, so one can name
the tag while the other still names the commit. The build workflow, called
with the tag in that window, built, cached and pinned the commit and then
failed its version check, again on every re-run until GitHub caught up.

## Decision

Called with a release tag, the build workflow builds nothing until every
archive of the tagged commit that Nix may fetch names the tag. It gives up
after a bound far beyond the staleness seen.

## Alternatives considered

- Tag a commit whose archive was never generated. CI builds every commit, and
  a repository whose main branch only takes pull requests cannot tag a commit
  CI has not seen.
- Retry the build until the version check passes. Each failed attempt has
  already built, pushed and pinned the commit's build under the release's
  name.
- Leave the wait to each calling repository. Every caller would need the same
  job, and one that lacks it publishes the wrong build.

## Consequences

- A release's build starts minutes to hours after the tag, and a run that
  waits past the bound fails without building anything.
- A lock written from the tag before GitHub catches up holds the commit's
  archive and fails its hash check afterwards; waiting does not prevent that
  for fetches outside the workflow.
