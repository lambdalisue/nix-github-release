# Workflows

What the reusable workflows promise to a repository that calls them.

## build.yml

Called as
`lambdalisue/nix-github-release/.github/workflows/build.yml@<tag>`, it builds
the given packages of the calling repository's flake on each runner it is
given, from the `github:` reference of the commit or tag it is given — the
source a user who installs that reference gets — never from a checkout.

- With no ref, it builds the commit the calling run is for; for a pull
  request, the head commit.
- With no packages, it builds the default package.
- Called with a release tag `vX.Y.Z`, the run fails unless every package's
  version is `X.Y.Z` and, for a package that names a program, its
  `--version` output contains `X.Y.Z`.
- With a Cachix cache it reads from that cache, and pushes what it builds when
  the auth token is passed. With a pin name it also keeps the build under that
  name — suffixed with the system, and with the package unless it is the
  default one — so the cache's retention never collects it.
- It asks for no permission beyond reading the repository's contents.
