;;; php-fh.el --- PHP Functions Highlighter
;; -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2024 Philippe Ivaldi
;;
;; Author: Philippe Ivaldi <emacs@MY-NAME.me>
;; Maintainer: Philippe Ivaldi <emacs@MY-NAME.me>
;; Created: September 08, 2024
;; Version: 0.0.1
;; Keywords: languages php highlight php-mode
;; Package-Requires: ((php-mode "2.0") (emacs "24.4"))
;; Homepage: https://github.com/pivaldi/php-fh
;;
;;; Commentary:
;; This file is not part of GNU Emacs.
;; See the file README.org for further information.

;;  Description

;;  Provide font highlighting of PHP functions within php-mode.

;;; Code:

(require 'php-mode)

;;;###autoload
(defgroup php-fh nil
  "PHP Functions Highlighter."
  :tag "PHP"
  :prefix "php-fh-"
  :group 'languages
  :link '(url-link :tag "Source code repository" "https://github.com/pivaldi/php-fh")
  :link '(url-link :tag "Executable dependency" "https://www.php.net/"))

;;;###autoload
(defcustom php-fh-user-functions-name '("empty")
  "List of PHP user defined functions that php-fh must highlight."
  :type '(repeat string)
  :group 'php-fh)

;;;###autoload
(defcustom php-fh-php-generate-funcs-code "foreach (get_defined_functions()['internal'] as $func) {
    echo $func . \"\n\";
}"
  "The PHP code to generate the native PHP functions."
  :type 'string
  :group 'php-fh)

;;;###autoload
(defcustom php-fh-php-cmd (executable-find "php")
  "The PHP command."
  :type 'string
  :group 'php-fh)


(defvar php-fh-data-dir
  (let ((dname "php-highlight/"))
    (if (eq system-type (or 'cygwin 'windows-nt 'ms-dos))
        (expand-file-name dname (getenv-internal "APPDATA"))
      (expand-file-name dname (or (getenv-internal "XDG_DATA_HOME") "~/.local/share"))))
  "Directory where the generated list of php functions are stored.")

(defvar php-fh-generated-php-funcs-file-name "php-funcs.txt"
  "The file name containing all the generated php functions.")

(defun php-fh--get-generated-php-funcs-file-path ()
  (format "%s%s" php-fh-data-dir php-fh-generated-php-funcs-file-name))

;;;###autoload
(defun php-fh-generate-php-func-file (&optional fname)
  "Retrieve and write in the file FNAME the list of php functions."
  (interactive "P")
  (let*
      ((curdir (file-name-directory (symbol-file 'php-fh)))
       (scriptpath (format "%s%s" curdir "scripts/generate-php-func.php")))
    (unless (file-directory-p php-fh-data-dir)
      (make-directory php-fh-data-dir))
    (with-temp-file (or fname (php-fh--get-generated-php-funcs-file-path))
      (insert (shell-command-to-string (format "%s -r %s" php-fh-php-cmd (shell-quote-argument php-fh-php-generate-funcs-code)))))))

(defun php-fh--add-function-keywords (function-keywords)
  (let* ((keyword-regexp
          (concat "\\<\\(" (regexp-opt function-keywords) "\\)(")))
    (font-lock-add-keywords 'php-mode `((,keyword-regexp 1 font-lock-function-name-face)))))

(defun php-fh--nth-list (list first count)
  "Return a copy of LIST, which may be an assoc list.
The elements of LIST are not copied, just the list structure itself."
  (if (consp list)
      (let ((res nil)
            (n first)
            (last (min (+ first count) (length list))))
        (while
            (and (push (nth n list) res)
                 (setq n (+ 1 n))
                 (< n last))) (nreverse res)) nil))

(defun php-fh--lines-to-list-from-file (file)
  "Return a list of lines of FILE."
  (require 'lisp-mnt)
  (lm-with-file file
    (split-string (buffer-string) "\n" t)))

;;;###autoload
(defun php-fh-highlight ()
  "Add all the known PHP functions as keyword to `font-lock-function-name-face'.
Knonw functions are those contained in the file get by the function
`php-fh--get-generated-php-funcs-file-path' plus those added to the
variable `php-fh-user-functions-name'."
  (unless (file-readable-p (php-fh--get-generated-php-funcs-file-path))
    (php-fh-generate-php-func-file))
  (let* ((all-func (php-fh--lines-to-list-from-file (php-fh--get-generated-php-funcs-file-path)))
         (l (length all-func))
         (n 0)
         (php-functions-name nil))
    ;; regexp-opt cannot parse all-func at once (failed in php-add-function-keywords)
    (while (and (< n l)
                (add-to-list 'php-functions-name (php-fh--nth-list all-func n 150) t)
                (setq n (+ n 150))))
    (add-to-list 'php-functions-name php-fh-user-functions-name)
    (dolist (php-function-name php-functions-name)
      (php-fh--add-function-keywords php-function-name)))
  t)

(provide 'php-fh)
;;; php-fh.el ends here
