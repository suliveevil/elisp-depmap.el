
(require 'projectile)

(defvar varprefix "(\\(def\\(var\\|un\\|subst\\)\\|setq\\) ")
(defvar varfullix "\\(\(setq\|\(def\(un\|var\|subst\)\)\) \(-?\\w+\)+")

(defmacro processline (nachcolon &rest rest)
  "Process a line, extract values between colons, and search for NACHCOLON
immediately after second colon, then perform REST."
  `(let ((bound (line-end-position))
         (bfunc #'buffer-substring-no-properties))
     (let* ((p2 (search-forward ":" bound t))
            (p3 (search-forward ":" bound t)))
       (when p3
         (let ((filename (funcall
                          bfunc (line-beginning-position) (1- p2)))
               (linenumb (funcall bfunc p2 (1- p3)))
               (nextchar (funcall bfunc p3 (1+ p3))))
           (unless (or (string-prefix-p "Ripgrep finished" filename)
                       (string= ,nachcolon nextchar))
             ,@rest))))))

(defun process-this-line ()
  "Parse the current line in the ripgrep buffer to extract definitions.
Specifically the filename, linenumber, and variable name."
  (save-excursion
    (processline
     " "
     (let* ((m0 (search-forward-regexp varprefix bound t))
            (m1 (point))
            (m2 (search-forward-regexp
                 "\\( \\|)\\|$\\)" nil t))
            (vartype (funcall bfunc (1+ p3) (1- m0)))
            (varname (funcall bfunc m1 (1- m2))))
       `(,varname ,vartype ,linenumb ,filename)))))


(defun getcrossrefs-forvar (vname)
  "Get all references to toplevel definition VNAME."
  (let ((rmapp nil)
        (rbuff (projectile-ripgrep vname t)))
    (with-current-buffer rbuff
      (goto-line 4)
      (while (search-forward "\n" nil t)
        (processline
         "("
         ;; we have a gap where our vname should follow
         (if (search-forward vname bound t)
             ;; return the parent function, or filename
             (add-to-list
              'rmapp
              (or '(getparentfunc filename linenumb) filename))))))))


(setq topdefs nil)
(setq grepbuffer nil)

(defun killall-grep-buffers ()
  (dolist
      (buff (--filter
             (string-prefix-p
              "*grep"
              (buffer-name it))
             (buffer-list)))
    (kill-buffer buff))
  (kill-buffer "*Backtrace*"))

(defun processdefinitions ()
  "Grab all definitions in a project, and process cross references."
  (add-hook 'projectile-grep-finished-hook 'processdefinitions-delegate)
  (let ((nowbuff (current-buffer))
        (pbuffer (projectile-grep
                  "(\\(setq\\|\\(def\\(un\\|var\\|subst\\)\\)\\)\ " nil)))
    (setq grepbuffer pbuffer)
    (switch-to-buffer nowbuff)))

(defun processdefinitions-delegate ()
  (let ((bname grepbuffer))
    (with-current-buffer bname
      (goto-line 4)
      (while (search-forward "\n" nil t)
        (let* ((vdefs (process-this-line))
               (vnams (car vdefs))
               ;;(xrefs (getcrossrefs-forvar vnams))
               )
          (add-to-list 'topdefs `(,vdefs xrefs))))
      (killall-grep-buffers)
      (remove-hook 'ripgrep-search-finished-hook 'processdefinitions-delegate))))
