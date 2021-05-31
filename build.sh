#!/usr/bin/env sh

find ./src -name '*.md' -exec claat export -o codelabs {} \;

delete_codelab_if_not_needed () {
  codelab_name=$(basename $1)
  source_file_count=$(grep -r -l -m 1 "id: $codelab_name" ./src | wc -l)

  if [[ $source_file_count -eq 0 ]]; then
    echo "$codelab_name not found in sources - remove this codelab"
    rm -rf $1
  else
    echo "$codelab_name found in sources - save this codelab"
  fi
}

export -f delete_codelab_if_not_needed
find ./codelabs -mindepth 1 -maxdepth 1 -type d -exec bash -c 'delete_codelab_if_not_needed "$0"' {} \;