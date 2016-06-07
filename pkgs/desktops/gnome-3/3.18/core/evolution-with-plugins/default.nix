{ stdenv, runCommand, bbe, perl, nukeReferences
, evolution, evolution_data_server, plugins ? []
}:

# Getting evolution to find external requires patching. Brute force solution:
# make a derivation with Evolution + EDS + plugins in one store path.

runCommand "evolution-with-plugins" {} ''
  set -x
  mkdir -p "$out"

  # copy all components
  cp -r ${evolution}/. "$out"
  chmod +w -R "$out"
  cp -r ${evolution_data_server}/. "$out"
  chmod +w -R "$out"
  ${stdenv.lib.concatMapStringsSep "; " (x: "cp -r ${x}/. $out") plugins}
  chmod +w -R "$out"

  # fixup store path references
  #find "$out" -type f -exec ${bbe}/bin/bbe \
  #        -e "s|${evolution}|$out|" \
  #        -e "s|${evolution_data_server}|$out|" \
  #        ${stdenv.lib.concatMapStringsSep " " (x: "-e \"s|${x}|$out|\"") plugins} \
  #        '{}' -o '{}' \;

  cat > replacer << __EOF__
  #!${stdenv.shell}
  set -x
  i=\$1
  cat "\$i" \
      | ${perl}/bin/perl -pe "s|${evolution}|$out|g" \
      | ${perl}/bin/perl -pe "s|${evolution_data_server}|$out|g" \
      | ${stdenv.lib.concatMapStringsSep " | " (x: "${perl}/bin/perl -pe \"s|${x}|$out|g\"") plugins} \
      > "\$i.tmp"
  if test -x "\$i"; then chmod +x "\$i.tmp"; fi
  mv "\$i.tmp" "\$i"
  __EOF__
  chmod +x replacer
  find "$out" -type f -exec ./replacer '{}' \;
''
