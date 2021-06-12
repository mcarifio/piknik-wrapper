#!/usr/bin/env bash

# strict mode
set -euo pipefail; IFS=$'\n\t'

function main {
    declare -r _dirname=$(cd $(dirname $0); pwd)
    declare -r _basename=$(basename ${_dirname})
    declare -r _me=${_basename%.*}

    nohup ${_dirname}/bin/piknik -config ${_dirname}/piknik-server.toml -server     
}

main $@
