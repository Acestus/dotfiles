;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; Use a larger font for better readability.
(setq doom-font (font-spec :family "Fira Code" :size 32 :weight 'semi-light :features '(:liga tlig)))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; Start Doom Emacs in fullscreen from launch.
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(fullscreen . maximized))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Bicep support with eglot LSP
(use-package! bicep-mode
  :mode "\\.bicep\\'")

(add-hook 'bicep-mode-hook #'eglot-ensure)

(after! eglot
  (add-to-list 'eglot-server-programs
               `(bicep-mode . (,(expand-file-name "~/dotnet/dotnet")
                                ,(expand-file-name "~/.emacs.d/.cache/bicep/Bicep.LangServer.dll")))))

;; PowerShell support with eglot + PowerShellEditorServices
(defvar my/powershell-executable
  (or (executable-find "pwsh")
      (executable-find "powershell"))
  "PowerShell executable used to launch PowerShellEditorServices.")

(defconst my/powershell-editor-services-root
  (expand-file-name "powershell-editor-services/" doom-cache-dir)
  "Cache directory for PowerShellEditorServices.")

(defconst my/powershell-editor-services-zip-url
  "https://github.com/PowerShell/PowerShellEditorServices/releases/latest/download/PowerShellEditorServices.zip"
  "Download URL for PowerShellEditorServices.")

(defun my/powershell--quote (value)
  "Return VALUE quoted for PowerShell."
  (concat "'" (replace-regexp-in-string "'" "''" value t t) "'"))

(defun my/powershell--call (command buffer)
  "Run COMMAND through PowerShell, capturing output in BUFFER."
  (unless my/powershell-executable
    (user-error "PowerShell executable not found in PATH"))
  (let ((exit-code (call-process my/powershell-executable nil buffer t
                                 "-NoLogo" "-NoProfile" "-NonInteractive"
                                 "-Command" command)))
    (unless (zerop exit-code)
      (error "PowerShellEditorServices setup failed; see %s" (buffer-name buffer)))))

(defun my/powershell-ensure-editor-services ()
  "Download PowerShellEditorServices into Doom's cache when needed."
  (let ((start-script (expand-file-name "PowerShellEditorServices/Start-EditorServices.ps1"
                                        my/powershell-editor-services-root)))
    (unless (file-exists-p start-script)
      (make-directory my/powershell-editor-services-root t)
      (let ((zip-file (make-temp-file "PowerShellEditorServices" nil ".zip"))
            (buffer (get-buffer-create "*PowerShell Editor Services Setup*")))
        (unwind-protect
            (progn
              (with-current-buffer buffer
                (erase-buffer))
              (my/powershell--call
               (format "Invoke-WebRequest -UseBasicParsing -Uri %s -OutFile %s"
                       (my/powershell--quote my/powershell-editor-services-zip-url)
                       (my/powershell--quote zip-file))
               buffer)
              (my/powershell--call
               (format "Expand-Archive -Force -Path %s -DestinationPath %s"
                       (my/powershell--quote zip-file)
                       (my/powershell--quote my/powershell-editor-services-root))
               buffer))
          (when (file-exists-p zip-file)
            (delete-file zip-file)))))))

(defun my/powershell-eglot-command (&optional _interactive _project)
  "Return the PowerShellEditorServices command for Eglot."
  (my/powershell-ensure-editor-services)
  (let ((start-script (expand-file-name "PowerShellEditorServices/Start-EditorServices.ps1"
                                        my/powershell-editor-services-root))
        (log-dir (expand-file-name "logs/" my/powershell-editor-services-root)))
    (make-directory log-dir t)
    (list my/powershell-executable
          "-NoProfile" "-NonInteractive" "-NoLogo"
          "-OutputFormat" "Text"
          "-File" start-script
          "-HostName" "Emacs Host"
          "-HostProfileId" "Emacs.LSP"
          "-HostVersion" "0.1"
          "-LogPath" (expand-file-name "emacs-powershell.log" log-dir)
          "-LogLevel" "Normal"
          "-SessionDetailsPath" (format "%s/PSES-VSCode-%d" log-dir (emacs-pid))
          "-Stdio"
          "-BundledModulesPath" my/powershell-editor-services-root
          "-FeatureFlags" "@()")))

(after! eglot
  (add-to-list 'eglot-server-programs
               (cons 'powershell-mode #'my/powershell-eglot-command)))

(after! powershell
  (add-hook 'powershell-mode-local-vars-hook #'eglot-ensure))

;; GitHub Copilot
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :init
  (setq copilot-idle-delay 0.2)
  :bind (:map copilot-completion-map
              ("<right>" . copilot-accept-completion)
              ("C-f" . copilot-accept-completion)
              ("M-<right>" . copilot-accept-completion-by-word)
              ("M-f" . copilot-accept-completion-by-word)
              ("<end>" . copilot-accept-completion-by-line)
              ("C-e" . copilot-accept-completion-by-line)
              ("M-n" . copilot-next-completion)
              ("M-p" . copilot-previous-completion)))

;; PlantUML previews via the local Docker server.
(add-to-list 'auto-mode-alist '("\\.puml\\'" . plantuml-mode))

(after! plantuml-mode
  (setq plantuml-default-exec-mode 'executable
        plantuml-executable-path (expand-file-name "~/.local/bin/plantuml-local-server")
        plantuml-output-type "svg")

  (defun my/plantuml-browse ()
    "Open the current PlantUML buffer in the local server's web UI."
    (interactive)
    (let* ((source (buffer-substring-no-properties (point-min) (point-max)))
           (compressed (deflate-zlib-compress source 'dynamic))
           (b64 (base64-encode-string (apply #'unibyte-string compressed) t)))
      (with-temp-buffer
        (insert b64)
        (translate-region (point-min) (point-max) plantuml-server-base64-char-table)
        (browse-url (concat "http://localhost:8080/uml/" (buffer-string))))))

  (define-key plantuml-mode-map (kbd "C-c C-b") #'my/plantuml-browse))

;; Let Org edit PlantUML source blocks with plantuml-mode.
(after! org
  (setq org-plantuml-exec-mode 'plantuml
        org-plantuml-executable-path (expand-file-name "~/.local/bin/plantuml-local-server")
        org-plantuml-args nil)
  (add-to-list 'org-src-lang-modes '("plantuml" . plantuml)))

;; Ligature configuration using ligature.el
(defvar my/ligature-symbols
  '("www" "**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\\\" "{-" "[]" "::" ":::" ":="
    "!!" "!=" "!==" "-}" "----" "-->" "->" "->>" "-<" "-<<" "-~" "#{" "#[" "##"
    "###" "####" "#(" "#?" "#_" "#_(" ".-" ".=" ".." "..<" "..." "?=" "??" ";;" "/*"
    "/**" "/=" "/==" "/>" "//" "///" "&&" "||" "||=" "|=" "|>" "^=" "$>" "++"
    "+++" "+>" "=:=" "==" "===" "==>" "=>" "=>>" "<=" "=<<" "=/=" ">-" ">=" ">=>"
    ">>" ">>-" ">>=" ">>>" "<*" "<*>" "<|" "<|>" "<$" "<$>" "<!--" "<-" "<--"
    "<->" "<+" "<+>" "<=" "<==" "<=>" "<=<" "<>" "<<" "<<-" "<<=" "<<<" "<~" "<~~"
    "</" "</>" "~@" "~-" "~=" "~>" "~~" "~~>" "%%" "x" ":" "+" "+" "*")
  "Ligatures to enable in programming modes.")

(after! ligature
  (ligature-set-ligatures 't '("www"))
  (dolist (mode '(prog-mode fundamental-mode bicep-mode))
    (ligature-set-ligatures mode my/ligature-symbols))
  (global-ligature-mode +1))
