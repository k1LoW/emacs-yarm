;;;yarm.el ---  Yet Another Ruby on Rails Minor Mode
;; -*- Mode: Emacs-Lisp -*-

;; Copyright (C) 2010 by 101000code/101000LAB

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

;; Version: 0.0.1
;; Author: k1LoW (Kenichirou Oyama), <k1lowxb [at] gmail [dot] com> <k1low [at] 101000lab [dot] org>
;; URL: http://code.101000lab.org, http://trac.codecheck.in

;;; Install
;; Put this file into load-path'ed directory, and byte compile it if
;; desired.  And put the following expression into your ~/.emacs.
;;
;; (require 'yarm)
;; (global-yarm t)
;;
;; If you use default key map, Put the following expression into your ~/.emacs.
;;
;; (yarm-set-default-key-map)

;;; Commentary:

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `yarm'
;;    Yet Another Ruby on Rails Minor Mode.
;;  `yarm-switch-to-model'
;;    Switch to model.
;;  `yarm-switch-to-view'
;;    Switch to view.
;;  `yarm-switch-to-controller'
;;    Switch to contoroller.
;;  `yarm-switch-to-partial'
;;    Switch to partial. If region is active, make new partial file.
;;  `yarm-switch-to-function'
;;    Switch to function.
;;  `yarm-switch'
;;    Omni switch function.
;;  `yarm-switch-to-file-history'
;;    Switch to file history.
;;  `yarm-open-dir'
;;    Open directory.
;;  `yarm-open-models-dir'
;;    Open models directory.
;;  `yarm-open-views-dir'
;;    Open views directory.
;;  `yarm-open-controllers-dir'
;;    Open contorollers directory.
;;  `yarm-open-helpers-dir'
;;    Open helpers directory.
;;  `yarm-open-config-dir'
;;    Open config dir.
;;  `yarm-open-layouts-dir'
;;    Open layouts directory.
;;  `yarm-open-js-dir'
;;    Open JavaScript directory.
;;  `yarm-open-css-dir'
;;    Open css directory.
;;  `anything-c-yarm-anything-only-source-yarm'
;;    anything only anything-c-source-yarm and anything-c-source-yarm-model-function.
;;  `anything-c-yarm-anything-only-function'
;;    anything only anything-c-source-yarm-function.
;;  `anything-c-yarm-anything-only-model-function'
;;    anything only anything-c-source-yarm-model-function.
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `yarm-root-path-search-limit'
;;    Search limit
;;    default = 5
;;  `yarm-use-imenu'
;;    Use imenu function
;;    default = nil

;;; Change Log
;; 0.0.1:

;;; TODO
;;

;;; Code:

;;require
(require 'inflections)
(require 'cl)
(require 'anything)
(require 'historyf)
(require 'easy-mmode)

(defgroup yarm nil
  "Yet Another Ruby on Rails Minor Mode"
  :group 'convenience
  :prefix "yarm-")

(defcustom yarm-root-path-search-limit 5
  "Search limit"
  :type 'integer
  :group 'yarm)

(defcustom yarm-use-imenu nil
  "Use imenu function"
  :type 'boolean
  :group 'yarm)

(defvar yarm-view-extension "html.erb"
  "Rails view extension.")

(defvar yarm-model-regexp "^.+/app/models/\\([^/]+\\)\.rb$"
  "Model file regExp.")

(defvar yarm-view-regexp "^.+/app/views/\\([^/]+\\)/\\([^/]+/\\)?\\([^/.]+\\)\\.\\([a-z\.]+\\)$"
  "View file regExp.")

(defvar yarm-controller-regexp "^.+/app/controllers/\\([^/]+\\)_controller\.rb$"
  "Contoroller file regExp.")

;;(global-set-key "\C-c\C-v" 'yarm)

(define-minor-mode yarm
  "Yet Another Ruby on Rails Minor Mode."
  :lighter " Yarm"
  :group 'yarm
  (if yarm
      (progn
        (setq minor-mode-map-alist
              (cons (cons 'yarm yarm-key-map)
                    minor-mode-map-alist))
        (run-hooks 'yarm-hook))
    nil))

(if (fboundp 'define-global-minor-mode)
    (define-global-minor-mode global-yarm
      yarm yarm-maybe
      :group 'yarm))

(defun yarm-maybe ()
  "What buffer `yarm' prefers."
  (if (and (not (minibufferp (current-buffer)))
           (yarm-set-root-path))
      (yarm 1)
    nil))

;; key-map
(defvar yarm-key-map
  (make-sparse-keymap)
  "Keymap for Yarm.")

(defun yarm-set-default-keymap ()
  "Set default key-map"
  (setq yarm-key-map
        (let ((map (make-sparse-keymap)))
          (define-key map "\C-cs" 'yarm-switch)
          (define-key map "\C-cm" 'yarm-switch-to-model)
          (define-key map "\C-cv" 'yarm-switch-to-view)
          (define-key map "\C-cc" 'yarm-switch-to-controller)
          (define-key map "\C-cf" 'yarm-switch-to-function)
          (define-key map "\C-ce" 'yarm-switch-to-partial)
          (define-key map "\C-cb" 'yarm-switch-to-file-history)
          (define-key map "\C-cM" 'yarm-open-models-dir)
          (define-key map "\C-cV" 'yarm-open-views-dir)
          (define-key map "\C-cC" 'yarm-open-controllers-dir)
          (define-key map "\C-cH" 'yarm-open-helpers-dir)
          (define-key map "\C-cL" 'yarm-open-layouts-dir)
          (define-key map "\C-cJ" 'yarm-open-js-dir)
          (define-key map "\C-cS" 'yarm-open-css-dir)
          (define-key map "\C-cT" 'yarm-open-tests-dir)
          (define-key map "\C-c\C-g" 'yarm-open-config-dir)

          (define-key map "\C-cl" 'anything-c-yarm-anything-only-source-yarm)
          (define-key map "\C-co" 'anything-c-yarm-anything-only-function)
          map)))

(defun yarm-is-model-file ()
  "Check whether current file is model file."
  (yarm-set-root-path)
  (if (not (string-match yarm-model-regexp (buffer-file-name)))
      nil
    (setq yarm-singular-name (match-string 1 (buffer-file-name)))
    (setq yarm-plural-name (pluralize-string yarm-singular-name))
    (setq yarm-current-file-type 'model)))

(defun yarm-is-view-file ()
  "Check whether current file is view file."
  (yarm-set-root-path)
  (if (not (string-match yarm-view-regexp (buffer-file-name)))
      nil
    (setq yarm-plural-name (match-string 1 (buffer-file-name)))
    (setq yarm-action-name (match-string 3 (buffer-file-name)))
    ;;(setq yarm-view-extension (match-string 4 (buffer-file-name)))
    (setq yarm-lower-camelized-action-name (yarm-lower-camelize yarm-action-name))
    (setq yarm-singular-name (singularize-string yarm-plural-name))
    (setq yarm-current-file-type 'view)))

(defun yarm-is-controller-file ()
  "Check whether current file is contoroller file."
  (yarm-set-root-path)
  (if (not (string-match yarm-controller-regexp (buffer-file-name)))
      nil
    (setq yarm-plural-name (match-string 1 (buffer-file-name)))
    (save-excursion
      (if
          (not (re-search-backward "def[ \t]*\\([a-zA-Z0-9_]+\\)[ \t]*" nil t))
          (re-search-forward "def[ \t]*\\([a-zA-Z0-9_]+\\)[ \t]*" nil t)))
    (setq yarm-action-name (match-string 1))
    (setq yarm-lower-camelized-action-name (yarm-lower-camelize yarm-action-name))
    (setq yarm-snake-action-name (yarm-snake yarm-action-name))
    (setq yarm-singular-name (singularize-string yarm-plural-name))
    (setq yarm-current-file-type 'controller)))

(defun yarm-is-file ()
  "Check whether current file is Ruby on Rail's file."
  (if (or (yarm-is-model-file)
          (yarm-is-controller-file)
          (yarm-is-view-file))
      t nil))

(defun yarm-get-current-line ()
  "Get current line."
  (thing-at-point 'line))

(defun yarm-set-root-path ()
  "Set root path."
  (yarm-is-root-path))

(defun yarm-is-root-path ()
  "Check root directory name and set regExp."
  (setq yarm-root-path (yarm-find-root-path))
  (if (not yarm-root-path)
      nil
    (string-match "^\\(.+/\\)\\([^/]+\\)/" yarm-root-path)
    (yarm-set-regexp)))

(defun yarm-find-root-path ()
  "Find app directory"
  (let ((current-dir default-directory))
    (loop with count = 0
          until (file-exists-p (concat current-dir "config/config.yml"))
          ;; Return nil if outside the value of
          if (= count yarm-root-path-search-limit)
          do (return nil)
          ;; Or search upper directories.
          else
          do (incf count)
          (setq current-dir (expand-file-name (concat current-dir "../")))
          finally return current-dir)))

(defun yarm-set-regexp ()
  "Set regExp."
  (setq yarm-model-regexp (concat yarm-root-path "app/models/\\([^/]+\\)\.rb"))
  (setq yarm-view-regexp (concat yarm-root-path "app/views/\\([^/]+\\)/\\([^/]+/\\)?\\([^/.]+\\)\\.\\([a-z\.]+\\)$"))
  (setq yarm-controller-regexp (concat yarm-root-path "app/controllers/\\([^/]+\\)_controller\.rb$")))

(defun yarm-switch-to-model ()
  "Switch to model."
  (interactive)
  (if (yarm-is-file)
      (yarm-switch-to-file (concat yarm-root-path "app/models/" yarm-singular-name ".rb"))
    (message "Can't find model name.")))

(defun yarm-switch-to-view ()
  "Switch to view."
  (interactive)
  (let ((view-files nil))
    (if (yarm-is-file)
        (progn
          (if (yarm-is-model-file) (setq yarm-plural-name (pluralize-string yarm-singular-name)))
          (setq view-files (yarm-set-view-list))
          (if view-files
              (cond
               ((= 1 (length view-files))
                (find-file (concat yarm-root-path "app/views/" yarm-plural-name "/" (car view-files))))
               (t (anything
                   '(((name . "Switch to view")
                      (candidates . view-files)
                      (display-to-real . (lambda (candidate)
                                           (concat yarm-root-path "app/views/" yarm-plural-name "/" candidate)
                                           ))
                      (type . file)))
                   nil nil nil nil)
                  ))
            (if (y-or-n-p "Make new file?")
                (progn
                  (unless (file-directory-p (concat yarm-root-path "app/views/" yarm-plural-name "/"))
                    (make-directory (concat yarm-root-path "app/views/" yarm-plural-name "/")))
                  (find-file (concat yarm-root-path "app/views/" yarm-plural-name "/" yarm-action-name "." yarm-view-extension)))
              (message (format "Can't find %s" (concat yarm-root-path "app/views/" yarm-plural-name "/" yarm-action-name "." yarm-view-extension))))))
      (message "Can't switch to view."))))

(defun yarm-set-view-list ()
  "Set view list"
  (let ((dir (concat yarm-root-path "app/views/" yarm-plural-name))
        (view-dir nil)
        (view-files nil))
    (unless (not (file-directory-p dir))
      (setq view-dir (remove-if-not (lambda (x) (file-directory-p (concat yarm-root-path "app/views/" yarm-plural-name "/" x))) (directory-files dir)))
      (setq view-dir (remove-if (lambda (x) (equal x "..")) view-dir))
      (loop for x in view-dir do (if (file-exists-p (concat yarm-root-path "app/views/" yarm-plural-name "/" x "/" yarm-snake-action-name "." yarm-view-extension))
                                     (unless (some (lambda (y) (equal (concat x "/" yarm-snake-action-name "." yarm-view-extension) y)) view-files)
                                       (push (concat x "/" yarm-snake-action-name "." yarm-view-extension) view-files))))
      (loop for x in view-dir do (if (file-exists-p (concat yarm-root-path "app/views/" yarm-plural-name "/" x "/" yarm-action-name "." yarm-view-extension))
                                     (unless (some (lambda (y) (equal (concat x "/" yarm-action-name "." yarm-view-extension) y)) view-files)
                                       (push (concat x "/" yarm-action-name "." yarm-view-extension) view-files)))))
    view-files))

(defun yarm-switch-to-controller ()
  "Switch to contoroller."
  (interactive)
  (if (yarm-is-file)
      (progn
        (if (file-exists-p (concat yarm-root-path "app/controllers/" yarm-plural-name "_controller.rb"))
            (progn
              (find-file (concat yarm-root-path "app/controllers/" yarm-plural-name "_controller.rb"))
              (goto-char (point-min))
              (if (not (re-search-forward (concat "def[ \t]*" yarm-lower-camelized-action-name "[ \t]*") nil t))
                  (progn
                    (goto-char (point-min))
                    (re-search-forward (concat "def[ \t]*" yarm-action-name "[ \t]*") nil t)))
              (recenter))
          (if (y-or-n-p "Make new file?")
              (find-file (concat yarm-root-path "app/controllers/" yarm-plural-name "_controller.rb"))
            (message (format "Can't find %s" (concat yarm-root-path "app/controllers/" yarm-plural-name "_controller.rb"))))))
    (message "Can't switch to contoroller.")))

(defun yarm-switch-to-file (file-path)
  "Switch to file."
  (if (file-exists-p file-path)
      (find-file file-path)
    (if (y-or-n-p "Make new file?")
        (find-file file-path)
      (message (format "Can't find %s" file-path)))))

(defun yarm-search-functions ()
  "Search function from current buffer."
  (let ((func-list nil))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "def[ \t]*\\([a-zA-Z0-9_]+\\)[ \t]*" nil t)
        (push (match-string 1) func-list))
      func-list)))

(defun yarm-switch-to-partial ()
  "Switch to partial. If region is active, make new partial file."
  (interactive)
  (let ((partial-name nil) (current-dir default-directory) (partial-file ""))
    (if (yarm-set-root-path)
        (if (string-match "render *:partial *=> *['\"]\\([-a-zA-Z0-9_\.]+\\)/?\\([-a-zA-Z0-9_\.]*\\)['\"]" (yarm-get-current-line))
            (progn
              (setq partial-file (match-string 1 (yarm-get-current-line)))
              (if (equal (match-string 2 (yarm-get-current-line)) "")
                  (setq partial-file (concat current-dir "_" (match-string 1 (yarm-get-current-line)) "." yarm-view-extension))
                (setq partial-file (concat current-dir "../" (match-string 1 (yarm-get-current-line)) "/_" (match-string 2 (yarm-get-current-line)) "." yarm-view-extension)))
              (if (file-exists-p partial-file)
                  (find-file partial-file)
                (if (y-or-n-p "Make new file?")
                    (find-file partial-file)
                  (message (format "Can't find %s" partial-file)))))
          (if (not (and (region-active-p)
                        (y-or-n-p "Can't find partial name. Make new file?")))
              (message "Can't find partial name.")
            (setq partial-name (read-string "Partial name (no extension): " "partial_name"))
            (if (not partial-name)
                (message "Can't find partial name.")
              (kill-region (point) (mark))
              (insert (concat "<%=render :partial => '" partial-name "' %>"))
              (find-file (concat current-dir "_" partial-name "." yarm-view-extension))
              (yank))))
      (message "Can't set root path."))))

(defun yarm-switch-to-function ()
  "Switch to function."
  (interactive)
  (let ((current-func nil))
    (if (and yarm-use-imenu
             (require 'imenu nil t))
        (anything 'anything-c-source-imenu)
      (if (or (yarm-is-controller-file)
              (yarm-is-model-file))
          (progn
            (setq current-func (yarm-search-functions))
            (anything
             '(((name . "Switch to current function")
                (candidates . current-func)
                (display-to-real . (lambda (candidate)
                                     (concat "def[ \t]*" candidate "[ \t]*")))
                (action
                 ("Switch to Function" . (lambda (candidate)
                                           (goto-char (point-min))
                                           (re-search-forward candidate nil t)
                                           (recenter)
                                           )))))
             nil nil nil nil))
        (message "Can't switch to function.")))))

(defun yarm-switch ()
  "Omni switch function."
  (interactive)
  (if (yarm-set-root-path)
      (cond
       ;;yarm-switch-to-partial
       ((string-match "render *:partial *=> *['\"]\\([-a-zA-Z0-9_\.]+\\)/?\\([-a-zA-Z0-9_\.]*\\)['\"]" (yarm-get-current-line))
        (yarm-switch-to-partial))
       ;;yarm-switch-to-controller
       ((yarm-is-view-file) (yarm-switch-to-controller))
       ;;yarm-switch-to-view
       ((yarm-is-controller-file) (yarm-switch-to-view))
       (t (message "Current buffer is neither view nor controller.")))
    (message "Can't set root path.")))

(defun yarm-switch-to-file-history ()
  "Switch to file history."
  (interactive)
  (historyf-back '(yarm)))

(defun yarm-open-dir (dir &optional recursive)
  "Open directory."
  (interactive)
  (let ((files nil)
        (path nil))
    (if (yarm-set-root-path)
        (if (file-directory-p (concat yarm-root-path dir))
            (anything
             '(((name . "Open directory")
                (init . (lambda ()
                          (setq path yarm-root-path)
                          (if recursive
                              (setq files (yarm-get-recuresive-file-list dir))
                            (setq files (directory-files (concat path dir))))))
                (candidates . files)
                (display-to-real . (lambda (candidate)
                                     (concat path dir candidate)
                                     ))
                (header-name . (lambda (name)
                                 (format "%s: %s" name dir)))
                (type . file)))
             nil nil nil nil)
          (message (concat "Can't open " yarm-root-path dir)))
      (message "Can't set root path."))))

(defun yarm-get-recuresive-file-list (dir)
  "Get file list recuresively."
  (let
      ((file-list nil))
    (loop for x in (yarm-get-recuresive-path-list (concat yarm-root-path dir))
          do (progn
               (string-match (concat yarm-root-path dir "\\(.+\\)") x)
               (push (match-string 1 x) file-list)))
    file-list))

(defun yarm-get-recuresive-path-list (file-list)
  "Get file path list recuresively."
  (let ((path-list nil))
    (unless (listp file-list)
      (setq file-list (list file-list)))
    (loop for x
          in file-list
          do (if (file-directory-p x)
                 (setq path-list
                       (append
                        (yarm-get-recuresive-path-list
                         (remove-if
                          (lambda(y) (string-match "\\.$\\|\\.svn" y)) (directory-files x t)))
                        path-list))
               (setq path-list (push x path-list))))
    path-list))

(defun yarm-open-models-dir ()
  "Open models directory."
  (interactive)
  (yarm-open-dir "app/models/"))

(defun yarm-open-views-dir ()
  "Open views directory."
  (interactive)
  (if (or (yarm-is-model-file) (yarm-is-controller-file) (yarm-is-view-file))
      (yarm-open-dir (concat "app/views/" yarm-plural-name "/"))
    (yarm-open-dir "app/views/" t)))

(defun yarm-open-controllers-dir ()
  "Open contorollers directory."
  (interactive)
  (yarm-open-dir "app/controllers/"))

(defun yarm-open-helpers-dir ()
  "Open helpers directory."
  (interactive)
  (yarm-open-dir "app/helpers/"))

(defun yarm-open-config-dir ()
  "Open config dir."
  (interactive)
  (yarm-open-dir "config/" t))

(defun yarm-open-layouts-dir ()
  "Open layouts directory."
  (interactive)
  (yarm-open-dir "app/views/layouts/" t))

(defun yarm-open-js-dir ()
  "Open JavaScript directory."
  (interactive)
  (yarm-open-dir "public/javascripts/" t))

(defun yarm-open-css-dir ()
  "Open css directory."
  (interactive)
  (yarm-open-dir "public/css/" t))

(defvar yarm-initial-input nil)
(defun yarm-get-initial-input ()
  (setq yarm-initial-input
        (buffer-substring-no-properties (point)
                                        (progn (save-excursion
                                                 (skip-syntax-backward "w_")
                                                 (point))))))

(defun yarm-camelize (str)
  "Change snake_case to Camelize."
  (let ((camelize-str str) (case-fold-search nil))
    (setq camelize-str (capitalize (downcase camelize-str)))
    (replace-regexp-in-string
     "_" ""
     camelize-str)))
;;(yarm-camelize "yarm_camelize")

(defun yarm-lower-camelize (str)
  "Change snake_case to lowerCamelize."
  (let ((head-str "") (tail-str "") (case-fold-search nil))
    (if (string-match "^\\([a-z]+_\\)\\([a-z0-9_]*\\)" (downcase str))
        (progn
          (setq head-str (match-string 1 (downcase str)))
          (setq tail-str (match-string 2 (capitalize str)))
          (if (string-match "_" head-str)
              (setq head-str (replace-match "" t nil head-str)))
          (while (string-match "_" tail-str)
            (setq tail-str (replace-match "" t nil tail-str)))
          (concat head-str tail-str))
      str)))
;;(yarm-lower-camelize "yarm_lower_camelize")

(defun yarm-snake (str) ;;copied from rails-lib.el
  "Change snake_case."
  (let ((case-fold-search nil))
    (downcase
     (replace-regexp-in-string
      "\\([A-Z]+\\)\\([A-Z][a-z]\\)" "\\1_\\2"
      (replace-regexp-in-string
       "\\([a-z\\d]\\)\\([A-Z]\\)" "\\1_\\2"
       str)))))
;;(yarm-snake "YarmSnake")
;;(yarm-snake "CYarmSnake")

;;; anything sources and functions

(when (require 'anything-show-completion nil t)
  (use-anything-show-completion 'anything-c-yarm-anything-only-function
                                '(length yarm-initial-input)))

(defvar yarm-candidate-function-name nil)

(defvar anything-c-source-yarm
  '((name . "Yarm Switch")
    (init
     . (lambda ()
         (if
             (and (yarm-set-root-path) (executable-find "grep"))
             (with-current-buffer (anything-candidate-buffer 'local)
               (call-process-shell-command
                (concat "grep '[^_]def' "
                        yarm-root-path
                        "app/controllers/*_controller.rb --with-filename")
                nil (current-buffer))
               (goto-char (point-min))
               (while (re-search-forward (concat yarm-root-path "app/controllers/\\([^\\/]+\\)_controller\.rb:.*def +\\([0-9a-zA-Z_-\.\?!=]+\\).*$") nil t)
                 (message (match-string 1))
                 (replace-match (concat (match-string 1) " / " (match-string 2))))
               )
           (with-current-buffer (anything-candidate-buffer 'local)
             (call-process-shell-command nil nil (current-buffer)))
           )))
    (candidates-in-buffer)
    (display-to-real . anything-c-yarm-set-names)
    (action
     ("Switch to Contoroller" . (lambda (candidate)
                                  (anything-c-yarm-switch-to-controller)))
     ("Switch to View" . (lambda (candidate)
                           (anything-c-yarm-switch-to-view)))
     ("Switch to Model" . (lambda (candidate)
                            (anything-c-yarm-switch-to-model))))))

(defun anything-c-yarm-set-names (candidate)
  "Set names by display-to-real"
  (progn
    (string-match "\\(.+\\) / \\(.+\\)" candidate)
    (setq yarm-plural-name (match-string 1 candidate))
    (setq yarm-action-name (match-string 2 candidate))
    (setq yarm-singular-name (singularize-string yarm-plural-name))
    (setq yarm-lower-camelized-action-name yarm-action-name)
    (setq yarm-snake-action-name (yarm-snake yarm-action-name))))

(defun anything-c-yarm-switch-to-view ()
  "Switch to view."
  (progn
    (yarm-set-root-path)
    (cond ((file-exists-p (concat yarm-root-path "app/views/" yarm-plural-name "/" yarm-snake-action-name "." yarm-view-extension))
           (find-file (concat yarm-root-path "app/views/" yarm-plural-name "/" yarm-snake-action-name "." yarm-view-extension)))
          ((file-exists-p (concat yarm-root-path "app/views/" yarm-plural-name "/" yarm-action-name "." yarm-view-extension))
           (find-file (concat yarm-root-path "app/views/" yarm-plural-name "/" yarm-action-name "." yarm-view-extension)))
          ((y-or-n-p "Make new file?")
           (unless (file-directory-p (concat yarm-root-path "app/views/" yarm-plural-name "/"))
             (make-directory (concat yarm-root-path "app/views/" yarm-plural-name "/")))
           (find-file (concat yarm-root-path "app/views/" yarm-plural-name "/" yarm-action-name "." yarm-view-extension)))
          (t (message (format "Can't find %s" (concat yarm-root-path "app/views/" yarm-plural-name "/" yarm-action-name "." yarm-view-extension)))))))

(defun anything-c-yarm-switch-to-controller ()
  "Switch to contoroller."
  (yarm-set-root-path)
  (if (file-exists-p (concat yarm-root-path "app/controllers/" yarm-plural-name "_controller.rb"))
      (progn
        (find-file (concat yarm-root-path "app/controllers/" yarm-plural-name "_controller.rb"))
        (goto-char (point-min))
        (if (not (re-search-forward (concat "def[ \t]*" yarm-lower-camelized-action-name "[ \t]*") nil t))
            (progn
              (goto-char (point-min))
              (re-search-forward (concat "def[ \t]*" yarm-action-name "[ \t]*") nil t))))
    (if (file-exists-p (concat yarm-root-path yarm-plural-name "_controller.rb"))
        (progn
          (find-file (concat yarm-root-path yarm-plural-name "_controller.rb"))
          (goto-char (point-min))
          (if (not (re-search-forward (concat "def[ \t]*" yarm-lower-camelized-action-name "[ \t]*") nil t))
              (progn
                (goto-char (point-min))
                (re-search-forward (concat "def[ \t]*" yarm-action-name "[ \t]*") nil t))))
      (if (y-or-n-p "Make new file?")
          (find-file (concat yarm-root-path "app/controllers/" yarm-plural-name "_controller.rb"))
        (message (format "Can't find %s" (concat yarm-root-path "app/controllers/" yarm-plural-name "_controller.rb")))))))

(defun anything-c-yarm-switch-to-model ()
  "Switch to model."
  (yarm-set-root-path)
  (if (file-exists-p (concat yarm-root-path "app/models/" yarm-singular-name ".rb"))
      (find-file (concat yarm-root-path "app/models/" yarm-singular-name ".rb"))
    (if (y-or-n-p "Make new file?")
        (find-file (concat yarm-root-path "app/models/" yarm-singular-name ".rb"))
      (message (format "Can't find %s" (concat yarm-root-path "app/models/" yarm-singular-name ".rb"))))))

(defun anything-c-yarm-switch-to-file-function (dir)
  "Switch to file and search function."
  (yarm-set-root-path)
  (if (not (file-exists-p (concat yarm-root-path dir yarm-singular-name ".rb")))
      (if (y-or-n-p "Make new file?")
          (find-file (concat yarm-root-path dir yarm-singular-name ".rb"))
        (message (format "Can't find %s" (concat yarm-root-path dir yarm-singular-name ".rb"))))
    (find-file (concat yarm-root-path dir yarm-singular-name ".rb"))
    (goto-char (point-min))
    (re-search-forward (concat "def[ \t]*" yarm-candidate-function-name "[ \t]*") nil t)))

(defvar anything-c-source-yarm-model-function
  '((name . "Yarm Model Function Switch")
    (init
     . (lambda ()
         (if
             (and (yarm-set-root-path) (executable-find "grep"))
             (with-current-buffer (anything-candidate-buffer 'local)
               (call-process-shell-command
                (concat "grep '[^_]def' "
                        yarm-root-path
                        "app/models/*.rb --with-filename")
                nil (current-buffer))
               (goto-char (point-min))
               (while (not (eobp))
                 (if (not (re-search-forward ".+\\/\\(.+\\)\.rb:.*def +\\([0-9a-zA-Z_\.\?!=-]+\\).*$" nil t))
                     (goto-char (point-max))
                   (setq class-name (yarm-camelize (match-string 1)))
                   (setq function-name (match-string 2))
                   (delete-region (point) (save-excursion (beginning-of-line) (point)))
                   (insert (concat class-name "::" function-name))
                   )))
           (with-current-buffer (anything-candidate-buffer 'local)
             (call-process-shell-command nil nil (current-buffer)))
           )))
    (candidates-in-buffer)
    (display-to-real . anything-c-yarm-set-names2)
    (action
     ("Switch to Function" . (lambda (candidate)
                               (anything-c-yarm-switch-to-file-function "app/models/")))
     ("Insert" . (lambda (candidate)
                   (insert candidate))))))

(defun anything-c-yarm-set-names2 (candidate)
  "Set names by display-to-real"
  (progn
    (string-match "\\(.+\\)::\\(.+\\)" candidate)
    (setq yarm-camelized-singular-name (match-string 1 candidate))
    (setq yarm-candidate-function-name (match-string 2 candidate))
    (setq yarm-singular-name (yarm-snake yarm-camelized-singular-name))))

(defun anything-c-yarm-anything-only-source-yarm ()
  "anything only anything-c-source-yarm and anything-c-source-yarm-model-function."
  (interactive)
  (anything (list anything-c-source-yarm
                  anything-c-source-yarm-model-function)
            nil "Find Rails Sources: " nil nil))

(defun anything-c-yarm-anything-only-function ()
  "anything only anything-c-source-yarm-function."
  (interactive)
  (let* ((initial-pattern (regexp-quote (or (thing-at-point 'symbol) ""))))
    (anything (list anything-c-source-yarm-model-function) initial-pattern "Find Rails Functions: " nil)))

(defun anything-c-yarm-anything-only-model-function ()
  "anything only anything-c-source-yarm-model-function."
  (interactive)
  (let* ((initial-pattern (regexp-quote (or (thing-at-point 'symbol) ""))))
    (anything '(anything-c-source-yarm-model-function) initial-pattern "Find Model Functions: " nil)))

;; mode provide
(provide 'yarm)

;;; end
;;; yarm.el ends here