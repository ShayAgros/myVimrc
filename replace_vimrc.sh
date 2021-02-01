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
	ln -fs ~/.vim/coc-settings.json ~/.config/nvim/coc-settings.json

	VIM=nvim
fi

echo ".vimrc file replaced"
echo "Installing Plugins with ${VIM}"

if which nvim >/dev/null 2>&1; then
	nvim --headless +PlugInstall +qa
	coc_extensions=$(nvim --headless +'call PrintCocExtensions()'  +qa 2>&1)
	# install CoC extensions if there are any
	if [[ ! -z ${coc_extensions// } ]]; then
		echo instaling coc extensions ${coc_extensions}
		mkdir -p ~/.config/coc
		eval nvim --headless +\"CocInstall -sync ${coc_extensions}\" +qall
		nvim --headless +CocUpdateSync +qall
	fi
else
	vim +PlugInstall +qa
fi

echo "Notice that yarn, nodejs, python-language-server packages need
		to be installed for CoC to work"
