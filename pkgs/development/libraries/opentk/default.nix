{ stdenv, fetchurl, unzip, mono, mesa, x11 }:

stdenv.mkDerivation rec {
  name = "opentk-2010-10-06";
  
  src = fetchurl {
    url = "mirror://sourceforge/opentk/${name}.zip";
    sha256 = "0npwnk9k3k3gqsfk4ca50b92y85xdxcnsv5zgnm20ib9i8l59ci8";
  };
  
  buildInputs = [ unzip ];
  propagatedBuildInputs = [ mono mesa x11 ];

  buildPhase = ''
    xbuild OpenTK.sln /p:Configuration=Release
  '';

  # FIXME: needs cleanup (and what is the correct Mono install layout?)
  #
  # We're not installing the examples because even if we make them run (by
  # making wrappers that start them in the path they expect so that they can
  # find their resources) they try to create log files in the installation
  # path.
  installPhase = ''
    # Copy build-dir verbatim
    mkdir -p $out/build-dir
    cp -r . $out/build-dir

    # Copy build result
    mkdir -p $out/release
    cp -r Binaries/OpenTK/Release/* $out/release

    mkdir -p $out/lib
    cp -r Binaries/OpenTK/Release/*.dll* $out/lib
    mkdir -p $out/bin
    cp -r Binaries/OpenTK/Release/*.exe $out/bin
    mkdir -p $out/share
    cp -r Binaries/OpenTK/Release/Data/ $out/share/
  '';
    ## Try to make a working wrapper for the opentk examples. Isn't there a cleaner way?
    #cat > $out/bin/opentk-examples << EOF
    ##!/bin/sh
    #export MONO_GAC_PREFIX=${libgdiplus}/lib:${libX11}/lib:\$MONO_GAC_PREFIX
    ## libMonoPosixHelper.so is in ${mono}/lib
    #export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${libgdiplus}/lib:${libX11}/lib:${mono}/lib
    ##cd $out/build-dir
    #exec ${mono}/bin/mono $out/build-dir/Binaries/OpenTK/Release/Examples.exe
    #EOF
    #chmod +x $out/bin/opentk-examples

  # Always needed on Mono, otherwise nothing runs
  dontStrip = true;

  meta = {
    description = ''Low-level C# library that wraps OpenGL, OpenCL and OpenAL'';
    homepage = http://www.opentk.com/;
    license = stdenv.lib.licenses.mit;
  };
}
