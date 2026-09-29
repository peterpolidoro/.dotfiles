;; Canonical Guix channel pin set for Peter's machines.
;;
;; Guix Home installs this file as ~/.config/guix/channels.scm, so `guix pull`
;; builds exactly these commits on every machine. Each Orb Weaver and
;; Mechatronic Magic repository's .guix/channels.scm carries a subset of the
;; same pins; a helper (guix-agent-tools-sync-channels, later `loom channels
;; sync`) copies the commits from here, so a Guix or tool-set update is one
;; edit in this file plus one sync. Move pins deliberately, per
;; orb-weaver-context/context/guix-channel-maintenance.md and the workstation
;; migration plan in orb-weaver-context/.agents/PLANS.md, and adopt a new Guix
;; commit only after `guix weather` shows substitutes for the heavy tiers.
;;
;; Pins as of 2026-09-29: retain the 2026-09-28 Guix dd8c1c5, Orb Weaver,
;; and shared emacs-config commits. Advance only emacs-config-peter to
;; b54187b: public 1.8.5, personal 1.12.10, and email 1.2.5, including the
;; startup garbage-collection and vterm responsiveness fixes.
;;
;; Substitute servers: besides the two default farms, the daemon on each
;; machine uses the North America build farm. On a foreign distro:
;;   curl -L -o /tmp/cuirass.genenetwork.org.pub \
;;     'https://git.genenetwork.org/guix-north-america/plain/.pubkeys/guix/cuirass.genenetwork.org.pub'
;;   sudo guix archive --authorize < /tmp/cuirass.genenetwork.org.pub
;;   sudo systemctl edit guix-daemon      # a drop-in, not a full unit override
;;     [Service]
;;     ExecStart=
;;     ExecStart=/var/guix/profiles/per-user/root/current-guix/bin/guix-daemon \
;;       --build-users-group=guixbuild --discover=yes \
;;       --substitute-urls='https://cuirass.genenetwork.org https://ci.guix.gnu.org https://bordeaux.guix.gnu.org'
;;   sudo systemctl daemon-reload
;; Restart guix-daemon from a clean TTY or after logging out; restarting it
;; from a live Guix-backed desktop session can leave /gnu/store busy. The key
;; is also installed as ~/.config/guix/cuirass.genenetwork.org.pub.

(list
 (channel
  (name 'guix)
  (url "https://git.guix.gnu.org/guix.git")
  (branch "master")
  (commit "dd8c1c5173a0e2e7311cb805ed0344ad971bc6e7")
  (introduction
   (make-channel-introduction
    "9edb3f66fd807b096b48283debdcddccfea34bad"
    (openpgp-fingerprint
     "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
 (channel
  (name 'guix-agent-tools)
  (url "https://codeberg.org/orb-weaver/guix-agent-tools.git")
  (branch "main")
  (commit "63ea285f89fc4662d2cec804847a4782135fd35e"))
 (channel
  (name 'orb-weaver-context)
  (url "https://codeberg.org/orb-weaver/orb-weaver-context.git")
  (branch "main")
  (commit "4b6ffa16b0159e095a5cb92a717284aa7d904eb3"))
 (channel
  (name 'orb-weaver-kicad-libs)
  (url "https://codeberg.org/orb-weaver/kicad-libs.git")
  (branch "main")
  (commit "8bde69e79fcf2cefde7fdefb865553019f269327"))
 (channel
  (name 'emacs-config)
  (url "https://codeberg.org/orb-weaver/emacs-config.git")
  (branch "main")
  (commit "51d2bc6e5e56ff29a32b0b3ec2d470d5dd8297b2"))
 (channel
  (name 'emacs-config-peter)
  (url "https://codeberg.org/peterpolidoro/emacs-config-peter.git")
  (branch "main")
  (commit "b54187bf5b63328682061c030e53c438560e253f")))
