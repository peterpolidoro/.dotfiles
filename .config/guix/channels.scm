;; This repository contains setup and management instructions for a Guix North American Build Farm.

;; Using Substitutes from cuirass.genenetwork.org
;; On Guix System
;; If you're using Guix System, you can use the cuirass.genenetwork.org substitute server completing the following:

;; Add https://cuirass.genenetwork.org to the list of substitute servers (using the substitute-urls field of guix-configuration passed to the guix-daemon service).
;; Adjust guix-daemon ACLs to include the following public key (using the authorized-keys field of guix-configuration passed to the guix-daemon service).

;; (public-key
;;  (ecc
;;   (curve Ed25519)
;;   (q #9578AD6CDB23BA51F9C4185D5D5A32A7EEB47ACDD55F1CCB8CEE4E0570FBF961#)
;;   )
;; )
;; In the future, we hope to work with Guix maintainers to include this substitute server as one of the provided Guix System defaults.

;; On Foreign Distributions
;; When using Guix on a foreign distribution, you'll need to do the following to enable substitutes from cuirass.genenetwork.org:

;; Add the public key (provided above) for cuirass.genenetwork.org to the guix-daemon ACLs.

;; curl -L   -o /tmp/cuirass.genenetwork.org.pub   'https://git.genenetwork.org/guix-north-america/plain/.pubkeys/guix/cuirass.genenetwork.org.pub'
;; sudo guix archive --authorize < cuirass.genenetwork.org.pub
;; Add the substitute url using the --substitute-urls option to guix-daemon. Assuming your foreign distribution uses systemd, this can be done using the following.

;; sudo systemctl edit --full guix-daemon
;; If you want to just use ci.guix.gnu.org, or cuirass.genenetwork.org for that matter, you'll need to adjust the substitute URLs configuration for the guix-daemon to just refer to the substitute servers you want to use. Once edited and saved, restart the guix daemon.
;; ExecStart=/gnu/store/.../bin/guix-daemon --build-users-group=guixbuild \
;;   --substitute-urls='https://cuirass.genenetwork.org https://ci.guix.gnu.org https://bordeaux.guix.gnu.org'

;; sudo systemctl daemon-reload
;; sudo systemctl restart guix-daemon.service
;; Reference
;; Intial Setup Instructions
;; Details the initial setup of a genenetwork.org sponsored, single node build farm.
;; Administration of cuirass.genenetwork.org
;; details maintenance and administration of cuirass.genenetwork.org

(use-modules (guix ci))

(list (channel-with-substitutes-available
       %default-guix-channel
       "https://ci.guix.gnu.org"))

(cons* (channel
         (name 'emacs-config)
         (url "https://codeberg.org/orb-weaver/emacs-config.git")
         (branch "main"))
       (channel
         (name 'emacs-config-peter)
         (url "https://codeberg.org/peterpolidoro/emacs-config-peter.git")
         (branch "main"))
       %default-channels)
