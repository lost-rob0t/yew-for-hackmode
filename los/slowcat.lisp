;;;
;;; slowcat.lisp - Make things go by slowly, like the old days.
;;;

(defpackage :slowcat
  (:documentation "Make things go by slowly, like the old days.")
  (:use :cl :dlib :opsys)
  (:export
   ;; Main entry point
   #:slowcat
   ;#:slowcat-main
   #:!slowcat
   ))
(in-package :slowcat)

(declaim #.`(optimize ,.(getf los-config::*config* :optimization-settings)))

(defun slowcat (stream-or-file &key (delay .02) (unit :char))
  ;; (flet ((catty (s)
  ;; 	   (loop :with line
  ;; 	      :while (setf line (read-line s nil))
  ;; 	      :do
  ;; 	      (write-line line)
  ;; 	      (sleep delay))))
  ;;   (if (streamp stream-or-file)
  ;; 	(catty stream-or-file)
  ;; 	(with-open-file (s (quote-filename stream-or-file) :direction :input)
  ;; 	  (catty s)))))
  (with-open-file-or-stream (s (quote-filename stream-or-file) :direction :input)
    (ecase unit
      (:line
       (loop :with line
	  :while (setf line (read-line s nil))
	  :do
	  (write-line line)
	  (finish-output)
	  (sleep delay)))
      (:char
       (loop :with line
	  :while (setf line (read-char s nil))
	  :do
	  (write-char line)
	  (finish-output)
	  (sleep delay))))))

#| This seems fairly superfluous with lish working

(defun slowcat-main ()
  "Invocation of slowcat from the command line."
  (if (<= (length (nos:lisp-args)) 2)
      (slowcat-stream *standard-input*)
      (let* ((args (nos:lisp-args))
	     (delay .02)
	     (p (position "-d" (nos:lisp-args) :test #'string=))
	     (d (and p (read-from-string (elt (nos:lisp-args) (1+ p))))))
	(when (and d (numberp d))
	  (setf delay d)
	  (setf args (loop :for i :from 0 :below (length args)
			:if (not (or (= i p) (= i (1+ p))))
			:collect (elt args i))))
	(loop :for file :in (subseq args 2)
	   :do
	   (slowcat file :delay delay)))))
|#

#+lish
(lish:defcommand slowcat
  ((delay number :short-arg #\d :default .001)
   (unit choice :short-arg #\u :default :char :choices '(:line :char))
   (files pathname :repeating t))
  "Make things go by slowly, like the old days."
  (if files
      (loop :for f :in files :do
	 (slowcat f :delay delay :unit unit))
      (slowcat *standard-input* :delay delay :unit unit)))

;; EOF
