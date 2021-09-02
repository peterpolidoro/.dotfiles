;; NOTE: init.el is generated from Emacs.org.  Please edit that file
;;       in Emacs and init.el will be generated automatically!

(setq user-full-name "Peter Polidoro"
			user-mail-address "peterpolidoro@gmail.com")

;; Adjust this font size for each system
(defvar pjp/default-font-size 120)
(defvar pjp/default-variable-font-size 120)

;; Make frame transparency overridable
(defvar pjp/frame-transparency '(95 . 95))

;;(require 'loadhist)
;;(file-dependents (feature-file 'cl))
(setq byte-compile-warnings '(cl-functions))

;; The default is 800 kilobytes.  Measured in bytes.
(setq gc-cons-threshold (* 50 1000 1000))

;; Profile emacs startup
(add-hook 'emacs-startup-hook
					(lambda ()
						(message "*** Emacs loaded in %s with %d garbage collections."
										 (format "%.2f seconds"
														 (float-time
															(time-subtract after-init-time before-init-time)))
										 gcs-done)))

(eval-when-compile
	(require 'use-package))
(require 'diminish)
(require 'bind-key)

;; Bootstrap straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
			 (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
			(bootstrap-version 5))
	(unless (file-exists-p bootstrap-file)
		(with-current-buffer
				(url-retrieve-synchronously
				 "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
				 'silent 'inhibit-cookies)
			(goto-char (point-max))
			(eval-print-last-sexp)))
	(load bootstrap-file nil 'nomessage))

;; Use straight.el for use-package expressions
(straight-use-package 'use-package)

;; Keep transient cruft out of ~/.emacs.d/
(setq user-emacs-directory "~/.cache/emacs/"
			backup-directory-alist `(("." . ,(expand-file-name "backups" user-emacs-directory)))
			url-history-file (expand-file-name "url/history" user-emacs-directory)
			auto-save-list-file-prefix (expand-file-name "auto-save-list/.saves-" user-emacs-directory)
			projectile-known-projects-file (expand-file-name "projectile-bookmarks.eld" user-emacs-directory))

;; Use no-littering to automatically set common paths to the new user-emacs-directory
(use-package no-littering)

;; Keep customization settings in a temporary file
(setq custom-file
			(if (boundp 'server-socket-dir)
					(expand-file-name "custom.el" server-socket-dir)
				(expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)

;; Add my library path to load-path
(push "~/.dotfiles/.emacs.d/lisp" load-path)

(server-start)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(use-package which-key
	:init (which-key-mode)
	:diminish which-key-mode
	:config
	(setq which-key-idle-delay 0.3))

;; Thanks, but no thanks
(setq inhibit-startup-message t)

(scroll-bar-mode -1)        ; Disable visible scrollbar
(tool-bar-mode -1)          ; Disable the toolbar
(tooltip-mode -1)           ; Disable tooltips
(set-fringe-mode 10)        ; Give some breathing room

(menu-bar-mode -1)            ; Disable the menu bar

;; Set up the visible bell
(setq visible-bell t)

(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))) ;; one line at a time
(setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
(setq mouse-wheel-follow-mouse 't) ;; scroll window under mouse
(setq scroll-step 1)

(set-frame-parameter (selected-frame) 'alpha pjp/frame-transparency)
(add-to-list 'default-frame-alist `(alpha . ,pjp/frame-transparency))
(set-frame-parameter (selected-frame) 'fullscreen 'maximized)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(column-number-mode)

;; Enable line numbers for some modes
(dolist (mode '(text-mode-hook
								prog-mode-hook
								conf-mode-hook))
	(add-hook mode (lambda () (display-line-numbers-mode 1))))

;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
								term-mode-hook
								shell-mode-hook
								treemacs-mode-hook
								eshell-mode-hook))
	(add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq large-file-warning-threshold nil)

(setq vc-follow-symlinks t)

(setq ad-redefinition-action 'accept)

(setq kill-whole-line t)

(setq-default fill-column 80)

(add-hook 'prog-mode-hook 'subword-mode)

(add-hook 'after-save-hook
					'executable-make-buffer-file-executable-if-script-p)

(setq sentence-end-double-space nil)

(add-hook 'before-save-hook
					(lambda ()
						(when buffer-file-name
							(let ((dir (file-name-directory buffer-file-name)))
								(when (and (not (file-exists-p dir))
													 (y-or-n-p (format "Directory %s does not exist. Create it?" dir)))
									(make-directory dir t))))))

(transient-mark-mode t)

(delete-selection-mode t)

(global-auto-revert-mode t)

(setq mouse-yank-at-point t)

(setq require-final-newline t)

(fset 'yes-or-no-p 'y-or-n-p)

(setq confirm-kill-emacs 'y-or-n-p)

(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
;; backwards compatibility as default-buffer-file-coding-system
;; is deprecated in 23.2.
(if (boundp 'buffer-file-coding-system)
		(setq-default buffer-file-coding-system 'utf-8)
	(setq default-buffer-file-coding-system 'utf-8))

;; Treat clipboard input as UTF-8 string first; compound text next, etc.
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

(use-package smartparens
	:config
	(smartparens-global-mode t)

	(sp-pair "'" nil :actions :rem)
	(sp-pair "`" nil :actions :rem)
	(setq sp-highlight-pair-overlay nil))

(set-default 'truncate-lines t)
(setq truncate-partial-width-windows t)

(setq-default tab-width 2)

(global-set-key (kbd "s-b")  'windmove-left)
(global-set-key (kbd "s-f") 'windmove-right)
(global-set-key (kbd "s-p")    'windmove-up)
(global-set-key (kbd "s-n")  'windmove-down)

(load-theme 'euphoria t t)
(enable-theme 'euphoria)
(setq color-theme-is-global t)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)

(set-face-attribute 'default nil :font "Fira Code Retina" :height pjp/default-font-size)

;; Set the fixed pitch face
(set-face-attribute 'fixed-pitch nil :font "Fira Code Retina" :height pjp/default-font-size)

;; Set the variable pitch face
(set-face-attribute 'variable-pitch nil :font "Cantarell" :height pjp/default-variable-font-size :weight 'regular)

(defun pjp/replace-unicode-font-mapping (block-name old-font new-font)
	(let* ((block-idx (cl-position-if
										 (lambda (i) (string-equal (car i) block-name))
										 unicode-fonts-block-font-mapping))
				 (block-fonts (cadr (nth block-idx unicode-fonts-block-font-mapping)))
				 (updated-block (cl-substitute new-font old-font block-fonts :test 'string-equal)))
		(setf (cdr (nth block-idx unicode-fonts-block-font-mapping))
					`(,updated-block))))

(use-package unicode-fonts
	:disabled
	:custom
	(unicode-fonts-skip-font-groups '(low-quality-glyphs))
	:config
	;; Fix the font mappings to use the right emoji font
	(mapcar
	 (lambda (block-name)
		 (pjp/replace-unicode-font-mapping block-name "Apple Color Emoji" "Noto Color Emoji"))
	 '("Dingbats"
		 "Emoticons"
		 "Miscellaneous Symbols and Pictographs"
		 "Transport and Map Symbols"))
	(unicode-fonts-setup))

(use-package emojify
	:hook (erc-mode . emojify-mode)
	:commands emojify-mode)

(use-package all-the-icons)

(use-package minions
	:hook (doom-modeline-mode . minions-mode))

(use-package doom-modeline
	:after eshell     ;; Make sure it gets hooked after eshell
	:hook (after-init . doom-modeline-init)
	:custom-face
	(mode-line ((t (:height 0.85))))
	(mode-line-inactive ((t (:height 0.85))))
	:custom
	(doom-modeline-height 15)
	(doom-modeline-bar-width 6)
	(doom-modeline-lsp t)
	(doom-modeline-github nil)
	(doom-modeline-mu4e nil)
	(doom-modeline-irc t)
	(doom-modeline-minor-modes t)
	(doom-modeline-persp-name nil)
	(doom-modeline-buffer-file-name-style 'truncate-except-project)
	(doom-modeline-major-mode-icon nil))

(setq display-time-format "%l:%M %p %b %y"
			display-time-default-load-average nil)

(use-package diminish)

(use-package alert
	:commands alert
	:config
	(setq alert-default-style 'notifications))

(use-package super-save
	:defer 1
	:diminish super-save-mode
	:config
	(super-save-mode +1)
	(setq super-save-auto-save-when-idle t))

(global-auto-revert-mode 1)

(use-package paren
	:config
	(set-face-attribute 'show-paren-match-expression nil :background "#363e4a")
	(show-paren-mode 1))

(setq display-time-world-list
			'(("America/Los_Angeles" "California")
				("America/New_York" "New York")
				("Europe/Athens" "Athens")
				("Pacific/Auckland" "Auckland")
				("Asia/Shanghai" "Shanghai")))
(setq display-time-world-time-format "%a, %d %b %I:%M %p %Z")

;; Set default connection mode to SSH
(setq tramp-default-method "ssh")

(use-package hydra
	:defer 1)

(defhydra hydra-zoom (global-map "C-=")
	"zoom"
	("=" text-scale-increase "in")
	("-" text-scale-decrease "out"))

(use-package ivy
	:diminish
	:bind (("C-s" . swiper))
	:init
	(ivy-mode 1)
	:config
	(setq ivy-use-virtual-buffers t)
	(setq ivy-wrap t)
	(setq ivy-count-format "(%d/%d) ")
	(setq enable-recursive-minibuffers t)

	;; Use different regex strategies per completion command
	(push '(completion-at-point . ivy--regex-fuzzy) ivy-re-builders-alist) ;; This doesn't seem to work...
	(push '(swiper . ivy--regex-ignore-order) ivy-re-builders-alist)
	(push '(counsel-M-x . ivy--regex-ignore-order) ivy-re-builders-alist)

	;; Set minibuffer height for different commands
	(setf (alist-get 'counsel-projectile-ag ivy-height-alist) 15)
	(setf (alist-get 'counsel-projectile-rg ivy-height-alist) 15)
	(setf (alist-get 'swiper ivy-height-alist) 15)
	(setf (alist-get 'counsel-switch-buffer ivy-height-alist) 7))

(use-package ivy-hydra
	:defer t
	:after hydra)

(use-package ivy-rich
	:init
	(ivy-rich-mode 1)
	:after counsel
	:config
	(setq ivy-format-function #'ivy-format-function-line)
	(setq ivy-rich-display-transformers-list
				(plist-put ivy-rich-display-transformers-list
									 'ivy-switch-buffer
									 '(:columns
										 ((ivy-rich-candidate (:width 40))
											(ivy-rich-switch-buffer-indicators (:width 4 :face error :align right)); return the buffer indicators
											(ivy-rich-switch-buffer-major-mode (:width 12 :face warning))          ; return the major mode info
											(ivy-rich-switch-buffer-project (:width 15 :face success))             ; return project name using `projectile'
											(ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))))))  ; return file path relative to project root or `default-directory' if project is nil
										 :predicate
										 (lambda (cand)
											 (if-let ((buffer (get-buffer cand)))
													 ;; Don't mess with EXWM buffers
													 (with-current-buffer buffer
														 (not (derived-mode-p 'exwm-mode)))))))))

(use-package counsel
	:demand t
	:bind (("M-x" . counsel-M-x)
				 ("C-x b" . counsel-ibuffer)
				 ("C-x C-f" . counsel-find-file)
				 ("C-M-l" . counsel-imenu)
				 ([remap describe-function] . counsel-describe-function)
				 ([remap describe-variable] . counsel-describe-variable)
				 :map minibuffer-local-map
				 ("C-r" . 'counsel-minibuffer-history))
	:custom
	(counsel-linux-app-format-function #'counsel-linux-app-format-function-name-only)
	:config
	(setq ivy-initial-inputs-alist nil) ;; Don't start searches with ^
	(counsel-mode 1))

(use-package flx  ;; Improves sorting for fuzzy-matched results
	:after ivy
	:defer t
	:init
	(setq ivy-flx-limit 10000))

(use-package smex ;; Adds M-x recent command sorting for counsel-M-x
	:defer 1
	:after counsel)

(use-package wgrep)

(use-package ivy-posframe
	:custom
	(ivy-posframe-width      115)
	(ivy-posframe-min-width  115)
	(ivy-posframe-height     10)
	(ivy-posframe-min-height 10)
	:config
	(setq ivy-posframe-display-functions-alist '((t . ivy-posframe-display-at-frame-center)))
	(setq ivy-posframe-parameters '((parent-frame . nil)
																	(left-fringe . 8)
																	(right-fringe . 8)))
	(ivy-posframe-mode 1))

(use-package prescient
	:after counsel
	:config
	(prescient-persist-mode 1))

(use-package ivy-prescient
	:after prescient
	:config
	(ivy-prescient-mode 1))

(use-package helpful
	:custom
	(counsel-describe-function-function #'helpful-callable)
	(counsel-describe-variable-function #'helpful-variable)
	:bind
	([remap describe-function] . counsel-describe-function)
	([remap describe-command] . helpful-command)
	([remap describe-variable] . counsel-describe-variable)
	([remap describe-key] . helpful-key)
	("C-." . helpful-at-point)
	("C-h c". helpful-command))

(defvar pjp/help-buffers '("^\\*Help\\*$"
													 "^\\*helpful"))

(while pjp/help-buffers
	(add-to-list 'display-buffer-alist
							 `(,(car pjp/help-buffers)
								 (display-buffer-pop-up-frame)
								 ))
	(setq pjp/help-buffers (cdr pjp/help-buffers)))

(use-package avy
	:commands (avy-goto-char avy-goto-word-0 avy-goto-line))

(use-package avy
	:bind (("C-:" . avy-goto-char)
				 ("C-;" . avy-goto-char-2)
				 ("M-g f" . avy-goto-line)
				 ("M-g w" . avy-goto-word-1)
				 ("M-g e" . avy-goto-word-0)))

(use-package expand-region
	:bind (("M-[" . er/expand-region)
				 ("M-]" . er/contract-region)
				 ("C-(" . er/mark-outside-pairs)
				 ("C-)" . er/mark-inside-pairs)))

(setq display-buffer-base-action
			'(display-buffer-reuse-mode-window
				display-buffer-reuse-window
				display-buffer-same-window))

;; If a popup does happen, don't resize windows to be equal-sized
(setq even-window-sizes nil)

(use-package dired
	:straight nil
	:defer 1
	:hook (dired-mode . dired-hide-details-mode)
	:bind (:map dired-mode-map
							("C-b" . dired-single-up-directory)
							("C-f" . dired-single-buffer))
	:commands (dired dired-jump)
	:config
	(setq dired-listing-switches "-agho --group-directories-first"
				dired-omit-verbose nil)

	(use-package all-the-icons-dired
		:hook (dired-mode . all-the-icons-dired-mode)))

(use-package dired-hide-dotfiles
	:hook (dired-mode . dired-hide-dotfiles-mode)
	:bind (:map dired-mode-map
							("." . dired-hide-dotfiles-mode)))

(use-package dired-single
	:straight t
	:after dired
	:bind (:map dired-mode-map
							("C-b" . dired-single-up-directory)
							("C-f" . dired-single-buffer)))

(use-package dired-subtree
	:straight t
	:after dired
	:bind (:map dired-mode-map
							("<tab>" . dired-subtree-cycle)))

(use-package dired-collapse
	:straight t
	:after dired
	:hook (dired-mode . dired-collapse-mode))

(use-package openwith
	:config
	(setq openwith-associations
				(list
				 (list (openwith-make-extension-regexp
								'("mpg" "mpeg" "mp3" "mp4"
									"avi" "wmv" "wav" "mov" "flv"
									"ogm" "ogg" "mkv"))
							 "mpv"
							 '(file))
				 (list (openwith-make-extension-regexp
								'("xbm" "pbm" "pgm" "ppm" "pnm"
									"png" "gif" "bmp" "tif" "jpeg")) ;; Removed jpg because Telega was
							 ;; causing feh to be opened...
							 "feh"
							 '(file))
				 (list (openwith-make-extension-regexp
								'("pdf"))
							 "zathura"
							 '(file))))
	(openwith-mode 1))

;; Turn on indentation and auto-fill mode for Org files
(defun pjp/org-mode-setup ()
	(variable-pitch-mode 1)
	(auto-fill-mode 0))

;; Make sure Straight pulls Org from Guix
(straight-use-package '(org :type built-in))

(use-package org
	:defer t
	:hook (org-mode . pjp/org-mode-setup)
	:config
	(setq org-src-fontify-natively t
				org-src-tab-acts-natively t
				org-edit-src-content-indentation 2
				org-hide-block-startup nil
				org-src-preserve-indentation nil
				org-startup-folded 'content
				org-descriptive-links nil
				org-cycle-separator-lines 2)

	(setq org-modules
				'(org-crypt
					org-habit
					org-bookmark
					org-eshell
					org-irc))

	(setq org-refile-targets '((nil :maxlevel . 1)
														 (org-agenda-files :maxlevel . 1)))

	(setq org-outline-path-complete-in-steps nil)
	(setq org-refile-use-outline-path t)

	(org-babel-do-load-languages
	 'org-babel-load-languages
	 '((emacs-lisp . t)
		 (shell . t)
		 (python . t)
		 (ledger . t)))

	(push '("conf-unix" . conf-unix) org-src-lang-modes)

	;; NOTE: Subsequent sections are still part of this use-package block!

;; Since we don't want to disable org-confirm-babel-evaluate all
;; of the time, do it around the after-save-hook
(defun pjp/org-babel-tangle-dont-ask ()
	;; Dynamic scoping to the rescue
	(let ((org-confirm-babel-evaluate nil))
		(org-babel-tangle)))

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'pjp/org-babel-tangle-dont-ask
																							'run-at-end 'only-in-org-mode)))

(dolist (face '((org-level-1 . 1.2)
								(org-level-2 . 1.1)
								(org-level-3 . 1.05)
								(org-level-4 . 1.0)
								(org-level-5 . 1.1)
								(org-level-6 . 1.1)
								(org-level-7 . 1.1)
								(org-level-8 . 1.1)))
	(set-face-attribute (car face) nil :font "Cantarell" :weight 'regular :height (cdr face)))

;; Make sure org-indent face is available
(require 'org-indent)

;; Ensure that anything that should be fixed-pitch in Org files appears that way
(set-face-attribute 'org-block nil    :foreground nil :inherit 'fixed-pitch)
(set-face-attribute 'org-table nil    :inherit 'fixed-pitch)
(set-face-attribute 'org-formula nil  :inherit 'fixed-pitch)
(set-face-attribute 'org-code nil     :inherit '(shadow fixed-pitch))
(set-face-attribute 'org-table nil    :inherit '(shadow fixed-pitch))
(set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
(set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
(set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
(set-face-attribute 'org-checkbox nil  :inherit 'fixed-pitch)

;; This is needed as of Org 9.2
(require 'org-tempo)

(add-to-list 'org-structure-template-alist '("sh" . "src sh"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
(add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))
(add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
(add-to-list 'org-structure-template-alist '("json" . "src json"))

;; This ends the use-package org-mode block
)

(setq org-src-fontify-natively t
			org-src-tab-acts-natively t)

(setq org-descriptive-links nil)

(eval-after-load "org"
	'(require 'ox-org nil t))

(eval-after-load "org"
	'(require 'ox-md nil t))

(eval-after-load "org"
	'(require 'ox-gfm nil t))

(defun org-include-img-from-pdf (&rest _)
	"Convert pdf files to image files in org-mode bracket links.

							# ()convertfrompdf:t # This is a special comment; tells that the upcoming
																	 # link points to the to-be-converted-to file.
							# If you have a foo.pdf that you need to convert to foo.png, use the
							# foo.png file name in the link.
							[[./foo.png]]
					"
	(interactive)
	(if (executable-find "convert")
			(save-excursion
				(goto-char (point-min))
				(while (re-search-forward "^[ \t]*#\\s-+()convertfrompdf\\s-*:\\s-*t"
																	nil :noerror)
					;; Keep on going to the next line till it finds a line with bracketed
					;; file link.
					(while (progn
									 (forward-line 1)
									 (not (looking-at org-bracket-link-regexp))))
					;; Get the sub-group 1 match, the link, from `org-bracket-link-regexp'
					(let ((link (match-string-no-properties 1)))
						(when (stringp link)
							(let* ((imgfile (expand-file-name link))
										 (pdffile (expand-file-name
															 (concat (file-name-sans-extension imgfile)
																			 "." "pdf")))
										 (cmd (concat "convert -density 96 -quality 85 "
																	pdffile " " imgfile)))
								(when (and (file-readable-p pdffile)
													 (file-newer-than-file-p pdffile imgfile))
									;; This block is executed only if pdffile is newer than
									;; imgfile or if imgfile does not exist.
									(shell-command cmd)
									(message "%s" cmd)))))))
		(user-error "`convert' executable (part of Imagemagick) is not found")))

;; (defun my/org-include-img-from-pdf-before-save ()
;;   "Execute `org-include-img-from-pdf' just before saving the file."
;;     (add-hook 'before-save-hook #'org-include-img-from-pdf nil :local))
;; (add-hook 'org-mode-hook #'my/org-include-img-from-pdf-before-save)

;; If you want to attempt to auto-convert PDF to PNG  only during exports, and not during each save.
(with-eval-after-load 'ox
	(add-hook 'org-export-before-processing-hook #'org-include-img-from-pdf))

(defconst help/org-special-pre "^\s*#[+]")
(defun help/org-2every-src-block (fn)
	"Visit every Source-Block and evaluate `FN'."
	(interactive)
	(save-excursion
		(goto-char (point-min))
		(let ((case-fold-search t))
			(while (re-search-forward (concat help/org-special-pre "BEGIN_SRC") nil t)
				(let ((element (org-element-at-point)))
					(when (eq (org-element-type element) 'src-block)
						(funcall fn element)))))
		(save-buffer)))
;;(define-key org-mode-map (kbd "M-]") (lambda () (interactive)
;;																			 (help/org-2every-src-block
;;																				'org-babel-remove-result)))

(defun pjp/lsp-mode-setup ()
	(setq lsp-headerline-breadcrumb-segments '(path-up-to-project file symbols))
	(lsp-headerline-breadcrumb-mode))

(use-package lsp-mode
	:commands (lsp lsp-deferred)
	:hook (lsp-mode . pjp/lsp-mode-setup)
	:init
	(setq lsp-keymap-prefix "s-l")  ;; Or 'C-l', 'C-c l'
	:config
	(lsp-enable-which-key-integration t))

(use-package lsp-ui
	:hook (lsp-mode . lsp-ui-mode)
	:custom
	(lsp-ui-doc-position 'bottom))

(use-package lsp-treemacs
	:after lsp)

(use-package lsp-ivy
	:commands lsp-ivy-workspace-symbol)

(use-package dap-mode
	:straight t
	:commands dap-mode
	:hook (dap-stopped . (lambda (arg) (call-interactively #'dap-hydra)))
	:config
	(dap-mode 1)
	(require 'dap-ui)
	(dap-ui-mode 1)
	(require 'dap-lldb))

(use-package company
	:defer t
	:init (global-company-mode)
	:config
	(progn
		;; Use Company for completion
		(bind-key [remap completion-at-point] #'company-complete company-mode-map)

		(setq company-tooltip-align-annotations t
					;; Easy navigation to candidates with M-<n>
					company-show-numbers t)
		(setq company-dabbrev-downcase nil))
	:diminish company-mode)

(use-package magit
	:commands (magit-status magit-get-current-branch)
	:diminish magit-auto-revert-mode
	:bind (("C-x g" . magit-status))
	:config
	(progn
		(setq magit-completing-read-function 'ivy-completing-read)
		(setq magit-item-highlight-face 'bold))
	:custom
	(magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(use-package forge
	:disabled)

(use-package magit-todos
	:defer t)

(use-package projectile
	:diminish projectile-mode
	:config (projectile-mode)
	:bind-keymap
	("C-c p" . projectile-command-map)
	:init
	(when (file-directory-p "~/git")
		(setq projectile-project-search-path '("~/git")))
	(setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
	:disabled
	:after projectile
	:config
	(counsel-projectile-mode))



;; (use-package dap-mode
;;   :straight t
;;   :hook (lsp-mode . dap-mode)
;;   :config
;;   (dap-ui-mode 1)
;;   (dap-tooltip-mode 1)
;;   (require 'dap-node)
;;   (dap-node-setup)

;;   (dap-register-debug-template "Node: Attach"
;;     (list :type "node"
;;           :cwd nil
;;           :request "attach"
;;           :program nil
;;           :port 9229
;;           :name "Node::Run")))

(use-package nvm
	:defer t)

(use-package typescript-mode
	:mode "\\.ts\\'"
	:config
	(setq typescript-indent-level 2))

(setq js-indent-level 2)
(setq js2-basic-offset 2)
(setq js2-mode-show-strict-warnings nil)

(use-package js2-mode
	:mode "\\.jsx?\\'"
	:config
	;; Use js2-mode for Node scripts
	(add-to-list 'magic-mode-alist '("#!/usr/bin/env node" . js2-mode)))

(use-package prettier-js
	:hook ((js2-mode . prettier-js-mode)
				 (typescript-mode . prettier-js-mode))
	:config
	(setq prettier-js-show-errors nil))

;; (use-package ccls
;;   :hook ((c-mode c++-mode objc-mode cuda-mode) .
;;          (lambda () (require 'ccls) (lsp))))

;; Unfortunately many standard c++ header files have no file
;; extension, and so will not typically be identified by emacs as c++
;; files. The following code is intended to solve this problem.
;; (require 'cl)

(defun file-in-directory-list-p (file dirlist)
	"Returns true if the file specified is contained within one of
		the directories in the list. The directories must also exist."
	(let ((dirs (mapcar 'expand-file-name dirlist))
				(filedir (expand-file-name (file-name-directory file))))
		(and
		 (file-directory-p filedir)
		 (member-if (lambda (x) ; Check directory prefix matches
									(string-match (substring x 0 (min(length filedir) (length x))) filedir))
								dirs))))

(defun buffer-standard-include-p ()
	"Returns true if the current buffer is contained within one of
		the directories in the INCLUDE environment variable."
	(and (getenv "INCLUDE")
			 (file-in-directory-list-p buffer-file-name (split-string (getenv "INCLUDE") path-separator))))

(add-to-list 'magic-fallback-mode-alist '(buffer-standard-include-p . c++-mode))

;; function decides whether .h file is C or C++ header, sets C++ by
;; default because there's more chance of there being a .h without a
;; .cc than a .h without a .c (ie. for C++ template files)
(defun c-c++-header ()
	"sets either c-mode or c++-mode, whichever is appropriate for
		header"
	(interactive)
	(let ((c-file (concat (substring (buffer-file-name) 0 -1) "c")))
		(if (file-exists-p c-file)
				(c-mode)
			(c++-mode))))
(add-to-list 'auto-mode-alist '("\\.h\\'" . c-c++-header))
;; and if that doesn't work, a function to toggle between c-mode and
;; c++-mode
(defun c-c++-toggle ()
	"toggles between c-mode and c++-mode"
	(interactive)
	(cond ((string= major-mode "c-mode")
				 (c++-mode))
				((string= major-mode "c++-mode")
				 (c-mode))))

(add-to-list 'auto-mode-alist '("\\.ino\\'" . c++-mode))

;; ROS style formatting
(defun ROS-c-mode-hook()
	(setq c-basic-offset 2)
	(setq indent-tabs-mode nil)
	(c-set-offset 'substatement-open 0)
	(c-set-offset 'innamespace 0)
	(c-set-offset 'case-label '+)
	(c-set-offset 'brace-list-open 0)
	(c-set-offset 'brace-list-intro '+)
	(c-set-offset 'brace-list-entry 0)
	(c-set-offset 'member-init-intro 0)
	(c-set-offset 'statement-case-open 0)
	(c-set-offset 'arglist-intro '+)
	(c-set-offset 'arglist-cont-nonempty '+)
	(c-set-offset 'arglist-close '+)
	(c-set-offset 'template-args-cont '+))
(add-hook 'c-mode-common-hook 'ROS-c-mode-hook)

(add-hook 'emacs-lisp-mode-hook #'flycheck-mode)

(use-package paredit
	:straight t
	:config
	(add-hook 'emacs-lisp-mode-hook #'paredit-mode)
	;; enable in the *scratch* buffer
	(add-hook 'lisp-interaction-mode-hook #'paredit-mode)
	(add-hook 'ielm-mode-hook #'paredit-mode)
	(add-hook 'lisp-mode-hook #'paredit-mode)
	(add-hook 'eval-expression-minibuffer-setup-hook #'paredit-mode))

(use-package markdown-mode
	:pin melpa-stable
	:mode "\\.md\\'"
	:config
	(setq markdown-command "marked")
	(defun pjp/set-markdown-header-font-sizes ()
		(dolist (face '((markdown-header-face-1 . 1.2)
										(markdown-header-face-2 . 1.1)
										(markdown-header-face-3 . 1.0)
										(markdown-header-face-4 . 1.0)
										(markdown-header-face-5 . 1.0)))
			(set-face-attribute (car face) nil :weight 'normal :height (cdr face))))

	(defun pjp/markdown-mode-hook ()
		(pjp/set-markdown-header-font-sizes))

	(add-hook 'markdown-mode-hook 'pjp/markdown-mode-hook))

(use-package web-mode
	:mode "(\\.\\(html?\\|ejs\\|tsx\\|jsx\\)\\'"
	:config
	(setq-default web-mode-code-indent-offset 2)
	(setq-default web-mode-markup-indent-offset 2)
	(setq-default web-mode-attribute-indent-offset 2))

;; 1. Start the server with `httpd-start'
;; 2. Use `impatient-mode' on any buffer
(use-package impatient-mode
	:straight t)

(use-package skewer-mode
	:straight t)

(use-package yaml-mode
	:mode "\\.ya?ml\\'")

(use-package flycheck
	:defer t
	:hook (lsp-mode . flycheck-mode))

(use-package yasnippet
	:hook (prog-mode . yas-minor-mode)
	:config
	(yas-reload-all))

(use-package smartparens
	:hook (prog-mode . smartparens-mode))

(use-package rainbow-delimiters
	:hook (prog-mode . rainbow-delimiters-mode))

(use-package rainbow-mode
	:defer t
	:hook (org-mode
				 emacs-lisp-mode
				 web-mode
				 typescript-mode
				 js2-mode))

(use-package term
	:config
	(setq explicit-shell-file-name "bash") ;; Change this to zsh, etc
	;;(setq explicit-zsh-args '())         ;; Use 'explicit-<shell>-args for shell-specific args

	;; Match the default Bash shell prompt.  Update this if you have a custom prompt
	(setq term-prompt-regexp "^[^#$%>\n]*[#$%>] *"))

(use-package eterm-256color
	:hook (term-mode . eterm-256color-mode))

(use-package vterm
	:commands vterm
	:config
	(setq term-prompt-regexp "^[^#$%>\n]*[#$%>] *")  ;; Set this to match your custom shell prompt
	;;(setq vterm-shell "zsh")                       ;; Set this to customize the shell to launch
	(setq vterm-max-scrollback 10000))

(when (eq system-type 'windows-nt)
	(setq explicit-shell-file-name "powershell.exe")
	(setq explicit-powershell.exe-args '()))

(defun pjp/configure-eshell ()
	;; Save command history when commands are entered
	(add-hook 'eshell-pre-command-hook 'eshell-save-some-history)

	;; Truncate buffer for performance
	(add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)

	(setq eshell-history-size         10000
				eshell-buffer-maximum-lines 10000
				eshell-hist-ignoredups t
				eshell-scroll-to-bottom-on-input t))

(use-package eshell-git-prompt)

(use-package eshell
	:hook (eshell-first-time-mode . pjp/configure-eshell)
	:config

	(with-eval-after-load 'esh-opt
		(setq eshell-destroy-buffer-when-process-dies t)
		(setq eshell-visual-commands '("htop")))

	(eshell-git-prompt-use-theme 'powerline))

;; Only fetch mail on knave
;; (setq pjp/mail-enabled (string-equal system-name "knave"))
(setq pjp/mail-enabled (string-equal system-name "test"))
(setq pjp/mu4e-inbox-query nil)
(when pjp/mail-enabled
	(require 'pjp-email))

(setq auto-mode-alist (cons '("\\.\\(pde\\|ino\\)$" . c++-mode) auto-mode-alist))
