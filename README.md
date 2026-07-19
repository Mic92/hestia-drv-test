# hestia-drv-test

Integration test bed for [hestia](https://github.com/Mic92/hestia)'s
"eval once, build by drv path" workflow: an eval job runs `nix-eval-jobs`,
registers the resulting `.drv` paths with `hestia hook`, and matrix build
jobs run `nix build <drvPath>^*` substituting the drv closure from the
GitHub Actions cache instead of re-evaluating the flake.
