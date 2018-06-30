;;;								-*- Lisp -*-
;;; view-lisp.asd - System definition for view-lisp
;;;

(defsystem view-lisp
    :name               "view-lisp"
    :description        "View things in the Lisp system."
    :version            "0.1.0"
    :author             "Nibby Nebbulous <nibbula -(. @ .)- gmail.com>"
    :license            "GPLv3"
    :source-control	:git
    :long-description
    "Use the tree viewer to browse through some of the multitudinous entities
residing in your running Lisp system. This can help you pretend that your
memory is a nice neat tree, rather than the vast corrals of scattered refuse
that it is."
    :depends-on (:dlib :tree-viewer :dlib-interactive)
    :components
    ((:file "view-lisp")))
