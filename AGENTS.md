# nix-github-release

Let a Nix flake fetched at a GitHub release tag build as that release.

## How it is built

- **Test first.** Red → green → refactor. Write the failing test before the
  code that makes it pass.
- **Each layer holds one thing.** Put a fact in the one layer that owns it,
  and nowhere else.

  | Layer | Holds |
  | --- | --- |
  | `docs/concept.md` | what this is and for whom |
  | `docs/adr/` | one decision and why it was made |
  | `docs/spec/` | the behaviour users and other components can rely on |
  | Tests | the details that pin the behaviour down: rules, boundaries, tables |
  | Code | how it is done |
  | Commits | why a change was made |
  | Comments | why it is not done another way |

  Before writing, fixing or reviewing a record, read `docs/adr/README.md`;
  before writing, fixing or reviewing a spec, read `docs/spec/README.md`.
  Follow their writing order.
- **Dependencies are current.** Before adding or bumping one, look up its
  latest release in the registry. Do not copy a version from memory or from
  another repository.

## Quality gate

Run `just ci` before reporting a change as done. CI runs the same recipe.

## Layout

| Path | What lives there |
| --- | --- |
| `lib/` | the functions the flake exports as `lib` |
| `tests/` | the `nix flake check` checks that pin the library down |
| `.github/workflows/` | the reusable workflows other repositories call, and this repository's own CI |
| `docs/` | concept, ADRs, specs, references |

## Language

- README, docs and commit messages: English
- Code comments, log and error messages: English

## Commits

Scoped Commits:

```
<scope>: <description>

<why this change is needed>
```

- The scope names where the change is, from the table below. Several scopes
  are joined with `, `; a change across the whole tree uses `treewide`.
- The description starts in lower case, has no trailing period, and stays
  within 72 characters.
- The body explains why. The code shows how; the tests show what.
- A release commit is `release: vX.Y.Z`.
- A breaking change says so in the body and carries a `BREAKING CHANGE:`
  trailer.

| Scope | Covers |
| --- | --- |
| `lib` | `lib/`, `tests/` |
| `workflows` | the reusable workflows under `.github/workflows/` |
| `docs` | `README.md`, `AGENTS.md`, `docs/concept.md` |
| `adr` | `docs/adr/` |
| `spec` | `docs/spec/` |
| `ci` | this repository's own CI |
| `nix` | `flake.nix`, `flake.lock` |
| `deps` | dependency updates |

Add a row when a new area appears.
