# Given the path to a git repository, return the output of "git describe [--tags]"

# FIXME:
#  warning: dumping very large path (> 256 MiB); this may run out of memory
#  error: illegal name: ‘.git’

{ runCommand, git }:

{ repo, tags ? false }:

runCommand "nixpkgs-version" { buildInputs = [ git ]; }
''
  # Support both work trees and bare repos
  if [ -d "${repo}/.git" ]; then
    git_dir="${repo}/.git"
  else
    git_dir="${repo}"
  fi

  git --git-dir "$git_dir" describe ${if tags then "--tags" else ""} >"$out"
''
