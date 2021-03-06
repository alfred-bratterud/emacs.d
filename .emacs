;; Load addons
(add-to-list 'load-path "~/.emacs.d/extra/")

;; Golang-mode
(require 'go-mode)

;; Editor-config 
;; https://github.com/editorconfig/editorconfig-emacs
(require 'editorconfig)
(editorconfig-mode 1)

;; Protobuf-mode
;; http://melpa.org/packages/protobuf-mode-20150521.2011.el
;; (add-to-list 'auto-mode-alist '("\\.proto\\'" . protobuf-mode))
;; (require 'protobuf-mode)

;; Column-marker
;; http://www.emacswiki.org/emacs/download/column-marker.el
(require 'column-marker)
(add-hook 'c++-mode-hook (lambda () (interactive) (column-marker-2 80)))

;; Rainbow parenthesis
;; https://raw.githubusercontent.com/jlr/rainbow-delimiters/master/rainbow-delimiters.el
(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

(setq c-default-style "stroustrup"
                c-basic-offset 4)

;; Column-numbers
(column-number-mode)

;; Add MELPA
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
		    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives '("gnu" . (concat proto "://elpa.gnu.org/packages/")))))
(package-initialize)

;; Enable helm (https://github.com/emacs-helm/helm/)
(require 'helm-config)

;; Dumb-jump keybindings
(use-package dumb-jump
	     :bind (("M-g o" . dumb-jump-go-other-window)
		    ("M-g j" . dumb-jump-go)
		    ("M-g i" . dumb-jump-go-prompt)
		    ("M-g x" . dumb-jump-go-prefer-external)
		    ("M-g z" . dumb-jump-go-prefer-external-other-window))
	     :config (setq dumb-jump-selector 'ivy) ;; (setq dumb-jump-selector 'helm)
	       :ensure)

(setq INCLUDEOS_SRC (or (getenv "INCLUDEOS_SRC") "~/IncludeOS"))
(message (concat "IncludeOS source: " INCLUDEOS_SRC))
(setq ARCH (or (getenv "ARCH") "x86_64"))
(message (concat "IncludeOS ARCH: " ARCH))
(setq OS_BUILD (concat INCLUDEOS_SRC "/build_" ARCH))
(message (concat "IncludeOS build: " OS_BUILD))
(setq APP (or (getenv "APP") (concat INCLUDEOS_SRC "/examples/demo-service" )))
(setq APP_BUILD (concat APP "/build" ))

(defun setapp (name)
  (interactive "MApp: ") 
  ;; Verify that the app exists, otherwise error
  (setq selected-dir name)
  (when (not (file-exists-p selected-dir))
    (error (concat selected-dir " doesn't exist")))
  ;; Make it idempotent
  (progn (when (string= selected-dir APP) (error "App allready selected")) 
	 (setq APP selected-dir)
	 (setq APP_BUILD (concat APP "/build"))
	 (shell-command (concat "~/.emacs.d/setapp.sh " name))
	 (print (concat "APP is now " selected-dir))))

(defun str-make-path-target (path target)
  (concat "cd " path " && make " target " "))

  (defun make-path-target (path target)
    (message (concat "Making path " path))    
    (compile (str-make-path-target path target)))

(defun make-install (path)
  (compile (str-make-path-target path "install")))  

(defun make-app ()
  (message (concat "Making app " APP_BUILD))     
  (interactive
   (let ((string (read-string "Build App target: " nil  'my-history)))
     (make-path-target APP_BUILD string))))

(defun make-os ()
  (interactive 
   (let ((string (read-string "Build OS target: " nil 'my-history)))
     (make-path-target OS_BUILD string))))


(defun clean-app ()
  (interactive)
  (make-path-target APP_BUILD "clean"))

(defun clean-os ()
  (interactive)
  (make-path-target OS_BUILD "clean"))

(defun clean ()
  (interactive)
  (compile (concat (str-make-path-target OS_BUILD "clean") " && "
		   (str-make-path-target APP_BUILD "clean"))))
					 

(defun make ()
  (interactive 
   (let ((target (read-string "Build OS+App target: " (car my-history) 'my-history)))
     (let ((default-directory APP_BUILD))
       (compile (concat (str-make-path-target OS_BUILD target) " && "
			(str-make-path-target OS_BUILD "install") " && "
			(str-make-path-target APP_BUILD target)))))))
   

(defun format-buffer ()
  "Format the whole buffer."
  ;;(c-set-style "stroustrup")
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max))
  (editorconfig-apply)
  (goto-char (point-max))
  (delete-blank-lines)
  (save-buffer))

;; Key bindings
(global-set-key (kbd "C-c RET") 'make-app)
(global-set-key (kbd "C-c a") 'make)
(global-set-key (kbd "C-c o") 'make-os)
(global-set-key (kbd "C-x <down>") 'next-error)
(global-set-key (kbd "C-x <up>") 'previous-error)
(global-set-key (kbd "C-c c") 'clean)

;; Jump to error
(setq compilation-skip-threshold 2) ;; 2 skips warnings

