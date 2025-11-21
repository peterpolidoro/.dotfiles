
(defun pjp/load-system-settings ()
  (interactive)
  (load-file "~/.dotfiles/.emacs.d/per-system-settings.el"))

(defun pjp/system-settings-get (setting)
  (alist-get setting pjp/system-settings))

(provide 'pjp-settings)
