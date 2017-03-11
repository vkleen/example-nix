# Main build file for managing all modules

let

    # Version of Nixpkgs to lock down to for our build
    #
    pkgsMakeArgs = {
        # git describe: 16.09-beta-11812-gfa03b8279f
        rev = "3bc9a5d8260430606b28b2692bdc6655a75dcfa6";
        sha256 = "10163h6v3z38mvmmkw23i8ylylpc2fh2mck18i1afamq6ipam16s";
    };

    pkgsMake = let
      pkg-make-path = (import <nixpkgs> {}).fetchFromGitHub {
        owner = "vkleen";
        repo = "example-nix";
        rev = "86583bf002db6f71c11a644c978b0eda23e6617b";
        sha256 = "10163h6v3z38mvmmkw23i8ylylpc2fh2mck18i1afamq6ipam16s";
      };
      in import (pkgs-make-path + "/modules/pkgs-make");

    # `pkgs-make` doesn't have a lot of code, but it does hide away enough
    # complexity to make this usage site simple and compact.
    #
    # If `pkgs-make` doesn't meet your all of your needs, you should be able
    # to modify it with some understanding of both Nix [NIX] and Nixpkgs
    # [NIXPKG], and the "call package" technique of calling functions in Nix
    # [CALLPKG].
    #
    # [NIX] http://nixos.org/nix/manual
    # [NIXPKGS] http://nixos.org/nixpkgs/manual
    # [CALLPKG] http://lethalman.blogspot.com/2014/09/nix-pill-13-callpackage-design-pattern.html

in

pkgsMake pkgsMakeArgs ({ call, lib }:
    let
        modifiedHaskellCall = f:
            lib.nix.composed [
                lib.haskell.enableLibraryProfiling
                lib.haskell.doHaddock
                f
            ];
        haskellLib = modifiedHaskellCall call.haskell.lib;
        haskellApp = modifiedHaskellCall call.haskell.app;
    in
    rec {

        ekg-assets = call.package modules/ekg-assets;
        example-lib = haskellLib modules/example-lib;
        example-app-static = haskellApp modules/example-app;
        example-app-dynamic =
            lib.haskell.enableSharedExecutables example-app-static;
        example-app-compact = call.package modules/example-app-compact;
        example-tarball = lib.nix.tarball example-app-compact;

        # Values in sub-sets are excluded as dependencies (prevents triggering
        # unnecessary builds when entering into nix-shell).  Be careful not to
        # chose a name that conflicts with a package name in `nixpkgs`.
        #
        example-extra.stack = call.package modules/stack;
        example-extra.licenses =
            lib.nix.licenses.json
                { inherit example-app-compact example-app-dynamic; };

    })
