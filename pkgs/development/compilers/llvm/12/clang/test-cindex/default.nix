{ stdenv, python3, libclang }:

stdenv.mkDerivation {
  name = "test-clang-cindex";

  src = libclang.python.src;

  buildInputs = [ python3 ];
  propagatedBuildInputs = [ libclang.python ];

  installPhase = ''
    set -x
    export PYTHONPATH="$PYTHONPATH:${libclang.python}/${python3.sitePackages}"
    python3 ./bindings/python/examples/cindex/cindex-includes.py ${./hello.c}
    touch "$out"
  '';
}
