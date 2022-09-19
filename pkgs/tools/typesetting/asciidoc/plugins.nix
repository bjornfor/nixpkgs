{ stdenv, fetchurl, unzip }:

{
# unzip is needed to extract filter and backend plugins
 unzip ? null
# filters
 enableDitaaFilter ? false, jre ? null
 enableMscgenFilter ? false, mscgen ? null
 enableDiagFilter ? false, blockdiag ? null, seqdiag ? null, actdiag ? null, nwdiag ? null
 enableQrcodeFilter ? false, qrencode ? null
 enableMatplotlibFilter ? false, matplotlib ? null, numpy ? null
 enableAafigureFilter ? false, aafigure ? null, recursivePthLoader ? null
# backends
 enableDeckjsBackend ? false
 enableOdfBackend ? false
}
