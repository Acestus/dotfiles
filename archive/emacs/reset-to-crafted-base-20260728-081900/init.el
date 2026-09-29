;;; init.el --- Acestus Crafted Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; Fresh baseline built from System Crafters Crafted Emacs.

;;; Code:

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file nil :nomessage))

(load (expand-file-name "modules/crafted-init-config" user-emacs-directory))

(require 'crafted-completion-packages)
(package-install-selected-packages :noconfirm)

(require 'crafted-completion-config)
(require 'crafted-defaults-config)
(require 'crafted-startup-config)

(load-theme 'deeper-blue t)

(set-default-coding-systems 'utf-8)

(add-to-list 'auto-mode-alist '("\\.md\\'" . text-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . text-mode))

(defvar acestus/frame-geometry-file
  (expand-file-name "frame-geometry.el" user-emacs-directory)
  "File where the last GUI Emacs frame geometry is saved.")

(defun acestus/read-frame-geometry ()
  "Read saved GUI frame geometry."
  (when (file-readable-p acestus/frame-geometry-file)
    (with-temp-buffer
      (insert-file-contents acestus/frame-geometry-file)
      (read (current-buffer)))))

(defun acestus/usable-frame-geometry-p (geometry)
  "Return non-nil when GEOMETRY has enough numeric frame data."
  (and (listp geometry)
       (integerp (alist-get 'left geometry))
       (integerp (alist-get 'top geometry))
       (integerp (alist-get 'width geometry))
       (integerp (alist-get 'height geometry))))

(defun acestus/save-frame-geometry (&optional frame)
  "Save FRAME's GUI size and position."
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (with-temp-file acestus/frame-geometry-file
        (prin1 `((left . ,(frame-parameter frame 'left))
                 (top . ,(frame-parameter frame 'top))
                 (width . ,(frame-width frame))
                 (height . ,(frame-height frame)))
               (current-buffer))))))

(defun acestus/apply-frame-geometry (frame)
  "Apply saved GUI geometry to FRAME."
  (let ((geometry (acestus/read-frame-geometry)))
    (when (and (display-graphic-p frame)
               (acestus/usable-frame-geometry-p geometry))
      (set-frame-position frame
                          (alist-get 'left geometry)
                          (alist-get 'top geometry))
      (set-frame-size frame
                      (alist-get 'width geometry)
                      (alist-get 'height geometry)))))

(let ((geometry (acestus/read-frame-geometry)))
  (when (acestus/usable-frame-geometry-p geometry)
    (setq initial-frame-alist (append geometry initial-frame-alist)
          default-frame-alist (append geometry default-frame-alist))))
(add-hook 'after-make-frame-functions #'acestus/apply-frame-geometry)
(add-hook 'delete-frame-functions #'acestus/save-frame-geometry)
(add-hook 'kill-emacs-hook #'acestus/save-frame-geometry)

(defun acestus/display-startup-time ()
  "Display Emacs startup time."
  (message "Crafted Emacs loaded in %s." (emacs-init-time)))
(add-hook 'emacs-startup-hook #'acestus/display-startup-time)

(provide 'init)
;;; init.el ends here
