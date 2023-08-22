;; NOTE: init.el is generated from Emacs.org.  Please edit that file
;;       in Emacs and init.el will be generated automatically!

(setq user-full-name "Peter Polidoro"
      user-mail-address "peter@polidoro.io")
(setq copyright-names-regexp
      (format "%s <%s>" user-full-name user-mail-address))

;; Adjust this font size for each system
(defvar pjp/default-font-size 120)
(defvar pjp/default-variable-font-size 120)

;; Make frame transparency overridable
(defvar pjp/frame-transparency '(95 . 95))

(setq warning-minimum-level :error)

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

(setq pjp/is-gnu (or (eq system-type 'gnu/linux) (eq system-type 'gnu)))
(setq pjp/is-guix-system (and pjp/is-gnu
                              (require 'f)
                              (string-equal (f-read "/etc/issue")
                                            "\nThis is the GNU system.  Welcome.\n")))

(if pjp/is-gnu
    (setq use-package-always-ensure nil)
  (require 'package)
  (setq package-archives '(("melpa" . "https://melpa.org/packages/")
												   ("melpa-stable" . "https://stable.melpa.org/packages/")
												   ("org" . "https://orgmode.org/elpa/")
												   ("elpa" . "https://elpa.gnu.org/packages/")))
  (package-initialize)
  (unless package-archive-contents
	  (package-refresh-contents))
  (unless (package-installed-p 'use-package)
	  (package-install 'use-package))
  (require 'use-package-ensure)
  (setq use-package-always-ensure t))

(eval-when-compile
  (require 'use-package))
;; (require 'diminish)
(require 'bind-key)

(add-hook 'scheme-mode-hook 'guix-devel-mode)

;; Keep transient cruft out of ~/.emacs.d/
(setq user-emacs-directory "~/.cache/emacs/"
      backup-directory-alist `(("." . ,(expand-file-name "backups" user-emacs-directory)))
      undo-tree-history-directory-alist `(("." . ,(expand-file-name "undo" user-emacs-directory)))
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

;; I use version control instead of backup files
(setq make-backup-files nil)

;; Add my library path to load-path
(push "~/.dotfiles/.emacs.d/lisp" load-path)

;; (server-start)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3))

(scroll-bar-mode -1)        ; Disable visible scrollbar
(tool-bar-mode -1)          ; Disable the toolbar

; Making tooltips appear in the echo area
(tooltip-mode -1)
(setq tooltip-use-echo-area t)

(set-fringe-mode 10)        ; Give some breathing room

(menu-bar-mode -1)            ; Disable the menu bar

;; Set up the visible bell
(setq visible-bell t)

(setq inhibit-startup-message t
      inhibit-startup-echo-area-message t)
(setq use-short-answers t)
(setq confirm-nonexistent-file-or-buffer nil)
(setq kill-buffer-query-functions
  (remq 'process-kill-buffer-query-function
         kill-buffer-query-functions))

(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))) ;; one line at a time
(setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
(setq mouse-wheel-follow-mouse 't) ;; scroll window under mouse
(setq scroll-step 1)

(set-frame-parameter (selected-frame) 'alpha pjp/frame-transparency)
(add-to-list 'default-frame-alist `(alpha . ,pjp/frame-transparency))
(set-frame-parameter (selected-frame) 'fullscreen 'maximized)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(setq switch-to-buffer-obey-display-actions t)

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

(global-visual-line-mode t)

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
(setq global-auto-revert-non-file-buffers t)

(setq mouse-yank-at-point t)

(setq require-final-newline t)

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

(if pjp/is-gnu
    (use-package undo-tree
      :init
      (global-undo-tree-mode 1)))

(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)
(setq-default frame-title-format "%b (%f)")

(defun pjp/kill-buffer ()
  (interactive)
  (catch 'quit
    (save-window-excursion
      (let (done)
        (when (and buffer-file-name (buffer-modified-p))
          (while (not done)
            (let ((response (read-char-choice
                             (format "Save file %s? (y, n, d, q) " (buffer-file-name))
                             '(?y ?n ?d ?q))))
              (setq done (cond
                          ((eq response ?q) (throw 'quit nil))
                          ((eq response ?y) (save-buffer) t)
                          ((eq response ?n) (set-buffer-modified-p nil) t)
                          ((eq response ?d) (diff-buffer-with-file) nil))))))
        (kill-buffer (current-buffer))))))

(global-set-key [remap kill-buffer] 'pjp/kill-buffer)

(load-theme 'euphoria t t)
(enable-theme 'euphoria)
(setq color-theme-is-global t)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)

(when pjp/is-gnu
  (set-face-attribute 'default nil :font "Fira Code Retina" :height pjp/default-font-size)

  ;; Set the fixed pitch face
  (set-face-attribute 'fixed-pitch nil :font "Fira Code Retina" :height pjp/default-font-size)

  ;; Set the variable pitch face
  (set-face-attribute 'variable-pitch nil :font "Iosevka Aile" :height pjp/default-variable-font-size :weight 'regular))

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

(global-auto-revert-mode 1)

(use-package paren
  :config
  (set-face-attribute 'show-paren-match-expression nil :background "#363e4a")
  (show-paren-mode))

(setq display-time-world-list
      '(("America/Los_Angeles" "California")
        ("America/New_York" "New York")
        ("Europe/Athens" "Athens")
        ("Pacific/Auckland" "Auckland")
        ("Asia/Shanghai" "Shanghai")))
(setq display-time-world-time-format "%a, %d %b %I:%M %p %Z")

(when pjp/is-gnu
  (setq epa-pinentry-mode 'loopback)
  (pinentry-start))

;; Set default connection mode to SSH
(setq tramp-default-method "ssh")

(defhydra hydra-zoom (global-map "C-=")
  "zoom"
  ("=" text-scale-increase "in")
  ("-" text-scale-decrease "out"))

(use-package helpful
  :bind
  ([remap describe-function] . helpful-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-key] . helpful-key)
  ;;("C-." . helpful-at-point)
  ("C-h c". helpful-command))

(defvar pjp/help-buffers '("^\\*Help\\*$"
                           "^\\*helpful"))

(while pjp/help-buffers
  (add-to-list 'display-buffer-alist
               `(,(car pjp/help-buffers)
                 (display-buffer-pop-up-frame)
                 ))
  (setq pjp/help-buffers (cdr pjp/help-buffers)))

(use-package hydra
  :defer 1)

(defun pjp/minibuffer-backward-kill (arg)
	"When minibuffer is completing a file name delete up to parent
		folder, otherwise delete a word"
	(interactive "p")
	(if minibuffer-completing-file-name
			;; Borrowed from https://github.com/raxod502/selectrum/issues/498#issuecomment-803283608
			(if (string-match-p "/." (minibuffer-contents))
					(zap-up-to-char (- arg) ?/)
				(delete-minibuffer-contents))
		(delete-word (- arg))))

(use-package vertico
	:bind (:map minibuffer-local-map
					    ("M-<backspace>" . pjp/minibuffer-backward-kill))
	:init
	(vertico-mode)

	;; Different scroll margin
	;; (setq vertico-scroll-margin 0)

	;; Show more candidates
	;; (setq vertico-count 20)

	;; Grow and shrink the Vertico minibuffer
	;; (setq vertico-resize t)

	;; Optionally enable cycling for `vertico-next' and `vertico-previous'.
	(setq vertico-cycle t))

(use-package emacs
	:init
	;; Add prompt indicator to `completing-read-multiple'.
	;; Alternatively try `consult-completing-read-multiple'.
	(defun crm-indicator (args)
		(cons (concat "[CRM] " (car args)) (cdr args)))
	(advice-add #'completing-read-multiple :filter-args #'crm-indicator)

	;; Do not allow the cursor in the minibuffer prompt
	(setq minibuffer-prompt-properties
				'(read-only t cursor-intangible t face minibuffer-prompt))
	(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

	;; Emacs 28: Hide commands in M-x which do not work in the current mode.
	;; Vertico commands are hidden in normal buffers.
	;; (setq read-extended-command-predicate
	;;       #'command-completion-default-include-p)

	;; Enable recursive minibuffers
	(setq enable-recursive-minibuffers t)

	;; TAB cycle if there are only few candidates
	(setq completion-cycle-threshold 3)

	;; Emacs 28: Hide commands in M-x which do not apply to the current mode.
	;; Corfu commands are hidden, since they are not supposed to be used via M-x.
	;; (setq read-extended-command-predicate
	;;       #'command-completion-default-include-p)

	;; Enable indentation+completion using the TAB key.
	;; `completion-at-point' is often bound to M-TAB.
	(setq tab-always-indent 'complete))

(use-package orderless
  :init
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (setq orderless-style-dispatchers '(+orderless-dispatch)
  ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  (setq completion-styles '(orderless)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(setq history-length 25)
(use-package savehist
  :init
  (savehist-mode))

(use-package corfu
  ;; Optional customizations
  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  ;; (corfu-auto t)                 ;; Enable auto completion
  ;; (corfu-commit-predicate nil)   ;; Do not commit selected candidates on next input
  ;; (corfu-quit-at-boundary t)     ;; Automatically quit at word boundary
  ;; (corfu-quit-no-match t)        ;; Automatically quit if there is no match
  ;; (corfu-preview-current nil)    ;; Disable current candidate preview
  (corfu-preselect-first nil)    ;; Disable candidate preselection
  ;; (corfu-echo-documentation nil) ;; Disable documentation in the echo area
  ;; (corfu-scroll-margin 5)        ;; Use scroll margin

  :bind
  (:map corfu-map
        ("TAB" . corfu-next)
        ([tab] . corfu-next)
        ("S-TAB" . corfu-previous)
        ([backtab] . corfu-previous))

  ;; You may want to enable Corfu only for certain modes.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))

  ;; Recommended: Enable Corfu globally.
  ;; This is recommended since dabbrev can be used globally (M-/).
  :init
  (global-corfu-mode))

(use-package consult
  ;; Replace bindings. Lazily loaded due by `use-package'.
  :bind (("C-s" . consult-line)
         ;; C-c bindings (mode-specific-map)
         ("C-c h" . consult-history)
         ("C-c m" . consult-mode-command)
         ("C-c k" . consult-kmacro)
         ;; C-x bindings (ctl-x-map)
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ("<help> a" . consult-apropos)            ;; orig. apropos-command
         ;; M-g bindings (goto-map)
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings (search-map)
         ("M-s d" . consult-find)
         ("M-s D" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s m" . consult-multi-occur)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi))           ;; needed by consult-line to detect isearch

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI. You may want to also
  ;; enable `consult-preview-at-point-mode` in Embark Collect buffers.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Optionally replace `completing-read-multiple' with an enhanced version.
  ;; (advice-add #'completing-read-multiple :override #'consult-completing-read-multiple)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key (kbd "M-."))
  ;; (setq consult-preview-key (list (kbd "<S-down>") (kbd "<S-up>")))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme
   :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-recent-file consult--source-project-recent-file consult--source-bookmark
   :preview-key "M-.")

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; (kbd "C-+")

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

  ;; Optionally configure a function which returns the project root directory.
  ;; There are multiple reasonable alternatives to chose from.
  ;;;; 1. project.el (project-roots)
  (setq consult-project-root-function
        (lambda ()
          (when-let (project (project-current))
            (car (project-roots project)))))
  ;;;; 2. projectile.el (projectile-project-root)
  ;; (autoload 'projectile-project-root "projectile")
  ;; (setq consult-project-root-function #'projectile-project-root)
  ;;;; 3. vc.el (vc-root-dir)
  ;; (setq consult-project-root-function #'vc-root-dir)
  ;;;; 4. locate-dominating-file
  ;; (setq consult-project-root-function (lambda () (locate-dominating-file "." ".git")))
  )

(use-package marginalia
  ;; Either bind `marginalia-cycle` globally or only in the minibuffer
  :bind (("M-A" . marginalia-cycle)
         :map minibuffer-local-map
         ("M-A" . marginalia-cycle))

  ;; The :init configuration is always executed (Not lazy!)
  :init

  ;; Must be in the :init section of use-package such that the mode gets
  ;; enabled right away. Note that this forces loading the package.
  (marginalia-mode))

(use-package embark
  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("M-." . embark-dwim)        ;; good alternative: C-;
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  :config

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Consult users will also want the embark-consult package.
(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t ; only necessary if you have the hook below
  ;; if you want to have consult previews as you move around an
  ;; auto-updating embark collect buffer
  :hook
  (embark-collect-mode . consult-preview-at-point-mode)
  )

(add-to-list 'completion-ignored-extensions ".go")

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

(setq-default indent-tabs-mode nil)

(setq-default show-trailing-whitespace t)
(dolist (hook '(special-mode-hook
                term-mode-hook
                comint-mode-hook
                compilation-mode-hook
                minibuffer-setup-hook))
  (add-hook hook
            (lambda () (setq show-trailing-whitespace nil))))

(use-package parinfer
  :disabled
  :hook ((clojure-mode . parinfer-mode)
         (emacs-lisp-mode . parinfer-mode)
         (common-lisp-mode . parinfer-mode)
         (scheme-mode . parinfer-mode)
         (lisp-mode . parinfer-mode))
  :config
  (setq parinfer-extensions
        '(defaults       ; should be included.
           pretty-parens  ; different paren styles for different modes.
           smart-tab      ; C-b & C-f jump positions and smart shift with tab & S-tab.
           smart-yank)))  ; Yank behavior depend on mode.

(use-package origami
  :hook (yaml-mode . origami-mode))

(setq display-buffer-base-action
      '(display-buffer-reuse-mode-window
        display-buffer-reuse-window
        display-buffer-same-window))

;; If a popup does happen, don't resize windows to be equal-sized
(setq even-window-sizes nil)

(use-package pass)

(setq auth-sources '(password-store))
(setq auth-source-debug t)
(setq auth-source-do-cache nil)
(setq auth-source-pass-filename "~/.password-store")

(use-package auth-source-pass
  :init (auth-source-pass-enable))

  (use-package dirvish
    :init
    (dirvish-override-dired-mode)
    :custom
    (dirvish-quick-access-entries ; It's a custom option, `setq' won't work
     '(("h" "~/" "Home")
       ("d" "~/Downloads/" "Downloads")
       ("." "~/.dotfiles/" "Dotfiles")
       ("a" "~/Repositories/arduino" "Arduino")
       ("g" "~/Repositories/guix" "Guix")
       ("k" "~/Repositories/kicad" "Kicad")
       ("o" "~/Repositories/peter/org" "Org")
       ("p" "~/Repositories/pypi" "Pypi")
       ("r" "~/Repositories/ros" "Ros")
       ))
    :config
    ;; (dirvish-peek-mode) ; Preview files in minibuffer
    ;; (dirvish-side-follow-mode) ; similar to `treemacs-follow-mode'
    ;; (setq dirvish-mode-line-format
    ;;       '(:left (sort symlink) :right (omit yank index)))
    ;; (setq dirvish-attributes
    ;;       '(all-the-icons file-time file-size collapse subtree-state vc-state git-msg))
    ;; (setq delete-by-moving-to-trash t)
    (setq dired-listing-switches
          "-l --almost-all --human-readable --group-directories-first --no-group")
    :bind ; Bind `dirvish|dirvish-side|dirvish-dwim' as you see fit
    (("C-c f" . dirvish-fd)
     :map dirvish-mode-map ; Dirvish inherits `dired-mode-map'
     ("a"   . dirvish-quick-access)
     ("f"   . dirvish-file-info-menu)
     ("y"   . dirvish-yank-menu)
     ("N"   . dirvish-narrow)
     ;; ("^"   . dirvish-history-last)
     ("h"   . dirvish-history-jump) ; remapped `describe-mode'
     ("s"   . dirvish-quicksort)    ; remapped `dired-sort-toggle-or-edit'
     ("v"   . dirvish-vc-menu)      ; remapped `dired-view-file'
     ("TAB" . dirvish-subtree-toggle)
     ("M-f" . dirvish-history-go-forward)
     ("M-b" . dirvish-history-go-backward)
     ("M-l" . dirvish-ls-switches-menu)
     ("M-m" . dirvish-mark-menu)
     ("M-t" . dirvish-layout-toggle)
     ("M-s" . dirvish-setup-menu)
     ("M-e" . dirvish-emerge-menu)
     ("M-j" . dirvish-fd-jump))
    )

;; (use-package openwith
;;   :config
;;   (setq openwith-associations
;;         (list
;;          (list (openwith-make-extension-regexp
;;                 '("mpg" "mpeg" "mp3" "mp4"
;;                   "avi" "wmv" "wav" "mov" "flv"
;;                   "ogm" "ogg" "mkv"))
;;                "mpv"
;;                '(file))
;;          (list (openwith-make-extension-regexp
;;                 '("xbm" "pbm" "pgm" "ppm" "pnm"
;;                   "png" "gif" "bmp" "tif" "jpeg")) ;; Removed jpg because Telega was
;;                ;; causing feh to be opened...
;;                "feh"
;;                '(file))
;;          (list (openwith-make-extension-regexp
;;                 '("pdf"))
;;                "zathura"
;;                '(file))))
;;   (openwith-mode 1))

(require 'rg)
(rg-enable-default-bindings)

(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "firefox")

(global-set-key (kbd "C-c l") #'dictionary-lookup-definition)

;; Turn on indentation and auto-fill mode for Org files
(defun pjp/org-mode-setup ()
  (org-indent-mode)
  (diminish org-indent-mode)
  (variable-pitch-mode 1)
  (auto-fill-mode 0)
  )

(use-package org
  :defer t
  :hook (org-mode . pjp/org-mode-setup)
  :config
  (setq org-ellipsis " ▾"
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-hide-block-startup nil
        org-src-preserve-indentation t
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
     (lisp . t)
     (shell . t)
     (python . t)
     (scheme . t)))

  (setq org-babel-python-command "python3")

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
  (set-face-attribute (car face) nil :font "Iosevka Aile" :weight 'regular :height (cdr face)))

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

(use-package org-roam
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory (file-truename "~/Repositories/peter/org/roam"))
  (org-roam-completion-everywhere t)
  (org-roam-completion-system 'default)
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ;; Dailies
         ("C-c n j" . org-roam-dailies-capture-today))
  :config
  (org-roam-db-autosync-mode)
  ;; If using org-roam-protocol
  (require 'org-roam-protocol))

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
;;                                                                                                                                                       (help/org-2every-src-block
;;                                                                                                                                                              'org-babel-remove-result)))

(use-package eglot)

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
  :bind (("C-c g" . magit-status))
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



(use-package ccls)

;; Unfortunately many standard c++ header files have no file
;; extension, and so will not typically be identified by emacs as c++
;; files. The following code is intended to solve this problem.
(require 'cl)

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
  :config
  (add-hook 'emacs-lisp-mode-hook #'enable-paredit-mode)
  (add-hook 'eval-expression-minibuffer-setup-hook #'enable-paredit-mode)
  (add-hook 'lisp-interaction-mode-hook #'enable-paredit-mode)
  (add-hook 'ielm-mode-hook #'enable-paredit-mode)
  (add-hook 'lisp-mode-hook #'enable-paredit-mode)
  (add-hook 'lisp-interaction-mode-hook #'enable-paredit-mode)
  (add-hook 'scheme-mode-hook #'enable-paredit-mode)
  )

;; TODO: This causes issues for some reason.
;; :bind (:map geiser-mode-map
;;        ("TAB" . completion-at-point))

(use-package geiser
  :config
  ;; (setq geiser-default-implementation 'gambit)
  (setq geiser-default-implementation 'guile)
  (setq geiser-active-implementations '(guile))
  (setq geiser-implementations-alist '(((regexp "\\.scm$") guile))))

(use-package markdown-mode
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
;; (use-package impatient-mode)

;; (use-package skewer-mode)

(use-package yaml-mode
  :mode "\\.ya?ml\\'")

(use-package flycheck
  :defer t)

(setq yas-snippet-dirs
      '("~/.emacs.d/snippets"
        "~/.emacs.d/snippets/guix"))
(yas-global-mode 1)

(use-package smartparens
  :hook (prog-mode . smartparens-mode))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(when pjp/is-gnu
  (use-package rainbow-mode
    :defer t
    :hook (org-mode
           emacs-lisp-mode
           web-mode
           typescript-mode
           js2-mode)))

(use-package csv)

(use-package csv-mode)

(use-package multi-term)

(use-package vterm
  :commands vterm
  :config
  (setq term-prompt-regexp "^[^#$%>\n]*[#$%>] *")  ;; Set this to match your custom shell prompt
  ;;(setq vterm-shell "zsh")                       ;; Set this to customize the shell to launch
  (setq vterm-max-scrollback 10000)
  (add-hook
   'vterm-mode-hook
   (lambda() (setq show-trailing-whitespace nil)))
  :bind (:map vterm-mode-map
              ("M-n" . multi-vterm-next)
              ("M-p" . multi-vterm-prev)))

(use-package multi-vterm)
(global-set-key (kbd "C-c v") 'multi-vterm)
(global-set-key (kbd "C-c d") 'multi-vterm-dedicated-toggle)

(defun pjp/vterm-execute-region-or-current-line ()
  "Insert text of current line in vterm and execute."
  (interactive)
  (require 'vterm)
  (eval-when-compile (require 'subr-x))
  (let ((command (if (region-active-p)
                     (string-trim (buffer-substring
                                   (save-excursion (region-beginning))
                                   (save-excursion (region-end))))
                   (string-trim (buffer-substring (save-excursion
                                                    (beginning-of-line)
                                                    (point))
                                                  (save-excursion
                                                    (end-of-line)
                                                    (point)))))))
    (let ((buf (current-buffer)))
      (unless (get-buffer vterm-buffer-name)
        (vterm))
      (display-buffer vterm-buffer-name t)
      (switch-to-buffer-other-window vterm-buffer-name)
      (vterm--goto-line -1)
      (message command)
      (vterm-send-string command)
      (vterm-send-return)
      (switch-to-buffer-other-window buf)
      )))
(global-set-key (kbd "C-c x") 'pjp/vterm-execute-region-or-current-line)

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

(use-package eshell
  :hook ((eshell-first-time-mode . pjp/configure-eshell)))

(use-package eshell-up)

(use-package eshell-toggle
  :custom
  (eshell-toggle-size-fraction 4)
  (eshell-toggle-run-command nil)
  :bind
  ("C-c s" . eshell-toggle))

(use-package eshell-syntax-highlighting
  :after eshell-mode
  :config
  ;; Enable in all Eshell buffers.
  (eshell-syntax-highlighting-global-mode +1))

(with-eval-after-load "esh-opt"
  (autoload 'epe-theme-multiline-with-status "eshell-prompt-extras")
  (setq eshell-highlight-prompt nil
        eshell-prompt-function 'epe-theme-multiline-with-status))

;; (with-eval-after-load "esh-opt"
;;   (require 'virtualenvwrapper)
;;   (venv-initialize-eshell)
;;   (autoload 'epe-theme-lambda "eshell-prompt-extras")
;;   (setq eshell-highlight-prompt nil
;;         eshell-prompt-function 'epe-theme-lambda))

;; (eshell-did-you-mean-setup)

(use-package eshell-bookmark
  :after eshell
  :config
  (add-hook 'eshell-mode-hook #'eshell-bookmark-setup))

;; Only fetch mail on knave
;; (setq pjp/mail-enabled (member system-name '("knave" "precision")))
;; (setq pjp/mu4e-inbox-query nil)
;; (when pjp/mail-enabled
;;   (require 'pjp-email))
(global-set-key (kbd "C-c e") (lambda() (interactive) (load "~/.emacs.d/lisp/pjp-email.el")))

(setq auto-mode-alist (cons '("\\.\\(pde\\|ino\\)$" . c++-mode) auto-mode-alist))

(pdf-loader-install)

(use-package guix
  :defer t)

(use-package daemons
  :commands daemons)

;; (use-package docker
;;   :commands docker)

;; (use-package docker-tramp
;;   :defer t
;;   :after docker)

(require 'dockerfile-mode)
(add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode))

(when pjp/is-gnu
  (with-eval-after-load 'geiser-guile
    (add-to-list 'geiser-guile-load-path "~/guix"))
  (load-file "~/.emacs.d/lisp/copyright.el"))

(require 'inheritenv)
(add-hook 'hack-local-variables-hook 'buffer-env-update)

(recentf-mode 1)
(save-place-mode 1)
(setq use-dialog-box nil)
