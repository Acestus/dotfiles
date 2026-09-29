;;; early-init.el --- Acestus Crafted Emacs bootstrap -*- lexical-binding: t; -*-

;;; Commentary:
;; Load Crafted Emacs package/archive setup before normal init.

;;; Code:

(load (expand-file-name "modules/crafted-early-init-config" user-emacs-directory))

(provide 'early-init)
;;; early-init.el ends here
