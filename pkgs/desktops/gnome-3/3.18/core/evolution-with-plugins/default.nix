{ stdenv, runCommand, evolution, evolution_data_server, plugins ? [] }:

# Getting evolution to find external requires patching. Brute force solution:
# make a derivation with Evolution + EDS + plugins in one store path.

runCommand "evolution-with-plugins" {} ''
  mkdir -p "$out"
  cp -r ${evolution}/. "$out"
  chmod +w -R "$out"
  cp -r ${evolution_data_server}/. "$out"
  chmod +w -R "$out"
  ${stdenv.lib.concatMapStringsSep "; " (x: "cp -r ${x}/. $out") plugins}
''
