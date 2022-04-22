#!/bin/bash

VIM=vim

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

# in neovim installed create a symlink for it too
if which nvim >/dev/null 2>&1; then
	mkdir -p ~/.config/nvim
	ln -fs ~/.vimrc ~/.config/nvim/init.vim

	VIM=nvim
fi

echo ".vimrc file replaced"
echo "Installing Plugins with ${VIM}"

curl --silent -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

if which nvim >/dev/null 2>&1; then
	nvim --headless +PlugInstall +qa
	# force TreeSitter to run TSUpdate.
	# For some cosmic reason it fails to do that in the first time
	# it installs the plugin
	nvim --headless +PlugInstall! +qa
else
	vim +PlugInstall +qa
fi
