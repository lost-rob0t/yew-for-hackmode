;;
;; char-util.lisp - General utility functions dealing with characters.
;;

;; $Revision: 1.1 $

(defpackage :char-util
  (:documentation "Utility functions for characters.")
  (:use :cl)
  (:export
   #:meta-char
   #:meta-char-p
   #:un-meta
   #:nice-char 
   ))
(in-package :char-util)

(defun meta-char (c)
  "Turn the meta (8th) bit on in the code representation of the
   given character."
  (code-char (logior (ash 1 7) (char-code c))))

(defun meta-char-p (c)
  "Is the given number a meta character as a char code?"
  (> (logand (ash 1 7) c) 0))

;; perhaps: one for chars, one for numbers (as char codes)
; (defmethod meta-char-p ((c @@@))
;   (> (logand (ash 1 7) c) 0))

(defun un-meta (c)
  "Return the non-meta character verion of character code C"
  (code-char (logand (- (ash 1 7) 1) c)))

(defun nice-char (c)
  "ASCII dependant nice character formatting"
  (let ((cc (if (characterp c) (char-code c) nil)))
    (cond
      ((and cc (meta-char-p cc))
       (format nil "M-~a" (nice-char (un-meta cc))))
      ((and cc (= cc 27))
       (format nil "ESC"))
      ((and cc (= cc (char-code #\space)))
       (format nil "SPACE"))
      ((and cc (< cc (char-code #\space)))
       (format nil "C-~(~c~)" (code-char (+ cc (char-code #\@)))))
      ((and cc (= cc 127)
       (format nil "C-?")))
     (cc (format nil "~a" c))
     (t (format nil "~s" c)))))

;; EOF
