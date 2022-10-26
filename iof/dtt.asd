;;;								-*- Lisp -*-
;;; dtt.asd -- System definition for dtt
;;;

(defsystem dtt
    :name               "dtt"
    :description        "Delimited Text Tables"
    :version            "0.1.0"
    :author             "Nibby Nebbulous <nibbula -(. @ .)- gmail.com>"
    :license            "GPL-3.0-only"
    :source-control	:git
    :long-description
    "This handles CSV and other delimited text format files."
    :depends-on (:dlib :collections :table :syntax-lisp)
    :components
    ((:file "dtt")))
