(use-modules (guix ci))

(list (channel-with-substitutes-available
       %default-guix-channel
       "https://ci.guix.gnu.org"))

(cons* (channel
        (name 'guix-janelia)
        (url "https://github.com/guix-janelia/guix-janelia.git")
        (branch "main"))
       %default-channels)
