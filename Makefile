.DEFAULT_GOAL := tangle
.PHONY: tangle simulate install clean checkout test

test:
	python3 tests/test_upgrade_scripts.py -v

tangle:
	emacs -Q --script ./tangle-dotfiles.el
simulate:
	stow -v -R -n --no-folding -t ~ .
install:
	stow -v -R --no-folding -t ~ .
clean:
	stow -v -t ~ -D .
checkout:
	mr -v -d ~ checkout
