;;;								-*- Lisp -*-
;;; view-image-fb.asd - System definition for view-image-fb
;;;

(defsystem view-image-fb
    :name               "view-image-fb"
    :description        "Image viewer Linux framebuffer driver."
    :version            "0.1.0"
    :author             "Nibby Nebbulous <nibbula -(. @ .)- gmail.com!uucp>"
    :license            "GPLv3"
    :source-control	:git
    :long-description   "Linux framebuffer driver for the image viwer."
    :depends-on (:dlib :dlib-misc :char-util :unicode :inator :image :view-image
		 :linux-fb)
    :components
    ((:file "view-image-fb")))
