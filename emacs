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
(set-face-background 'hl-line "#333")

; Show line numbers on the left side.
(require 'linum)
(global-linum-mode 1)

; Set line number and column number modes on by default.
(line-number-mode 1)
(column-number-mode 1)

; Highlight matching parenthesis.
(show-paren-mode 1)

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

; Indent and clean whole buffer ( http://emacsblog.org/2007/01/17/indent-whole-buffer/ ).
(defun iwb ()
  "indent whole buffer"
  (interactive)
  (delete-trailing-whitespace)
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max)))

; Right margin: http://www.emacswiki.org/emacs/MarginMode
