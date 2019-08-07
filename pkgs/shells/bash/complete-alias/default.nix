{ stdenv, fetchzip }:

stdenv.mkDerivation rec {
  name = "complete-alias-${version}";
  version = "1.6.0";

  src = fetchzip {
    url = "https://github.com/cykerway/complete-alias/archive/${version}.tar.gz";
    sha256 = "1s02wsg12422kzrlb9khq4hp3clm35qrvcvqa109r1dz8bmx9ff1";
  };

  installPhase = ''
    install -Dm444 -t "$out/share/bash-completion/completions" bash_completion.sh
  '';

  meta = with stdenv.lib; {
    description = "Programmable completion function for shell aliases";
    homepage = "https://repo.cykerway.com/complete-alias";
    license = licenses.gpl3;
    platforms = platforms.all;
    maintainers = with maintainers; [ bjornfor ];
  };
}
