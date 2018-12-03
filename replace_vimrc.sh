#!/bin/bash

if [[ ! -f `pwd`/vimrc ||  ! -d `pwd`/vimsources ]]; then
	echo "script should be ran from the same directory"
	echo "with .vimrc and vimsources"
	exit 2
fi

if [[ -f ~/.vimrc || -h ~/.vimrc ]]; then
	echo ".vimrc file found"
	rm -i ~/.vimrc
	if [[ -f ~/.vimrc ]]; then
		exit 1
	fi
fi

if [[ -d ~/.vim/plugin || -h ~/.vim/plugin ]]; then
    	echo ".vim/plugin folder found"
	rm -ir ~/.vim/plugin
	if [[ -d ~/.vim/plugin ]]; then
	    exit 1
	fi
elif [[ ! -d ~/.vim ]]; then
    mkdir ~/.vim
fi

rm -rf ~/vimsources

echo "creating symlinks"
ln -s `pwd`/vimrc ~/.vimrc
ln -s `pwd`/vimsources ~/

# create symlinks for all files in .vim dir
for dir in `pwd`/vim/*; do
	if [[ -h ~/.vim/`basename $dir` ]]; then
		rm ~/.vim/`basename $dir`
	fi
	ln -s ${dir} ~/.vim/`basename $dir`
done

if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
    echo "Installing Vundle (Vim Plugin manager)"
    git clone https://github.com/VundleVim/Vundle.vim.git \
	~/.vim/bundle/Vundle.vim
fi

echo ".vimrc file replaced"
