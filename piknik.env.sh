# source this

[[ -z "${BASH_SOURCE}" ]] && { >&2 echo "No BASH_SOURCE?" ; return 1; }

# Create a function to do the work, then delete it. Allows `declare`
function _main {
    # Get the location of this script, preserving symlinks.
    declare -r here=$(cd $(dirname ${BASH_SOURCE}); pwd)
    # Add here to path if needed.
    &> /dev/null grep ${here}/bin <<< ${PATH} || export PATH="${here}/bin:${PATH}"
    
    # Derive the function name below based on the name of this script.
    declare -r name=$(basename ${BASH_SOURCE%%.*})
    # Use the correct client config file, piknik-client.toml if present, then piknik-client-remote.toml
    declare toml=${here}/${name}-client-remote.toml
    [[ -r ${here}/${name}-client-local.toml ]] && toml=${here}/${name}-client-local.toml

    # Create a function in the current bash process
    eval "function ${name} { command ${name} -config ${toml} \$*; }" && export -f ${name}
}

# Call _main then remove it.
_main $@
unset _main
