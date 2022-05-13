tangle:
	emacs -Q --script ./.emacs.d/tangle-dotfiles.el
simulate:
	stow -v -R -n --no-folding -t ~ .
install:
	stow -v -R --no-folding -t ~ .
clean:
	stow -v -t ~ -D .
checkout:
	mr -v -d ~ checkout
