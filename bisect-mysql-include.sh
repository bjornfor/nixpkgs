#!/bin/sh
# Git bisect runner script

#set -x

outputs=$(nix-build -A mariadb.all)
ret=$?
if [ $ret -eq 100 ]; then
    exit 125  # this revision cannot be tested
fi
if [ $ret -ne 0 ]; then
    exit 1  # fail
fi

for out in $(echo $outputs); do
    pcfile=$(find $out -name "*.pc") || exit 125  # this revision cannot be tested
    if ! [ -f "$pcfile" ]; then
        continue
    fi

    incdir=$out$(grep includedir= $pcfile | cut -c 21-)
    echo Include directory is: $incdir
    if [ -d "$incdir" ]; then
        exit 0  # success
    else
        exit 1  # fail
    fi
done

# no .pc file
exit 125  # skip
