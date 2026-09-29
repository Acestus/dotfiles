;;; init.el --- Crafted Emacs Base Example -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Base example init.el (extended from the info file).
;; Basic example of loading a module.

;;; Code:

;;; Initial phase

;; Load the custom file if it exists.  Among other settings, this will
;; have the list `package-selected-packages', so we need to load that
;; before adding more packages.  The value of the `custom-file'
;; variable must be set appropriately, by default the value is nil.
;; This can be done here, or in the early-init.el file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (and custom-file
           (file-exists-p custom-file))
  (load custom-file nil :nomessage))

;; Bootstrap crafted-emacs in init.el
;; Adds crafted-emacs modules to the `load-path', sets up a module
;; writing template, sets the `crafted-emacs-home' variable.
(load (expand-file-name "modules/crafted-init-config"
                        user-emacs-directory))
;; Adjust the path (e.g. to an absolute one)
;; depending where you cloned Crafted Emacs.
;; (load "/path/to/crafted-emacs/modules/crafted-init-config")

;;; Packages phase
;; Collect list of packages to install. Do not just blindly copy this
;; list, instead think about what you need and see if there is a
;; module which provides the list of packages needed. This phase is
;; not needed if manage the installed packages with Guix or Nix. It
;; is also not needed if you do not need Crafted Emacs to install
;; packages for a module, for example,
;; `crafted-speedbar-config' does not require any packages to
;; be installed.

;; Add package definitions for completion packages
;; to `package-selected-packages'.
(require 'crafted-completion-packages)

;; Manually select theme packages
(add-to-list 'package-selected-packages 'ef-themes)
(add-to-list 'package-selected-packages 'tokyo-night)

;; Install the packages listed in the `package-selected-packages' list.
(package-install-selected-packages :noconfirm)

;; Use the Tokyo Night dark theme.
(load-theme 'tokyo-night t)

;; Make the default face 50% larger on Eleanor.
(set-face-attribute 'default nil :height 150)

;;; Configuration phase
;; Some example modules to configure Emacs. Don't blindly copy these,
;; they are here for example purposes. Find the modules which work
;; for you.

;; Load configuration for the completion module
(require 'crafted-completion-config)

;; Some more configurations that don't require packages to be installed
(require 'crafted-defaults-config)
(require 'crafted-startup-config)

;;; Optional configuration

;; Profile emacs startup
(defun ce-base-example/display-startup-time ()
  "Display the startup time after Emacs is fully initialized."
  (message "Crafted Emacs loaded in %s."
           (emacs-init-time)))
(add-hook 'emacs-startup-hook #'ce-base-example/display-startup-time)

;; Set default coding system (especially for Windows)
(set-default-coding-systems 'utf-8)

;; Treat Markdown as plain text without adding packages.
(add-to-list 'auto-mode-alist '("\\.md\\'" . text-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . text-mode))
(add-hook 'text-mode-hook #'visual-line-mode)

;; Enable GitHub Copilot inline completions in Org notes.
(when (require 'copilot nil :noerror)
  (setq copilot-idle-delay 0.2)
  (add-hook 'org-mode-hook #'copilot-mode)
  (keymap-set copilot-completion-map "<tab>" #'copilot-accept-completion)
  (keymap-set copilot-completion-map "TAB" #'copilot-accept-completion)
  (keymap-set copilot-completion-map "C-<tab>" #'copilot-accept-completion-by-word)
  (keymap-set copilot-completion-map "C-TAB" #'copilot-accept-completion-by-word)
  (keymap-set copilot-completion-map "M-n" #'copilot-next-completion)
  (keymap-set copilot-completion-map "M-p" #'copilot-previous-completion)
  (keymap-global-set "C-c p" #'copilot-mode))

;; Personal keybindings use the `C-c LETTER' space reserved for users.
(keymap-global-set "C-c r" #'recentf-open-files)
(keymap-global-set "C-c v" #'revert-buffer)

;;; _
(provide 'init)
;;; init.el ends here
