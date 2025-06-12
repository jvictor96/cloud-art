#!/bin/bash

if command -v cloud 2>&1 > /dev/null; then
    echo "no need to install"
    exit 0
fi

CLOUDDIR=$HOME/.cloud

mkdir -p $BINDIR $CLOUDDIR/art $CLOUDDIR/left_art
cp cloudrc $CLOUDDIR/cloudrc
install -m 755 cloud.sh $CLOUDDIR/cloud
install -m 755 cloud_left.sh $CLOUDDIR/cloud_left
install -m 755 cloudcfg.sh $CLOUDDIR/cloudcfg

if command -v zsh 2>&1 > /dev/null; then
    echo 'export PATH=$PATH:'$CLOUDDIR >> $HOME/.zshrc
else
    echo 'export PATH=$PATH:'$CLOUDDIR >> $HOME/.bashrc
fi

echo -e 'use \033[0;31m export PATH=$PATH:'$CLOUDDIR' \033[0m to activate it, or restart the shell'
echo -e 'suggestion: start with \033[0;31m cloudcfg art add art/borderDemo \033[0m and \033[0;31m cloudcfg command add ls \033[0m when the command line is ready. then rum ls'