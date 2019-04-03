(require 'cl)

;;;;;;;;;;;;;;;;;;;;;
;;; HANDLE PACKAGE INSTALLS
;;;;;;;;;;;;;;;;;;;;;
(when (>= emacs-major-version 24)
  (require 'package)
  (add-to-list
   'package-archives
   '("melpa" . "http://melpa.org/packages/")
   t)
  (package-initialize))
;;Create repositories cache, if required
(when (not package-archive-contents)
  (package-refresh-contents))
;;Declare a list of required packages
(defvar my-require-packages
  '(multiple-cursors
    ztree
    web-mode
    lua-mode
    auto-complete
    js2-mode
    ))
;;Install required packages
(cl-loop for p in my-require-packages
         unless (package-installed-p p)
         do (package-install p)
         )

;;;;;;;;;;;;;;;;;;;;;
;;; CONFIGS
;;;;;;;;;;;;;;;;;;;;;

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(inhibit-startup-screen t)
)
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
)

;; IDO
(require 'ido)
(ido-mode t)

;; auto-complete
(ac-config-default)

;; web-mode
(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode)) 
(add-to-list 'auto-mode-alist '("\\.php\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.css\\'" . web-mode)) 
(defun my-web-mode-hook () "Hooks for Web mode." 
       (setq web-mode-markup-indent-offset 2) 
       (setq web-mode-css-indent-offset 2)
       (setq web-mode-code-indent-offset 2)
       (setq indent-tabs-mode nil)
       (setq tab-width 2)
) 
(add-hook 'web-mode-hook 'my-web-mode-hook)

;; Indents / Tabs
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(setq c-default-style "linux"
      c-basic-offset 2)
(setq ruby-indent-level 2)
(setq lua-indent-level 2)
(setq js-indent-level 2)

;; Show tabs
(setq whitespace-style '(tab-mark))
(global-whitespace-newline-mode)

;; multiple-cursors
(global-set-key (kbd "C-c -") 'mc/mark-next-like-this)

;; gdb
(setq gdb-show-main t)

;; newline + indent by prev row (alt + backspace)
(defun my-newline-indent ()
  (interactive)
  (looking-back "^\\([\t ]*\\).*")
  (newline)
  (insert (match-string 1))
)
(global-set-key "\M-\d" 'my-newline-indent) 

;; easy window resizing (found from: https://www.emacswiki.org/emacs/WindowResize)
(defun resize-window (&optional arg)    ; Hirose Yuuji and Bob Wiener
  "*Resize window interactively."
  (interactive "p")
  (if (one-window-p) (error "Cannot resize sole window"))
  (or arg (setq arg 1))
  (let (c)
    (catch 'done
      (while t
        (message
         "h=heighten, s=shrink, w=widen, n=narrow (by %d);  1-9=unit, q=quit"
         arg)
        (setq c (read-char))
        (condition-case ()
            (cond
             ((= c ?h) (enlarge-window arg))
             ((= c ?s) (shrink-window arg))
             ((= c ?w) (enlarge-window-horizontally arg))
             ((= c ?n) (shrink-window-horizontally arg))
             ((= c ?\^G) (keyboard-quit))
             ((= c ?q) (throw 'done t))
             ((and (> c ?0) (<= c ?9)) (setq arg (- c ?0)))
             (t (beep)))
          (error (beep)))))
    (message "Done.")))
(global-set-key (kbd "C-c <up>") 'resize-window)


;; js2
; (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))

;; match brackets
(show-paren-mode 1)
(global-set-key (kbd "M-<left>") 'backward-sexp)
(global-set-key (kbd "M-<right>") 'forward-sexp)

;;;;;;;;;;;;
; JSX LINT
;   http://codewinds.com/blog/2015-04-02-emacs-flycheck-eslint-jsx.html
;;;;;;;;;;;;

;; use web-mode for .js(x) files
(add-to-list 'auto-mode-alist '("\\.js[x]?$" . web-mode))

;; this one lets js files to be (jsx) formatted/linted too
(setq web-mode-content-types-alist
      '(("jsx" . "\\.js[x]?\\'")))


;; http://www.flycheck.org/manual/latest/index.html
(require 'flycheck)

;; turn on flychecking globally
(add-hook 'after-init-hook #'global-flycheck-mode)

;; disable jshint since we prefer eslint checking
(setq-default flycheck-disabled-checkers
              (append flycheck-disabled-checkers
                      '(javascript-jshint)))

;; use eslint with web-mode for jsx files
(flycheck-add-mode 'javascript-eslint 'web-mode)

;; customize flycheck temp file prefix
(setq-default flycheck-temp-prefix ".flycheck")

;; disable json-jsonlist checking for json files
(setq-default flycheck-disabled-checkers
              (append flycheck-disabled-checkers
                      '(json-jsonlist)))


;; use local eslint from node_modules before global
;; http://emacs.stackexchange.com/questions/21205/flycheck-with-file-relative-eslint-executable
(defun my/use-eslint-from-node-modules ()
  (let* ((root (locate-dominating-file
                (or (buffer-file-name) default-directory)
                "node_modules"))
         (eslint (and root
                      (expand-file-name "node_modules/eslint/bin/eslint.js"
                                        root))))
    (when (and eslint (file-executable-p eslint))
      (setq-local flycheck-javascript-eslint-executable eslint))))
(add-hook 'flycheck-mode-hook #'my/use-eslint-from-node-modules)


;; for better jsx syntax-highlighting in web-mode
;; - courtesy of Patrick @halbtuerke
(defadvice web-mode-highlight-part (around tweak-jsx activate)
  (if (equal web-mode-content-type "jsx")
      (let ((web-mode-enable-part-face nil))
        ad-do-it)
    ad-do-it))

;;; JSX lint end

;;; Backups (https://stackoverflow.com/questions/151945/how-do-i-control-how-emacs-makes-backup-files)
(defvar --backup-directory (concat user-emacs-directory "backups"))
(if (not (file-exists-p --backup-directory))
    (make-directory --backup-directory t))
(setq backup-directory-alist `(("." . ,--backup-directory)))
(setq make-backup-files t               ; backup of a file the first time it is saved.
      backup-by-copying t               ; don't clobber symlinks
      version-control t                 ; version numbers for backup files
      delete-old-versions t             ; delete excess backup files silently
      delete-by-moving-to-trash t
      kept-old-versions 6               ; oldest versions to keep when a new numbered backup is made (default: 2)
      kept-new-versions 9               ; newest versions to keep when a new numbered backup is made (default: 2)
      auto-save-default t               ; auto-save every buffer that visits a file
      auto-save-timeout 20              ; number of seconds idle time before auto-save (default: 30)
      auto-save-interval 200            ; number of keystrokes between auto-saves (default: 300)
      )

;;; .emacs ends here
