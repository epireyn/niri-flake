{ lib, ... }:
let
  git-hashes = import ./git-hashes.nix;

  cargo-git-packages =
    src:
    lib.pipe "${src}/Cargo.lock" [
      builtins.readFile
      builtins.fromTOML
      (lock: lock.package)
      (builtins.filter (pkg: lib.hasPrefix "git+" (pkg.source or "")))
      (map (
        pkg:
        let
          url-rev = lib.splitString "#" (lib.removePrefix "git+" pkg.source);
        in
        pkg
        // {
          url = builtins.head (lib.splitString "?" (builtins.head url-rev));
          rev = lib.last url-rev;
        }
      ))
    ];
in
{
  args = src: {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
    outputHashes = builtins.listToAttrs (
      map (pkg: {
        name = "${pkg.name}-${pkg.version}";
        value = git-hashes.${pkg.rev};
      }) (builtins.filter (pkg: git-hashes ? ${pkg.rev}) (cargo-git-packages src))
    );
  };

  generate-hashes =
    srcs:
    lib.pipe srcs [
      (builtins.concatMap cargo-git-packages)
      (map (pkg: {
        name = pkg.rev;
        value = pkg;
      }))
      builtins.listToAttrs
      (lib.mapAttrsToList (
        rev: pkg:
        let
          inherit
            (builtins.fetchGit {
              inherit (pkg) url rev;
              allRefs = true;
              submodules = true;
            })
            narHash
            ;
        in
        "  \"${rev}\" = \"${narHash}\"; # ${pkg.url}"
      ))
      (builtins.concatStringsSep "\n")
      (hashes: ''
        # This is a generated file.
        # It lists hashes of git dependencies found in Cargo.lock files, keyed by commit.
        # Dependencies listed here are fetched with `fetchgit` at build time,
        # any other commit falls back to `builtins.fetchGit` during evaluation.
        {
        ${hashes}
        }
      '')
    ];
}
