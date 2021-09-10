(use-package mu4e
  ;; :defer 20 ; Wait until 20 seconds after startup
  :config

  ;; Load org-mode integration
  (require 'org-mu4e)

  ;; Refresh mail using isync every 5 minutes
  (setq mu4e-update-interval (* 10 60))
  (setq mu4e-get-mail-command "mbsync -a")
  (setq mu4e-root-maildir "~/Email")

  ;; Use Ivy for mu4e completions (maildir folders, etc)
  (setq mu4e-completing-read-function #'ivy-completing-read)

  ;; Make sure that moving a message (like to Trash) causes the
  ;; message to get a new file name.  This helps to avoid the
  ;; dreaded "UID is N beyond highest assigned" error.
  ;; See this link for more info: https://stackoverflow.com/a/43461973
  (setq mu4e-change-filenames-when-moving t)

  ;; Set up contexts for email accounts
  (setq mu4e-contexts
        (list
         (make-mu4e-context
          :name "gmail"
          :match-func (lambda (msg)
                        (when msg
                          (string-prefix-p "/Gmail" (mu4e-message-field msg :maildir))))
          :vars '((user-full-name . "Peter Polidoro")
                  (user-mail-address . "peterpolidoro@gmail.com")
                  (smtpmail-smtp-user  . "peterpolidoro@gmail.com")
                  (smtpmail-smtp-server  . "smtp.gmail.com")
                  (smtpmail-smtp-service . 465)
                  (smtpmail-stream-type  . ssl)
                  (mu4e-refile-folder . "/Gmail/All")
                  (mu4e-drafts-folder . "/Gmail/Drafts")
                  (mu4e-sent-folder . "/Gmail/Sent")
                  (mu4e-trash-folder . "/Gmail/Trash")
                  (mu4e-sent-messages-behavior . sent)
                  ))
         (make-mu4e-context
          :name "janelia"
          :match-func (lambda (msg)
                        (when msg
                          (string-prefix-p "/Janelia" (mu4e-message-field msg :maildir))))
          :vars '((user-full-name . "Peter Polidoro")
                  (user-mail-address . "polidorop@janelia.hhmi.org")
                  (smtpmail-smtp-user  . "polidorop@hhmi.org")
                  (smtpmail-smtp-server  . "smtp.office365.com")
                  (smtpmail-smtp-service . 587)
                  (smtpmail-stream-type  . starttls)
                  (mu4e-drafts-folder . "/Janelia/Drafts")
                  (mu4e-sent-folder . "/Janelia/Sent")
                  (mu4e-trash-folder . "/Janelia/Trash")
                  (mu4e-refile-folder . "/Janelia/Archive")
                  (mu4e-sent-messages-behavior . sent)
                  ))
         ))
  (setq mu4e-context-policy 'pick-first)

  ;; Prevent mu4e from permanently deleting trashed items
  ;; This snippet was taken from the following article:
  ;; http://cachestocaches.com/2017/3/complete-guide-email-emacs-using-mu-and-/
  (defun remove-nth-element (nth list)
    (if (zerop nth) (cdr list)
      (let ((last (nthcdr (1- nth) list)))
        (setcdr last (cddr last))
        list)))
  (setq mu4e-marks (remove-nth-element 5 mu4e-marks))
  (add-to-list 'mu4e-marks
               '(trash
                 :char ("d" . "▼")
                 :prompt "dtrash"
                 :dyn-target (lambda (target msg) (mu4e-get-trash-folder msg))
                 :action (lambda (docid msg target)
                           (mu4e~proc-move docid
                                           (mu4e~mark-check-target target) "-N"))))

  ;; Display options
  (setq mu4e-view-show-images t)
  (setq mu4e-view-show-addresses 't)

  ;; Composing mail
  (setq mu4e-compose-dont-reply-to-self t)

  ;; Use mu4e for sending e-mail
  (setq message-send-mail-function 'smtpmail-send-it)

  ;; Signing messages (use mml-secure-sign-pgpmime)
  ;; (setq mml-secure-openpgp-signers '("53C41E6E41AAFE55335ACA5E446A2ED4D940BF14"))

  ;; (See the documentation for `mu4e-sent-messages-behavior' if you have
  ;; additional non-Gmail addresses and want assign them different
  ;; behavior.)

  ;; setup some handy shortcuts
  ;; you can quickly switch to your Inbox -- press ``ji''
  ;; then, when you want archive some messages, move them to
  ;; the 'All Email' folder by pressing ``ma''.
  ;; (setq mu4e-maildir-shortcuts
  ;;       '(("/Gmail/Inbox" . ?i)
  ;;         ("/Gmail/Drafts" . ?d)
  ;;         ("/Gmail/Sent" . ?s)
  ;;         ("/Gmail/Trash" . ?t)))

  (add-to-list 'mu4e-bookmarks
               (make-mu4e-bookmark
                :name "All Inboxes"
                :query "maildir:/Gmail/Inbox OR maildir:/Janelia/Inbox"
                :key ?i))

  ;; don't keep message buffers around
  (setq message-kill-buffer-on-exit t)

  (setq pjp/mu4e-inbox-query
        "(maildir:/Personal/Inbox OR maildir:/Gmail/Inbox) AND flag:unread")

  ;; (defun pjp/go-to-inbox ()
  ;;   (interactive)
  ;;   (mu4e-headers-search pjp/mu4e-inbox-query))

  ;; Start mu4e
  (call-interactively 'mu4e))

(use-package mu4e-alert
  :after mu4e
  :config
  ;; Show unread emails from all inboxes
  (setq mu4e-alert-interesting-mail-query pjp/mu4e-inbox-query)

  ;; Show notifications for mails already notified
  (setq mu4e-alert-notify-repeated-mails nil)

  (mu4e-alert-enable-notifications))

(provide 'pjp-email)
