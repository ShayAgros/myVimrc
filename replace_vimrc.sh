#!/bin/bash

VIM=vim

if ! which nvim >/dev/null 2>&1 ; then
    echo "nvim isn't installed. Not configuring"
    exit 1
fi

if [[ -d ~/.config/nvim || -h ~/.config/nvim ]]; then
    [[ -d ~/.config/nvim_prev || -h ~/.config/nvim_prev ]] && rm -rf ~/.config/nvim_prev
    mv ~/.config/nvim ~/.config/nvim_prev
fi

ln -fs `pwd`/nvim ~/.config/nvim

echo "Created nvim directory"

echo "Installing Plugins and Treesitter parsers with nvim"
nvim --headless "+Lazy! sync" +qa
