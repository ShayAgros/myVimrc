#!/bin/bash

if [[ ! -f `pwd`/vimrc ]]; then
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

# create symlinks for all files in .vim dir
for dir in `pwd`/vim/*; do
	if [[ -h ~/.vim/`basename $dir` ]]; then
		rm ~/.vim/`basename $dir`
	fi
	ln -s ${dir} ~/.vim/`basename $dir`
done

echo ".vimrc file replaced"
echo "Installing Plugins"
vim +PlugInstall +qa

echo "Notice that yarn, nodejs, python-language-server packages need
		to be installed for CoC to work"
