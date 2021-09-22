(require 'map) ;; Needed for map-merge

(setq pjp/system-settings
  (map-merge
    'list
    '((desktop/dpi . 180)
      (emacs/default-face-size . 220)
      (emacs/variable-face-size . 245)
      (emacs/fixed-face-size . 200)
      )
    ))
