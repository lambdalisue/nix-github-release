# Run `nix develop` (or use direnv) first so every tool is on PATH.

set shell := ["bash", "-euo", "pipefail", "-c"]

# List the recipes.
default:
    @just --list

# Format every source.
fmt:
    find . -name '*.nix' -not -path './.*' -print0 | xargs -0 nixfmt

# Check formatting without changing files.
fmt-check:
    find . -name '*.nix' -not -path './.*' -print0 | xargs -0 nixfmt --check

# Run the tests.
test:
    nix flake check --print-build-logs

# Everything CI runs.
ci: fmt-check test
