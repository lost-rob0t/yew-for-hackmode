;;
;; dl-list - a doubly-linked list
;;

;; $Revision: 1.2 $

;; People tell me you should never use doubly-linked list.
;; I'm not quite sure I believe them, but after this there is a zipper-ish
;; structure that does just about the same thing while taking less space,
;; like about by half. I'm not sure about performance though.
;;
;; This actually demonstrates some palpable flaws in Common Lisp!
;; - sequences should be generic (and still be fast)
;;   i.e. objects all the way down (like dylan or clojure).
;; - Classes can't really be self referential

(defpackage :dl-list
  (:documentation "The nefarious doubly-linked list anti-pattern.")
  (:use :cl)
  (:export
   #:dl-list
   #:dl-node
   #:dl-content
   #:dl-prev
   #:dl-next
   #:make-dl-list
   #:dl-push
   #:dl-pop
   #:dl-list-do
   #:dl-list-do-element
   #:dl-list-do-backward
   #:dl-list-do-backward-element
   ))
(in-package :dl-list)

(defclass dl-list ()
  (
; I want to be able to specifiy the types like this:
;    (prev :initarg :prev :accessor dl-prev :initform nil
; 	 :type (or null dl-list-type))
;    (next :initarg :next :accessor dl-next :initform nil
; 	 :type (or null dl-list-type))
; but it doesn't work. So what should I do? For now I just omit the types.
   (prev :initarg :prev :accessor dl-prev :initform nil)
   (next :initarg :next :accessor dl-next :initform nil)
   (content :initarg :content :accessor dl-content :initform nil))
  (:documentation "A doubly linked list."))

;; I don't really know if specifing the type will make things faster or not.
;; @@@ Perhaps I could test it out.
(deftype dl-node () '(or null dl-list))

(defmacro dl-push (lst obj)
  "Push an element onto the front of the list, modifying it."
;  (declare (type dl-list lst))
  `(let ((new (make-instance 'dl-list :next ,lst :content ,obj)))
    (setf (dl-prev ,lst) new)
    (setf ,lst new)))

(defmacro dl-pop (lst)
  "Pop an element off from the front of the list, modifying it."
;  (declare (type dl-list lst))
  `(prog1 (dl-content ,lst)
    (setf ,lst (dl-next ,lst)
          (dl-prev ,lst) nil)))

(defun make-dl-list (&key from-list)
  "Gratuitous abbreviation."
  (let ((l (make-instance 'dl-list)))
    (when from-list
      (loop :for i :in from-list :do
	 (dl-push l i)))
    l))

(defun dl-list-do (list func)
  "Call FUNC with the content each successive element of LIST."
  (declare (type dl-list list))
  (loop :for i = list :then (dl-next i)
     :do (funcall func (dl-content i))
     :while (dl-next i)))

(defun dl-list-do-element (list func)
  "Call FUNC with each successive element of LIST."
  (declare (type dl-list list))
  (loop :for i = list :then (dl-next i)
     :do (funcall func i)
     :while (dl-next i)))

(defun dl-list-do-backward (list func)
  "Call FUNC with the content of each element of LIST, going backwards."
  (declare (type dl-list list))
  (loop :for i = list :then (dl-prev i)
	:do (funcall func (dl-content i))
	:while (dl-prev i)))

(defun dl-list-do-backward-element (list func)
  "Call FUNC with each element of LIST, going backwards."
  (declare (type dl-list list))
  (loop :for i = list :then (dl-prev i)
	:do (funcall func i)
	:while (dl-prev i)))

;; @@@ Actually, it could be able to be readable, right?
(defmethod print-object ((obj dl-list) stream)
  "Print a dl-list in an unreadable way."
  (print-unreadable-object (obj stream :type t :identity t)
    (write-char #\( stream)
    (loop :for i = obj :then (dl-next i)
	  :do (write (dl-content i) :stream stream)
	  :while (and (dl-next i) (write-char #\space stream)))
    (write-char #\) stream)))

;; @@@ how 'bout some tests?

#| 
Here's what I came up with after after reading some crap about the 
zipper data structure and not really understanding it.

(3 2 1) (4 5 6 7 8) = 1 2 3 4 5 6 7
^        ^                  ^

next
(4 3 2 1) (5 6 7 8) = 1 2 3 4 5 6 7
^          ^                  ^

prev
(2 1) (3 4 5 6 7 8) = 1 2 3 4 5 6 7
^      ^
|#

#| @@@ NOT DONE YET

(defclass zlist ()
  ((left  :initarg :left  :accessor zl-left  :initform nil :type list)
   (right :initarg :right :accessor zl-right :initform nil :type list)
   (head  :initarg :head  :accessor zl-head  :initform nil :type list)
   (tail  :initarg :tail  :accessor zl-tail  :initform nil :type list))
  (:documentation "A zipper list."))

(defmethod initialize-instance :after ((z zlist) &rest initargs
				       &key initial-contents
				       &allow-other-keys)
  (declare (type list initial-contents))
  (when initial-contents
    (setf (zl-left z) (reverse initial-contents))
    (setf (zl-head z) (last (zl-left z)))))

(defun zlist (&rest args)
  "Gratuitous abbreviation."
  (make-instance 'zlist :initial-contents args))

(defmacro zl-push (obj z)
  "Push an element onto the front of the list, modifying it."
  (declare (type zlist z))
  `(if (zl-head ,z)
       ;; Non-empty, so cons on to end of head, which is actually the beginning.
       (setf (cdr (zl-head ,z)) (cons ,obj nil))
       ;; Empty list, just set the head and left.
       (setf (zl-left ,z) (list ,obj)
	     (zl-head ,z) (zl-left ,z))))

(defmacro zl-pop (lst)
  "Pop an element off from the front of the list, modifying it."
  (declare (type zlist lst))
  `(prog1 (zl-head ,lst)
     (setf (car (zl-head ,lst)) nil
	   (zl-head ,lst) (last (zl-left ,lst)))))

(defmacro zl-next (lst)
  "Go to the next element. Modifies the list."
  )

(defmacro zl-prev (lst)
  "Go to the previous element. Modifies the list."
  )

(defun zl-list-do (lst func)
  "Call func with each successive element of the list."
  (declare (type dl-list lst))
  (loop for i = lst then (zl-next i)
	do (funcall func (zl-content i))
	while (dl-next i)))

(defun zl-list-do-backward (lst func)
  "Call func with each element of the list, going backwards."
  (declare (type dl-list lst))
  (loop for i = lst then (dl-prev i)
	do (funcall func (dl-content i))
	while (dl-prev i)))

;; @@@ Actually, it could be able to be readable, right???
(defmethod print-object ((obj zl-list) stream)
  "Print a dl-list in an unreadable way."
  (print-unreadable-object (obj stream :type t :identity t)
    (write-char #\( stream)
    (loop for i = obj then (zl-next i)
	  do (write (zl-content i) :stream stream)
	  while (and (zl-next i) (write-char #\space stream)))
    (write-char #\) stream)))

|#

;; EOF
