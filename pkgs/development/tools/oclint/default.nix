{ stdenv, fetchurl, cmake, clang, llvm }:

stdenv.mkDerivation rec {
  name = "oclint-0.8.1";

  src = fetchurl {
    url = "http://archives.oclint.org/releases/0.8/${name}-src.tar.gz";
    sha256 = "043m3yzw11krp19g7v9ccj0fch7wgha6jr758bmczfhrqsdanvgv";
  };

  buildInputs = [ cmake clang ];

  patches = [ ./add-clang-include-dir.patch ];

  # The oclint build system is a set of scripts (starting with the driver
  # script, buildAll.sh) that clones clang and llvm into the source tree and
  # then run cmake and make in a bunch of directories.
  #
  #   http://docs.oclint.org/en/dev/intro/build.html
  #
  # Yes, it's pretty bad... That's why we must do our own build procedure.
  configurePhase = "true";
  buildPhase = ''
    echo "Doing ./buildCore.sh stuff"
    # ./buildCore.sh
    mkdir -p oclint-core-build
    (cd oclint-core-build \
        && cmake -D OCLINT_BUILD_TYPE=Release \
                 -D CMAKE_CXX_COMPILER=${clang}/bin/clang++ \
                 -D CMAKE_C_COMPILER=${clang}/bin/clang \
                 -D LLVM_ROOT=${llvm} \
                 -D CLANG_ROOT=${clang} \
                 ../oclint-core \
        && make
    )

    echo "Doing ./buildMetrics.sh stuff"
    # ./buildMetrics.sh
    mkdir -p oclint-metrics-build
    (cd oclint-metrics-build \
        && cmake -D OCLINT_BUILD_TYPE=Release \
                 -D CMAKE_CXX_COMPILER=${clang}/bin/clang++ \
                 -D CMAKE_C_COMPILER=${clang}/bin/clang \
                 -D LLVM_ROOT=${llvm} \
                 -D CLANG_ROOT=${clang} \
                 ../oclint-metrics \
        && make
    )

    echo "Doing ./buildRules.sh stuff"
    # ./buildRules.sh
    mkdir -p oclint-rules-build
    (cd oclint-rules-build \
        && cmake -D OCLINT_BUILD_TYPE=Release \
                 -D CMAKE_CXX_COMPILER=${clang}/bin/clang++ \
                 -D CMAKE_C_COMPILER=${clang}/bin/clang \
                 -D LLVM_ROOT=${llvm} \
                 -D CLANG_ROOT=${clang} \
                 -D OCLINT_SOURCE_DIR=../oclint-core \
                 -D OCLINT_BUILD_DIR=../oclint-core-build \
                 -D OCLINT_METRICS_SOURCE_DIR=../oclint-metrics \
                 -D OCLINT_METRICS_BUILD_DIR=../oclint-metrics-build \
                 ../oclint-rules \
        && make
    )

    # TODO:
    #./buildReporters.sh $RELEASE_CONFIG
    #./buildClangTooling.sh $RELEASE_CONFIG
    #./buildRelease.sh
  '';
  # Already done?
  installPhase = "true";

  meta = with stdenv.lib; {
    description = "Static code analysis tool based on Clang/LLVM";
    homepage = http://oclint.org/;
    license = licenses.bsd3;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}
