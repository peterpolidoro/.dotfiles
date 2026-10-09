.DEFAULT_GOAL := tangle
.PHONY: tangle simulate install install-lxqt clean checkout test

test:
	python3 tests/test_upgrade_scripts.py -v
	python3 tests/test_guix_apparmor.py -v
	python3 tests/test_lxqt_settings.py -v

tangle:
	emacs -Q --script ./tangle-dotfiles.el
simulate:
	stow -v -R -n --no-folding -t ~ .
install:
	stow -v -R --no-folding -t ~ .
install-lxqt: install
	./.local/bin/setup-lxqt
clean:
	stow -v -t ~ -D .
checkout:
	mr -v -d ~ checkout
