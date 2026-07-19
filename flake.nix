{
  description = "Test repo for hestia's matrix subaction (eval once, build by drv path)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      checks = eachSystem (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          # Shared, never-upstream-cached dependency: exercises how uncached
          # deps behave across matrix jobs (each job that needs it rebuilds
          # or substitutes it from previous runs).
          shared-dep = pkgs.runCommand "shared-dep" { } ''
            echo "shared dependency round 4" > $out
          '';
        in
        rec {
          # Impure output (differs every rebuild), stresses re-push logic.
          impure-date = pkgs.runCommand "impure-date" { } ''
            echo "built at $(date)" > $out
          '';
          # ~1 MiB of incompressible data: exercises chunking/pack upload.
          big-random = pkgs.runCommand "big-random" { } ''
            head -c 1M /dev/urandom > $out
          '';
          # Local source input: the drv closure includes the source path.
          with-src = pkgs.runCommand "with-src" { src = ./flake.nix; } ''
            cat $src > $out
          '';
          # Alias of with-src: same drvPath, must be deduplicated to one job.
          with-src-alias = with-src;
          # Depends on shared-dep and a real nixpkgs package (upstream
          # substitutable), so the job mixes hestia and cache.nixos.org.
          uses-deps = pkgs.runCommand "uses-deps" { buildInputs = [ pkgs.hello ]; } ''
            hello > $out
            cat ${shared-dep} >> $out
          '';
          # Rebuilt nixpkgs package (not upstream cached): bigger drv
          # closure, patched source.
          patched-hello = pkgs.hello.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              echo "patched by hestia-drv-test" > PATCHED
            '';
            doCheck = false;
          });
          # Grouped: both build in one matrix job. Group names include the
          # system because a group must not span systems.
          small-1 = pkgs.runCommand "small-1" { meta.hestia.group = "small-${system}"; } ''
            echo "small 1" > $out
          '';
          small-2 = pkgs.runCommand "small-2" { meta.hestia.group = "small-${system}"; } ''
            echo "small 2" > $out
          '';
          # Full NixOS system closure: thousands of drvs and sources in the
          # closure, stress test for drv registration/upload and manifest
          # size. Mostly substituted from cache.nixos.org at build time.
          nixos-minimal =
            (nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                {
                  boot.isContainer = true;
                  system.stateVersion = "26.05";
                  # Rebuild marker so the toplevel is never upstream-cached.
                  environment.etc."hestia-drv-test".text = "stress test round 4";
                }
              ];
            }).config.system.build.toplevel;
          # Runner override via meta.hestia.os.
          pinned-runner = pkgs.runCommand "pinned-runner" {
            meta.hestia.os = if system == "x86_64-linux" then "ubuntu-latest" else "ubuntu-24.04-arm";
          } ''
            echo "pinned runner" > $out
          '';
        }
      );
    };
}
