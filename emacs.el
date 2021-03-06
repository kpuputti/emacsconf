;;;; Kimmo's Emacs configuration file.
; Created 11 October 2009.
; Move emacsconf to ~/emacs.d and create a symlink to this file with
; cd; ln -s .emacs.d/emacsconf/emacs.cfg .emacs
;
; Packages installed with apt:
; emacs-snapshot-gtk emacs-goodies-el css-mode gettext-el js2-mode php-mode python-mode python-rope python-ropemacs rhino
;
; Add custom directory to load path.
(add-to-list 'load-path "~/.emacs.d/emacsconf/plugins")

; Confirm quit
(setq confirm-kill-emacs 'y-or-n-p)

; Set default font size.
(set-face-attribute 'default nil :height 100)

; Set the color theme.
(require 'color-theme)
(color-theme-initialize)
(setq color-theme-is-global t)
(color-theme-simple-1)

; Helps a bit with the shell ansi colors.
(require 'ansi-color)

; Set current line highlighting and color.
(global-hl-line-mode 1)
(set-face-background 'hl-line "#111")

; Show line numbers on the left side.
(require 'linum)
(global-linum-mode 1)

; Set line number and column number modes on by default.
(line-number-mode 1)
(column-number-mode 1)

; Highlight matching parenthesis.
(show-paren-mode 1)

; Hide the tool bar with buttons.
(tool-bar-mode -1)

; Hide the scrollbar.
(scroll-bar-mode -1)

; Enable ido-mode.
(require 'ido)
(ido-mode t)
(setq ido-enable-flex-matching t)

; Enable uniquify for buffer names.
(require 'uniquify)

; Show full file path on the title bar
; ( http://www.nabble.com/How-to-full-pathname-in-modeline-td21749423.html ).
(setq-default frame-title-format
              (list '((buffer-file-name " %f"
                                        (dired-directory
                                         dired-directory
                                         (revert-buffer-function " %b"
                                                                 ("%b - Dir:  " default-directory)))))))

; Use one global directory for backups files
; ( http://www.emacswiki.org/emacs/BackupDirectory ).
(setq
 backup-by-copying t
 backup-directory-alist
 '(("." . "~/.emacs-backups"))
 delete-old-versions t
 kept-new-versions 6
 kept-old-versions 2
 version-control t)

; Use smooth scrolling.
(require 'smooth-scrolling)
(setq smooth-scroll-margin 1)

; Always use spaces for indentation.
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

; Load session from the directory Emacs was opened in.
(desktop-load-default)
(desktop-read)

; Fix CSS mode indentation.
(setq cssm-indent-level 4)
(setq cssm-newline-before-closing-bracket t)
(setq cssm-indent-function #'cssm-c-style-indenter)
(setq cssm-mirror-mode nil)

; Load mode for Django templates ( http://code.djangoproject.com/wiki/Emacs )
(autoload 'django-mode "django-mode")

; Use yasnippet ( http://code.google.com/p/yasnippet/ )
(require 'yasnippet) ;; not yasnippet-bundle
(yas/initialize)

; User defined snippets.
(yas/load-directory "~/.emacs.d/emacsconf/mysnippets")

; Use js2-mode and espresso for Javascript
; ( http://mihai.bazon.net/projects/editing-javascript-with-emacs-js2-mode ).
(autoload 'js2-mode "js2" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
(autoload 'espresso-mode "espresso")

(defun my-js2-indent-function ()
  (interactive)
  (save-restriction
    (widen)
    (let* ((inhibit-point-motion-hooks t)
           (parse-status (save-excursion (syntax-ppss (point-at-bol))))
           (offset (- (current-column) (current-indentation)))
           (indentation (espresso--proper-indentation parse-status))
           node)

      (save-excursion

        ;; I like to indent case and labels to half of the tab width
        (back-to-indentation)
        (if (looking-at "case\\s-")
            (setq indentation (+ indentation (/ espresso-indent-level 2))))

        ;; consecutive declarations in a var statement are nice if
        ;; properly aligned, i.e:
        ;;
        ;; var foo = "bar",
        ;;     bar = "foo";
        (setq node (js2-node-at-point))
        (when (and node
                   (= js2-NAME (js2-node-type node))
                   (= js2-VAR (js2-node-type (js2-node-parent node))))
          (setq indentation (+ 4 indentation))))

      (indent-line-to indentation)
      (when (> offset 0) (forward-char offset)))))

(defun my-indent-sexp ()
  (interactive)
  (save-restriction
    (save-excursion
      (widen)
      (let* ((inhibit-point-motion-hooks t)
             (parse-status (syntax-ppss (point)))
             (beg (nth 1 parse-status))
             (end-marker (make-marker))
             (end (progn (goto-char beg) (forward-list) (point)))
             (ovl (make-overlay beg end)))
        (set-marker end-marker end)
        (overlay-put ovl 'face 'highlight)
        (goto-char beg)
        (while (< (point) (marker-position end-marker))
          ;; don't reindent blank lines so we don't set the "buffer
          ;; modified" property for nothing
          (beginning-of-line)
          (unless (looking-at "\\s-*$")
            (indent-according-to-mode))
          (forward-line))
        (run-with-timer 0.5 nil '(lambda(ovl)
                                   (delete-overlay ovl)) ovl)))))

(defun my-js2-mode-hook ()
  (require 'espresso)
  (setq espresso-indent-level 4
        indent-tabs-mode nil
        c-basic-offset 4)
  (c-toggle-auto-state 0)
  (c-toggle-hungry-state 1)
  (set (make-local-variable 'indent-line-function) 'my-js2-indent-function)
  (define-key js2-mode-map [(meta control |)] 'cperl-lineup)
  (define-key js2-mode-map [(meta control \;)]
    '(lambda()
       (interactive)
       (insert "/* -----[ ")
       (save-excursion
         (insert " ]----- */"))
       ))
  (define-key js2-mode-map [(return)] 'newline-and-indent)
  (define-key js2-mode-map [(backspace)] 'c-electric-backspace)
  (define-key js2-mode-map [(control d)] 'c-electric-delete-forward)
  (define-key js2-mode-map [(control meta q)] 'my-indent-sexp)
  (if (featurep 'js2-highlight-vars)
      (js2-highlight-vars-mode))
  (message "My JS2 hook"))

(add-hook 'js2-mode-hook 'my-js2-mode-hook)

; Flymake settings.
(require 'flymake)

;(require 'flymake-jslint)
;(add-hook 'js2-mode-hook
;          (lambda () (flymake-mode 1)))

; Flymake for Python using pyflakes.
(when (load "flymake" t)
  (defun flymake-pyflakes-init ()
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           (local-file (file-relative-name
                        temp-file
                        (file-name-directory buffer-file-name))))
      (list "pyflakes" (list local-file))))

  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.py\\'" flymake-pyflakes-init)))

(add-hook 'find-file-hook 'flymake-find-file-hook)

; Indent and clean whole buffer ( http://emacsblog.org/2007/01/17/indent-whole-buffer/ ).
(defun iwb ()
  "indent whole buffer"
  (interactive)
  (delete-trailing-whitespace)
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max)))


; Right margin.
; http://www.emacswiki.org/emacs/MarginMode
; http://www.geocities.com/gchen275/xemacs/
(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(js2-allow-keywords-as-property-names nil)
 '(js2-indent-on-enter-key nil)
 '(js2-mirror-mode nil)
 '(uniquify-buffer-name-style (quote post-forward-angle-brackets) nil (uniquify)))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )

; SCSS mode
(autoload 'scss-mode "scss-mode")
(setq scss-compile-at-save nil)

(add-to-list 'auto-mode-alist '("\\.css.dtml$" . css-mode))
(add-to-list 'auto-mode-alist '("\\.scss\\'" . scss-mode))
(add-to-list 'auto-mode-alist '("\\.pt$" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.cpt$" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.zcml$" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.html$" . html-mode))

(add-to-list 'auto-mode-alist '("\\.xml$" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.rdf$" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.owl$" . nxml-mode))

(setq magic-mode-alist nil)

(add-hook 'latex-mode-hook 'flyspell-mode)
(add-hook 'text-mode-hook 'flyspell-mode)
(add-hook 'rst-mode-hook 'flyspell-mode)
(add-hook 'doctest-mode-hook 'flyspell-mode)
(setq c-default-style
      '((java-mode . "java") (other . "cc-mode")))

(autoload 'groovy-mode "groovy-mode" "Groovy editing mode." t)
(add-to-list 'auto-mode-alist '("\.groovy$" . groovy-mode))
(add-to-list 'interpreter-mode-alist '("groovy" . groovy-mode))

(defun force-tab-indent ()
  (interactive)
  (setq indent-tabs-mode t))

(defalias 'qrr 'query-replace-regexp)
(defalias 'dtr 'delete-trailing-whitespace)

(setq x-select-enable-clipboard t)
