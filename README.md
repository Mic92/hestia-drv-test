# hestia-drv-test

Integration test bed for [hestia](https://github.com/Mic92/hestia)'s
`matrix` subaction: an eval job evaluates the flake once with
`nix-eval-jobs`, uploads the `.drv` closures to the GitHub Actions cache,
and emits a build matrix; build jobs run `nix build <drvPath>^*` without
re-evaluating. Currently pinned to the beta fork `Mic92/hestia-beta`.

The checks cover: two systems (x86_64/aarch64 runners), impure rebuilds,
chunked ~1 MiB output, local sources in the drv closure, aliased attrs
(dedup), upstream + local dependencies, a rebuilt nixpkgs package,
`meta.hestia.group` (shared runner) and `meta.hestia.os` (runner
override).
