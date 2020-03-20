;;; package-map.el --- Generate a graphviz map of functions and definitions -*- lexical-binding: t; -*-

;; Copright (C) 2020 Mehmet Tekman <mtekman89@gmail.com>

;; Author: Mehmet Tekman
;; URL: https://github.com/mtekman/remind-bindings.el
;; Keywords: outlines
;; Package-Requires: ((emacs "26.1") (projectile "2.2.0-snapshot"))
;; Version: 0.1

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;;; Code:
(require 'package-map-parse)


(defun makesummarytable ()
  (let ((hashtable (generatemap)))
    (with-current-buffer (find-file "graphviz2.org")
      (erase-buffer)
      (insert "| Type | Name | File | #Lines | #Mentions | Mentions |\n|--\n")
      (maphash
       (lambda (funcname info)
         (let ((vfile (plist-get info :file))
               (vbegs (plist-get info :line-beg))
               (vends (plist-get info :line-end))
               (vtype (plist-get info :type))
               (vment (plist-get info :mentions)))
           (insert
            (format "| %s | %s | %s | %d | %d | %s |\n"
                    vtype funcname vfile
                    (if vends (- vends vbegs) 1)
                    (length vment)
                    vment))))
       hashtable)
      (org-table-align))))



(defun getcolors (hashtable accesskey1 &optional accesskey2)
  "Get a list of colors."
  (let ((uniqkeys nil)
        (colors '("red" "blue" "green" "orange" "purple" "gray" "yellow" "pink")))
    (maphash
     (lambda (key annot)
       (let ((val (plist-get annot accesskey1)))
         (cl-pushnew val uniqkeys)))
     hashtable)
    (let ((numvals (length uniqkeys)))
      (cl-subseq tmpcol 0 numvals))))


(defun getshape (hashtable accesskey1 &optional accesskey2)
  "Get a list of shapes."
  (
  
  (let ((uniqkeys nil)
        (colors '("red" "blue" "green" "orange" "purple" "gray" "yellow" "pink")))
    (maphash
     (lambda (key annot)
       (let ((val (plist-get annot accesskey1)))
         (cl-pushnew val uniqkeys)))
     hashtable)
    (let ((numvals (length uniqkeys)))
      (cl-subseq tmpcol 0 numvals))))


(defun makedotfile ()
  (let ((hashtable (generatemap)))
    ;; TODO: implement these
    (let ((list-colors (getcolors hashtable :file))
          (list-height (getheights hashtable :line-beg :line-end))
          (list-shapes (getshapes hashtable :type)))
      (with-current-buffer (find-file "graphviz2.dot")
        (erase-buffer)
        (insert "strict graph {\n")
        (maphash
         (lambda (funcname info)
           (let ((vfile (plist-get info :file))
                 (vbegs (plist-get info :line-beg))
                 (vends (plist-get info :line-end))
                 (vtype (plist-get info :type))
                 (vment (plist-get info :mentions)))
             (let ((numlines (if vends (- vends vbegs) 1)))
               (insert (format "  \"%s\" [height=%f]\n"
                               funcname (1+ (/ numlines 10)))))
             (dolist (mento vment)
               (unless (eq funcname mento)
                 (insert (format "  \"%s\" -- \"%s\" [color=\"%s\"]\n"
                                 funcname mento vfile))))))
         hashtable)
        (insert "}\n")))))



;; Logic:
;; -- if there is more than 1 file, then create several columns.
;; -- if only 1 file, more free for all approach.

;; [node]
;;  -- height (size of function), label (vname), color (file)
;; [edge]
;;  --


(provide 'package-map)
;;; package-map.el ends here