#!/bin/bash

function set_command() {
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

cat > "${HOME}/.cloud/${1}_wrapper.sh" << EOF
#!/bin/bash

echo "${1} \$@" > /tmp/cmd.sh
cloud
rm /tmp/cmd.sh
EOF
chmod +x "${HOME}/.cloud/${1}_wrapper.sh"

if [[ "$SHELL" =~ .*.zsh ]] && [[ -z "$(grep "${HOME}/.cloud/${1}_wrapper.sh" "${HOME}/.zshrc")" ]]; then
echo "zsh detected"
cat >> "${HOME}/.zshrc" << EOF
export CLOUD_COMMANDS="\$CLOUD_COMMANDS\${CLOUD_COMMANDS:+\n}${1}"
if [[ -r "${HOME}/.cloud/${1}_wrapper.sh" ]]; then
alias ${1}="${HOME}/.cloud/${1}_wrapper.sh"
fi
EOF
fi
if [[ "$SHELL" =~ "*bash" ]] && [[ -z "$(grep "${HOME}/.cloud/${1}_wrapper.sh" "${HOME}/.bashrc")" ]]; then
echo "bash detected"
cat >> ${HOME}/.bashrc << EOF
export CLOUD_COMMANDS="\$CLOUD_COMMANDS\${CLOUD_COMMANDS:+\n}${1}"
if [[ -r "${HOME}/.cloud/${1}_wrapper.sh" ]]; then
alias ${1}="${HOME}/.cloud/${1}_wrapper.sh"
fi
EOF
fi
}

function set_config() {
    source ${HOME}/.cloud/cloudrc
    export "$1"
    configs=("SHUFFLES" "REPETITION_RANGE" "ALIGN" "PADDING" "SPACING" "MAX_LINES" "MODE")
    for key in "${configs[@]}"; do
        echo "$key=${!key}" >> /tmp/cloudrc
    done
    mv /tmp/cloudrc ${HOME}/.cloud/cloudrc
}

function get_dim_data() {
    sizex=$(cat $1 | head -n1 | wc -m) 
	while IFS= read -r line; do
        if (( sizex < ${#line} )); then
            sizex=${#line}
        fi
	done < $1
	echo "$sizex $(wc -l $1 | cut -d" " --field 1) $1" >> "${HOME}/.cloud/dimensions"
}

function process() {
    export -f get_dim_data
    rm "${HOME}/.cloud/dimensions"
    find ${HOME}/.cloud/art -type f -exec bash -c 'get_dim_data $0' {} \;
}

function import() {
    cp $1 ${HOME}/.cloud/art
}

function help() {
cat << EOF
Usage: cloudcfg [COMMAND] [SUBCOMMAND] [ARGUMENTS]
Commands:
    art                 Manage ascii art files
        add             [FILENAME]
        remove          [FILENAME]
        show            [FILENAME]
        list
    command:            Manage commands wapped by cloud. eg cat, ls, find
        add             [COMMAND]
        remove          [COMMAND]
        list
    config:             Manage configs. eg "SHUFFLES" "REPETITION_RANGE" "ALIGN" "PADDING" "SPACING" "MAX_LINES" "MODE"
        set             [KEY]=[VALUE]
        show
    help:               Print this message
    profile:            Manage sets of arts, configs and commands
        To be implemented
EOF
}

if [[ "$1" == "art" ]]; then
    if [[ "$2" == "add" ]]; then
        import "$3"
        process
        exit 0
    fi
    if [[ "$2" == "remove" ]]; then
        rm ${HOME}/.cloud/art/$3
        process
        exit 0
    fi
    if [[ "$2" == "view" ]]; then
        cat ${HOME}/.cloud/art/$3
        exit 0
    fi
    if [[ "$2" == "list" ]]; then
        ls ${HOME}/.cloud/art
        process
        exit 0
    fi
fi

if [[ "$1" == "command" ]]; then
    if [[ "$2" == "add" ]]; then
        set_command "$3"
        exit 0
    fi
    if [[ "$2" == "remove" ]]; then
        rm ${HOME}/.cloud/${3}_wrapper.sh
        exit 0
    fi
    if [[ "$2" == "list" ]]; then
        echo -e "$CLOUD_COMMANDS"
        exit 0
    fi
fi

if [[ "$1" == "config" ]]; then
    if [[ "$2" == "set" ]]; then
        set_config "$3"
        exit 0
    fi
    if [[ "$2" == "show" ]]; then
        cat ${HOME}/.cloud/cloudrc
        exit 0
    fi
fi

if [[ "$1" == "help" ]]; then
    help
    exit 0
fi

help
exit 1
