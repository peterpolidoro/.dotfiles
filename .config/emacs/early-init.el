;;; early-init.el --- Early startup tweaks -*- lexical-binding: t; -*-
;; NOTE: This file is generated from Emacs.org.  Please edit that file
;;       in Emacs and this file will be generated automatically!

;; We use Guix profiles for packages; don't let package.el initialize.
(setq package-enable-at-startup nil)

;; Avoid frame flicker / resizing during init.
(setq frame-inhibit-implied-resize t)

;; Hide UI chrome as early as possible (we can re-enable in init if desired).
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; Speed up startup by deferring file-name handlers; restore after init.
(let ((old file-name-handler-alist))
  (setq file-name-handler-alist nil)
  (add-hook 'emacs-startup-hook
            (lambda () (setq file-name-handler-alist old))))

;; Environment variables:
;;   EMACS_INIT_DIR      - directory containing init files (read-only)
;;   EMACS_WRITABLE_DIR  - base directory for writable data/state/cache
;;                         (if unset, XDG directories are used)

;;------------------------------------------------------------------------------
;; 1. Readable init directory (may be in Guix store)
;;------------------------------------------------------------------------------

(defvar emacs-init-dir
  (or (getenv "EMACS_INIT_DIR")
      (expand-file-name
       "emacs/"
       (or (getenv "XDG_CONFIG_HOME")
           (expand-file-name "~/.config/"))))
  "Directory containing Emacs init files (preferably read-only).")

(setq user-emacs-directory emacs-init-dir)

;;------------------------------------------------------------------------------
;; 2. Writable base and XDG fallbacks
;;------------------------------------------------------------------------------

(defconst emacs-writable-base
  (getenv "EMACS_WRITABLE_DIR")
  "Base directory for all writable Emacs data/state/cache if set.")

;; If EMACS_WRITABLE_DIR is set, we derive data/state/cache under it.
;; Otherwise, use XDG_DATA_HOME / XDG_STATE_HOME / XDG_CACHE_HOME.
(defconst emacs-xdg-data-home
  (or (and emacs-writable-base
           (expand-file-name "data/" emacs-writable-base))
      (or (getenv "XDG_DATA_HOME")
          (expand-file-name "~/.local/share/"))))

(defconst emacs-xdg-state-home
  (or (and emacs-writable-base
           (expand-file-name "state/" emacs-writable-base))
      (or (getenv "XDG_STATE_HOME")
          (expand-file-name "~/.local/state/"))))

(defconst emacs-xdg-cache-home
  (or (and emacs-writable-base
           (expand-file-name "cache/" emacs-writable-base))
      (or (getenv "XDG_CACHE_HOME")
          (expand-file-name "~/.cache/"))))

(defconst emacs-data-dir  (expand-file-name "emacs/" emacs-xdg-data-home))
(defconst emacs-state-dir (expand-file-name "emacs/" emacs-xdg-state-home))
(defconst emacs-cache-dir (expand-file-name "emacs/" emacs-xdg-cache-home))

(dolist (dir (list emacs-data-dir emacs-state-dir emacs-cache-dir))
  (make-directory dir t))

;;------------------------------------------------------------------------------
;; 3. Core writable file locations
;;------------------------------------------------------------------------------

;; Keep Custom from touching your init files
(setq custom-file (expand-file-name "custom.el" emacs-state-dir))

;; package.el installation directory (if you let it install anything)
(setq package-user-dir (expand-file-name "elpa/" emacs-data-dir))

;; Session / state files
(setq url-history-file      (expand-file-name "url/history" emacs-state-dir)
      recentf-save-file     (expand-file-name "recentf"      emacs-state-dir)
      bookmark-default-file (expand-file-name "bookmarks"    emacs-state-dir)
      savehist-file         (expand-file-name "savehist"     emacs-state-dir)
      save-place-file       (expand-file-name "saveplace"    emacs-state-dir)
      project-list-file     (expand-file-name "projects"     emacs-state-dir)
      tramp-persistency-file-name (expand-file-name "tramp"  emacs-state-dir)
      eshell-directory-name (expand-file-name "eshell/"      emacs-state-dir)
      server-auth-dir       (expand-file-name "server/"      emacs-state-dir)
      desktop-dirname       (expand-file-name "desktop/"     emacs-state-dir))

(dolist (dir (list
              (file-name-directory url-history-file)
              (file-name-directory recentf-save-file)
              (file-name-directory bookmark-default-file)
              (file-name-directory savehist-file)
              (file-name-directory save-place-file)
              (file-name-directory project-list-file)
              (file-name-directory tramp-persistency-file-name)
              eshell-directory-name
              server-auth-dir
              desktop-dirname))
  (when dir (make-directory dir t)))

;;------------------------------------------------------------------------------
;; 4. Backups, autosaves, locks → cache dir
;;------------------------------------------------------------------------------

(let* ((backup-dir   (expand-file-name "backup/"   emacs-cache-dir))
       (autosave-dir (expand-file-name "autosave/" emacs-cache-dir))
       (locks-dir    (expand-file-name "locks/"    emacs-cache-dir)))
  (dolist (dir (list backup-dir autosave-dir locks-dir))
    (make-directory dir t))
  (setq backup-directory-alist
        `(("." . ,backup-dir))
        auto-save-list-file-prefix
        (expand-file-name ".saves-" autosave-dir)
        auto-save-file-name-transforms
        `((".*" ,autosave-dir t)))
  (when (boundp 'lock-file-name-transforms) ; Emacs 28+
    (setq lock-file-name-transforms
          `((".*" ,locks-dir t)))))

;;------------------------------------------------------------------------------
;; 5. Native compilation cache → cache dir
;;------------------------------------------------------------------------------

(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (expand-file-name "eln-cache/" emacs-cache-dir)))

;;------------------------------------------------------------------------------
;; 6. no-littering: route package files into writable dirs
;;------------------------------------------------------------------------------

;; Map “etc” (config-ish) into data dir and “var” (state-ish) into state dir.
;; Both are writable; readable init stays in EMACS_INIT_DIR / XDG config.
(condition-case err
    (progn
      (setq no-littering-etc-directory
            (expand-file-name "etc/" emacs-data-dir)
            no-littering-var-directory
            (expand-file-name "var/" emacs-state-dir))
      (require 'no-littering))
  (error
   (message "Warning: no-littering not available: %s" err)))

;;------------------------------------------------------------------------------

(provide 'early-init)
;;; early-init.el ends here
