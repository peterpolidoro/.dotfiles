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
