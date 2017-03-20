# This expression returns a list of all fixed output derivations used by ‘expr’.
#
# Usage:
#   nix-build --arg expr "(import ./. {}).hello" --keep-going -Q ./maintainers/scripts/all-sources.nix
#   nix-build --arg expr "(import ./. {})" --keep-going -Q ./maintainers/scripts/all-sources.nix
#
# The latter command fails due to eval issues in nixpkgs, and when that's
# fixed (i.e. comment out 'beamPackages' form all-packages.nix), it fails on
# stack overflow / infinite recursion. The latest .nix file being evaluated was
# "maven" something.
#
# Another problem:
#
#   $ nix-build ./maintainers/scripts/all-sources.nix --arg expr "(import ./. {}).eclipses" --keep-going -Q
#   these derivations will be built:
#     /nix/store/d1cxji9vfcyr8lp955pid7yzw5x8z0ll-AnyEditTools_2.6.0.201511291145.jar.drv
#     building path(s) ‘/nix/store/h6ivbqb0qpr2xvzgdd0wiqfxvdaskhnc-AnyEditTools_2.6.0.201511291145.jar’
#     output path ‘/nix/store/h6ivbqb0qpr2xvzgdd0wiqfxvdaskhnc-AnyEditTools_2.6.0.201511291145.jar’ has sha256 hash ‘1nyrad2df971gi88dadh1dv8151hsm2q3c6yxz5mmwcm8scwsjpy’ when ‘1vllci75qcd28b6hn2jz29l6cabxx9ql5i6l9cwq9rxp49dhc96b’ was expected
#     error: build of ‘/nix/store/d1cxji9vfcyr8lp955pid7yzw5x8z0ll-AnyEditTools_2.6.0.201511291145.jar.drv’ failed
#
# Such errors stop the build, even with --keep-going.
#
# FIXME: Lots of duplication between ./find-tarballs.nix and this script.

with import ../.. { };
with lib;

{ expr }:

let

  root = expr;

  uniqueDrvs = map (x: x.drv) (genericClosure {
    startSet = map (drv: { key = head (drv.urls or [ drv.url ]); inherit drv; }) fetchurlDependencies;
    operator = const [ ];
  });

  urls = map (drv: { url = head (drv.urls or [ drv.url ]); hash = drv.outputHash; type = drv.outputHashAlgo; name = drv.name; }) fetchurlDependencies;

  fetchurlDependencies =
    filter
      (drv: drv.outputHash or "" != ""
          && drv.postFetch or "" == "" && (drv ? url || drv ? urls))
      dependencies;

  dependencies = map (x: x.value) (genericClosure {
    startSet = map keyDrv (derivationsIn' root);
    operator = { key, value }: map keyDrv (immediateDependenciesOf value);
  });

  derivationsIn' = x:
    if !canEval x then []
    else if isDerivation x then optional (canEval x.drvPath) x
    else if isList x then concatLists (map derivationsIn' x)
    else if isAttrs x then concatLists (mapAttrsToList (n: v: derivationsIn' v) x)
    else [ ];

  keyDrv = drv: if canEval drv.drvPath then { key = drv.drvPath; value = drv; } else { };

  immediateDependenciesOf = drv:
    concatLists (mapAttrsToList (n: v: derivationsIn v) (removeAttrs drv ["meta" "passthru"]));

  derivationsIn = x:
    if !canEval x then []
    else if isDerivation x then optional (canEval x.drvPath) x
    else if isList x then concatLists (map derivationsIn x)
    else [ ];

  canEval = val: (builtins.tryEval val).success;

in uniqueDrvs
