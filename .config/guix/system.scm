;; This is an operating system configuration generated
;; by the graphical installer.

(use-modules (gnu) (nongnu packages linux))
(use-service-modules
  cups
  desktop
  networking
  ssh
  xorg)

(operating-system
  (kernel linux)
  (firmware (list linux-firmware))
  (locale "en_US.utf8")
  (timezone "America/New_York")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "precision")
  (users (cons* (user-account
                  (name "peter")
                  (comment "Peter Polidoro")
                  (group "users")
                  (home-directory "/home/peter")
                  (supplementary-groups
                    '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))
  (packages
    (append
      (list (specification->package "emacs")
            (specification->package "emacs-exwm")
            (specification->package
              "emacs-desktop-environment")
            (specification->package "nss-certs"))
      %base-packages))
  (services
    (append
      (list (service xfce-desktop-service-type)
            (service openssh-service-type)
            (service cups-service-type)
            (set-xorg-configuration
              (xorg-configuration
                (keyboard-layout keyboard-layout))))
      %desktop-services))
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets (list "/boot/efi"))
      (keyboard-layout keyboard-layout)))
  (file-systems
    (cons* (file-system
             (mount-point "/home")
             (device
               (uuid "45514010-9ad4-406c-854a-84a436a8740a"
                     'ext4))
             (type "ext4"))
           (file-system
             (mount-point "/")
             (device
               (uuid "87f80f89-ae99-41c5-90d4-005b3eb2592d"
                     'ext4))
             (type "ext4"))
           (file-system
             (mount-point "/boot/efi")
             (device (uuid "8C65-7484" 'fat32))
             (type "vfat"))
           %base-file-systems)))
