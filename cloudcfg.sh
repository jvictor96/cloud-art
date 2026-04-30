#!/bin/bash

source ${HOME}/.cloud/cloudrc

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
    configs=("PADDING" "SPACING" "MAX_LINES")
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
	echo "$sizex $(wc -l $1 | cut -d" " --field 1) $1" >> "${DIMENSION_FILE}"
}

function process() {
    export -f get_dim_data
    rm -f "${DIMENSION_FILE}"
    find ${ART_FOLDER} -type f -exec bash -c 'get_dim_data $0' {} \;
}

function import() {
    cp $1 ${ART_FOLDER}
}

function help() {
cat << EOF
Usage: cloudcfg [COMMAND] [SUBCOMMAND] [ARGUMENTS]
Commands:
    art                 Manage ascii art files
        left
        add             [FILENAME]
        remove          [FILENAME]
        show            [FILENAME]
        list
    command:            Manage commands wapped by cloud. eg cat, ls, find
        add             [COMMAND]
        remove          [COMMAND]
        list
    config:             Manage configs. eg "PADDING" "SPACING" "MAX_LINES" "SKIP"
        set             [KEY]=[VALUE]
        show
        help
    help:               Print this message
EOF
}

if [[ "$1" == "art" ]]; then
    if [[ "$2" = "left" ]]; then
    export ART_FOLDER="${HOME}/.cloud/left_art"
    export DIMENSION_FILE="${HOME}/.cloud/left_dimensions"
    else
    export ART_FOLDER="${HOME}/.cloud/art"
    export DIMENSION_FILE="${HOME}/.cloud/dimensions"
    fi
    if [[ "$3" == "add" ]]; then
        import "$3"
        process
        exit 0
    fi
    if [[ "$3" == "remove" ]]; then
        rm ${ART_FOLDER}/$3
        process
        exit 0
    fi
    if [[ "$3" == "view" ]]; then
        cat ${ART_FOLDER}/$3
        exit 0
    fi
    ls ${ART_FOLDER}
    exit 0

fi

if [[ "$1" == "command" ]]; then
    if [[ "$2" == "add" ]]; then
        set_command "$3"
        echo "restart the shell to activate it"
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
    if [[ "$2" == "help" ]]; then
        echo "PADDING defines a horizontal padding"
        echo "SPACING defines a minimun space between arts"
        echo "MAX_LINES tells the algorithm to not run when the output is too long"
        echo "SKIP turns the algorithm on and off"
        exit 0
    fi
fi

if [[ "$1" == "help" ]]; then
    help
    exit 0
fi

help
exit 1
