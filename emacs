;;;; Kimmo's Emacs configuration file.
; Created 11 October 2009.
; Move emacsconf to ~/emacs.d and create a symlink to this file with
; cd; ln -s .emacs.d/emacsconf/emacs.cfg .emacs
;
; Packages installed with apt:
; emacs-snapshot-gtk emacs-goodies-el css-mode gettext-el js2-mode php-mode python-mode python-rope python-ropemacs
;
; Add custom directory to load path.
(add-to-list 'load-path "~/.emacs.d/emacsconf/plugins")

; Set default font size.
(set-face-attribute 'default nil :height 100)

; Set the color theme.
(require 'color-theme)
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

; Load mode for Django templates ( http://code.djangoproject.com/wiki/Emacs )
(require 'django-mode)

; Use yasnippet ( http://code.google.com/p/yasnippet/ )
(add-to-list 'load-path "~/.emacs.d/emacsconf/plugins/yasnippet-0.6.1c")
(require 'yasnippet) ;; not yasnippet-bundle
(yas/initialize)
(yas/load-directory "~/.emacs.d/emacsconf/plugins/yasnippet-0.6.1c/snippets")

; User defined snippets.
(setq yas/root-directory "~/.emacs.d/emacsconf/mysnippets")
(yas/load-directory yas/root-directory)

; Use js2-mode and espresso for Javascript
; ( http://mihai.bazon.net/projects/editing-javascript-with-emacs-js2-mode ).
(autoload 'js2-mode "js2-mode" nil t)
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
 '(js2-mirror-mode nil))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )
