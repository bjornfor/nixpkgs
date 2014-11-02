{ stdenv, makeWrapper, git, subversion, mercurial, bazaar, cvs, unzip, curl, gnused, libfaketime }:

stdenv.mkDerivation {
  name = "nix-prefetch-scripts";

  buildInputs = [ makeWrapper ];

  phases = [ "installPhase" "fixupPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    function copyScript {
      local name=nix-prefetch-$1;
      local src=$2;
      local wrapArgs=()
      cp $src $out/bin/$name;
      for dep in ''${@:3}; do
        wrapArgs+=(--prefix PATH : "$dep/bin")
      done
      wrapArgs+=(--prefix PATH : "${gnused}/bin")
      # TODO: Use libfaketime for all scripts?
      if [ "$1" = "git" ]; then
        fakelib="${libfaketime}/lib/libfaketime.so.1"
        test -f "$fakelib" || { echo "$fakelib doesn't exist; please update nix expression."; exit 1; }
        wrapArgs+=(--prefix LD_PRELOAD : "$fakelib")
        wrapArgs+=(--set FAKETIME \""1970-01-01 00:00:00\"")
      fi
      wrapProgram $out/bin/$name "''${wrapArgs[@]}"
    }

    copyScript "hg" ${../../../build-support/fetchhg/nix-prefetch-hg} ${mercurial}
    copyScript "git" ${../../../build-support/fetchgit/nix-prefetch-git} ${git}
    copyScript "svn" ${../../../build-support/fetchsvn/nix-prefetch-svn} ${subversion}
    copyScript "bzr" ${../../../build-support/fetchbzr/nix-prefetch-bzr} ${bazaar}
    copyScript "cvs" ${../../../build-support/fetchcvs/nix-prefetch-cvs} ${cvs}
    copyScript "zip" ${../../../build-support/fetchzip/nix-prefetch-zip} ${unzip} ${curl}
  '';

  meta = with stdenv.lib; {
    description = "Collection of all the nix-prefetch-* scripts which may be used to obtain source hashes";
    maintainers = with maintainers; [ bennofs ];
    platforms = with stdenv.lib.platforms; unix;
    # Quicker to build than to download, I hope
    hydraPlatforms = [];
  };
}
