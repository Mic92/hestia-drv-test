{
  description = "Test repo for hestia's eval-once / build-by-drv-path workflow";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      hydraJobs = {
        hello-a = pkgs.runCommand "hello-a" { } ''
          echo "hello from a $(date)" > $out
        '';
        hello-b = pkgs.runCommand "hello-b" { } ''
          echo "hello from b" > $out
          head -c 1M /dev/urandom >> $out
        '';
        hello-c = pkgs.runCommand "hello-c" { src = ./flake.nix; } ''
          cat $src > $out
          echo "hello from c" >> $out
        '';
      };
    };
}
