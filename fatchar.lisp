;;
;; fatchar.lisp - Characters with attributes.
;;

(defpackage :fatchar
  (:documentation "Characters with attributes.
Defines a FATCHAR which is a character with color and font attributes.
Define a FATCHAR-STRING as a vector of FATCHARS.
Define a FAT-STRING as a struct with a FATCHAR-STRING so we can specialize.
Define a TEXT-SPAN as a list representation of a FAT-STRING.
")
  (:use :cl :dlib :stretchy :char-util :collections :ochar :ostring :color)
  (:export
   #:fatchar
   #:fatchar-p
   #:make-fatchar
   #:fatchar-c #:fatchar-fg #:fatchar-bg #:fatchar-line #:fatchar-attrs
   #:fatchar-string
   #:fat-string #:fat-string-string
   #:fatchar-init
   #:copy-fatchar
   #:same-effects
   #:fatchar=
   #:make-fat-string
   #:make-fatchar-string
   #:fatchar-string-to-string
   #:string-vector
   #:fat-string-to-string
   #:fat-string< #:fat-string> #:fat-string= #:fat-string/=
   #:fat-string<= #:fat-string>= #:fat-string-lessp #:fat-string-greaterp
   #:fat-string-equal #:fat-string-not-equal
   #:fat-string-not-lessp #:fat-string-not-greaterp
   #:span-length
   #:fat-string-to-span
   #:fatchar-string-to-span
   #:span-to-fat-string #:ß
   #:span-to-fatchar-string
   #:process-ansi-colors
   #:remove-effects
   ))
(in-package :fatchar)

;; (declaim (optimize (speed 3) (safety 0) (debug 1) (space 0) (compilation-speed 0)))
(declaim (optimize (speed 0) (safety 3) (debug 3) (space 0) (compilation-speed 0)))

(defstruct fatchar
  "A character with attributes."
  (c (code-char 0) :type character)
  (fg nil)
  (bg nil)
  (line 0 :type fixnum)
  (attrs nil :type list))

(defun fatchar-init (c)
  "Initialize a fatchar with the default vaules."
  (setf (fatchar-c     c)	(code-char 0)
	(fatchar-fg    c)	:white
	(fatchar-bg    c)	:black
	(fatchar-line  c)	0
	(fatchar-attrs c)	nil))

;; I think we can just use the one made by defstruct?
;; (defun copy-fatchar (c)
;;   (declare (type fatchar c))
;;   (when c
;;     (make-fatchar
;;      :c	    (fatchar-c c)
;;      :fg    (fatchar-fg c)
;;      :bg    (fatchar-bg c)
;;      :line  (fatchar-line c)
;;      :attrs (fatchar-attrs c))))

(defun same-effects (a b)
  "Return true if the two fatchars have the same colors and attributes."
  (and (equal (fatchar-fg a) (fatchar-fg b))
       (equal (fatchar-bg a) (fatchar-bg b))
       (not (set-exclusive-or (fatchar-attrs a) (fatchar-attrs b)
			      :test #'eq))))

(defun fatchar= (a b)
  "True if everything about a fatchar is the equivalent."
  (and (char= (fatchar-c a) (fatchar-c b))
       (same-effects a b)
       (= (fatchar-line a) (fatchar-line b))))

(defun fatchar/= (a b)
  (not (fatchar= a b)))

(defmethod ochar= ((char-1 fatchar) (char-2 fatchar))
  (fatchar= char-1 char-2))

(defmethod ochar/= ((char-1 fatchar) (char-2 fatchar))
  (fatchar/= char-1 char-2))

(deftype fatchar-string (&optional size)
  "A string of FATCHARs."
  `(vector fatchar ,size))

;; This is potentially wasteful, but required to specialize methods.
(defclass fat-string ()
  ((string				; blurg :|
    :initarg :string :accessor fat-string-string
    :documentation "A lot of crust around a string."))
  (:documentation "A vector of FATCHAR."))
;;(string (vector) :type fatchar-string)) ; Is this better or worse?

(defparameter *known-attrs*
  `(:normal :standout :underline :bold :inverse)
  "List of known attributes.")

;; Collection methods

(defmethod olength ((s fat-string))
  (length (fat-string-string s)))

(defun make-fat-string (&key string)
  (make-instance 'fat-string :string string))

(defmethod oelt ((s fat-string) key)
  (aref (fat-string-string s) key))

(defmethod (setf oelt) (value (s fat-string) key) ;; @@@ ??? test
  (setf (aref (fat-string-string s) key) value))

;; It's probably better to use oelt than oaref if you can.

(defmethod oaref ((s fat-string) &rest subscripts)
  (apply #'aref (fat-string-string s) subscripts))

(defmethod (setf oaref) (value (s fat-string) &rest subscripts) ;; @@@ ??? test
  (when (> (length subscripts) 1)
    (error "Wrong number of subscripts, ~s, for a fat-string."
	   (length subscripts)))
  (setf (aref (fat-string-string s) (car subscripts)) value))

(defmethod ochar ((s fat-string) index)
  (aref (fat-string-string s) index))

(defmethod (setf ochar) ((value character) (s fat-string) index)
  (setf (fatchar-c (aref (fat-string-string s) index)) value))

(defmethod (setf ochar) ((value fatchar) (s fat-string) index)
  (setf (aref (fat-string-string s) index) value))

(defmacro call-with-start-and-end (func args)
  "Call func with args and START and END keywords, assume that an environemnt
that has START and START-P and END and END-P."
  `(progn
     (if start-p
	 (if end-p
	     (,func ,@args :start start :end end)
	     (,func ,@args :start start))
	 (if end-p
	     (,func ,@args ::end end)
	     (,func ,@args)))))

(defmacro call-with-start-end-test (func args)
  "Call func with args and START, END, TEST, and TEST-NOT keywords. Assume that
the environemnt has <arg> and <arg>-P for all those keywords."
  `(progn
     (cond
       (test-not-p
	(if start-p
	    (if end-p
		(,func ,@args :start start :end end :test-not test-not)
		(,func ,@args :start start :test-not test-not))
	    (if end-p
		(,func ,@args ::end end :test-not test-not)
		(,func ,@args :test-not test-not))))
       (test-p
	(if start-p
	    (if end-p
		(,func ,@args :start start :end end :test test)
		(,func ,@args :start start :test test))
	    (if end-p
		(,func ,@args ::end end :test test)
		(,func ,@args :test test))))
       (t
	(if start-p
	    (if end-p
		(,func ,@args :start start :end end)
		(,func ,@args :start start))
	    (if end-p
		(,func ,@args ::end end)
		(,func ,@args)))))))

(defmethod osubseq ((string fat-string) start &optional end)
  "Sub-sequence of a fat-string."
  (make-fat-string
   :string
   (if end
       (subseq (fat-string-string string) start end)
       (subseq (fat-string-string string) start))))

(defmethod ocount ((item fatchar) (collection fat-string)
		   &key from-end key
		     (test nil test-p)
		     (test-not nil test-not-p)
		     (start nil start-p)
		     (end nil end-p))
  (if (or test-p test-not-p)
      (call-with-start-end-test
       count (item (fat-string-string collection) :from-end from-end
		   :key key))
      (call-with-start-and-end
       count (item (fat-string-string collection) :from-end from-end
		   :key key
		   :test (or test #'fatchar=)))))

(defmethod ocount ((item character) (collection fat-string)
		   &key from-end key
		     (test nil test-p)
		     (test-not nil test-not-p)
		     (start nil start-p)
		     (end nil end-p))
  (labels ((key-func (c)
	     (funcall key (fatchar-c c))))
  (call-with-start-end-test
   count (item (fat-string-string collection) :from-end from-end
	       :key (if key #'key-func #'fatchar-c)))))

(defmethod oposition ((item fatchar) (string fat-string)
		      &key from-end test test-not key
			(start nil start-p)
			(end nil end-p))
  "Position of a fatchar in a fat-string."
  (declare (ignorable start start-p end end-p))
  (call-with-start-and-end
   position
   (item (fat-string-string string)
	 :from-end from-end
	 ;; Default to reasonable tests.
	 :test (or test #'equalp)
	 :key key
	 :test-not (or test-not (lambda (x y) (not (equalp x y)))))))

(defmethod oposition ((item character) (string fat-string)
		      &key from-end test test-not key
			(start nil start-p)
			(end nil end-p))
  "Position of a fatchar in a fat-string."
  (declare (ignorable start start-p end end-p))
  (call-with-start-and-end
   position
   (item (fat-string-string string)
	 :from-end from-end
	 :test test :test-not test-not
	 ;; Make the key reach into the fatchar for the character.
	 :key (or (and key (_ (funcall key (fatchar-c _))))
		  #'fatchar-c))))

(defmethod oposition-if (predicate (string fat-string)
			 &key from-end key
			   (start nil start-p)
			   (end nil end-p))
  "Position of a fatchar in a fat-string."
  (declare (ignorable start start-p end end-p))
  (call-with-start-and-end
   position-if
   (predicate (fat-string-string string)
	      :from-end from-end
	      :key key)))

(defmethod osplit ((separator fatchar) (string fat-string)
		   &key omit-empty test key
		     (start nil start-p)
		     (end nil end-p))
  (declare (ignorable start start-p end end-p))
  (mapcar (_ (make-fat-string :string _))
	  (call-with-start-and-end
	   split-sequence
	   (separator (fat-string-string string)
		      :omit-empty omit-empty
		      ;; Default to a reasonable test for fatchars.
		      :test (or test #'equalp)
		      :key key))))

(defmethod osplit ((separator character) (string fat-string)
		   &key omit-empty test key
		     (start nil start-p)
		     (end nil end-p))
  (declare (ignorable start start-p end end-p))
  (mapcar (_ (make-fat-string :string _))
	  (call-with-start-and-end
	   split-sequence
	   (separator (fat-string-string string)
		      :omit-empty omit-empty
		      :test test
		      ;; Make the key reach into the fatchar for the character.
		      :key (or (and key (_ (funcall key (fatchar-c _))))
			       #'fatchar-c)))))

(defmethod osplit ((separator string) (string fat-string)
		   &key omit-empty test key
		     (start nil start-p)
		     (end nil end-p))
  (declare (ignorable start start-p end end-p))
  (mapcar (_ (make-fat-string :string _))
	  (call-with-start-and-end
	   split-sequence
	   (separator (fat-string-string string)
		      :omit-empty omit-empty
		      :test test
		      ;; Make the key reach into the fatchar for the character.
		      :key (or (and key (_ (funcall key (fatchar-c _))))
			       #'fatchar-c)))))

(defmethod osplit ((separator fat-string) (string fat-string)
		   &key omit-empty test key
		     (start nil start-p)
		     (end nil end-p))
  (declare (ignorable start start-p end end-p))
  (mapcar (_ (make-fat-string :string _))
	  (call-with-start-and-end
	   split-sequence
	   ((fat-string-string separator) (fat-string-string string)
	    :omit-empty omit-empty
	    ;; Default to a reasonable test for fatchars.
	    :test (or test #'equalp)
	    :key key))))

(defun make-fatchar-string (thing)
  "Make a string of fatchars from THING, which can be a string or a character."
  (let (result)
    (flet ((from-string (string)
	     (setf result (make-array (list (length string))
				      :element-type 'fatchar
				      :initial-element (make-fatchar)))
	     (loop :for i :from 0 :below (length string) :do
		(setf (aref result i) (make-fatchar :c (char string i))))))
      (etypecase thing
	(string
	 (from-string thing))
	(character
	 (setf result
	       (make-array '(1) :element-type 'fatchar
			   :initial-element (make-fatchar :c thing))))
	;; We could princ-to-string other stuff, but it's probably better if
	;; the caller does it explicitly.
	)
      result)))

(defun fat-string-to-string (fat-string)
  "Make a string from a fat string. This of course loses the attributes."
  (typecase fat-string
    (fat-string (fatchar-string-to-string (fat-string-string fat-string)))
    (fatchar-string (fatchar-string-to-string fat-string))
    (t fat-string)))

(defun fatchar-string-to-string (string)
  "Make a string from a fat string. This of course loses the attributes."
  ;; Arrays can't really distinguish their orginal element type if it's
  ;; upgraded, so we might not be able tell a string from a fatchar-string.
  (typecase string
    (fatchar-string
     ;; (let ((s (make-array (list (length fat-string))
     ;; 			  :element-type 'character)))
     ;;   (loop :for i :from 0 :below (length fat-string) :do
     ;; 	  (setf (aref s i) (fatchar-c (aref fat-string i))))
     ;;   s))
     (map 'string (_ (if (fatchar-p _) (fatchar-c _) _)) string))
    (t string)))

;; @@@ Maybe this should be generic?
(defun string-vector (string)
  "Return the STRING as a vector. This converts FAT-STRINGs to FATCHAR-STRINGs,
and returns STRINGs or FATCHAR-STRINGs as-is. This is useful so you can iterate
over a string's characters, even with the 'normal' (non-collections) sequence
functions."
  (etypecase string
    (fat-string (fat-string-string string))
    ((or string fatchar-string) string)))

;; @@@ What about string equality considering the effects?

(defun fat-string-compare (f a b)
  (funcall f (fat-string-to-string a) (fat-string-to-string b)))

(eval-when (:compile-toplevel)
  (defmacro make-string-comparators ()
    (let ((forms
	   (loop :with func
	      :for f :in '(string< string> string= string/= string<= string>=
			   string-lessp string-greaterp string-equal
			   string-not-equal string-not-lessp
			   string-not-greaterp)
	      :do
	      (setf func (symbolify (s+ "FAT-" f)))
	      :collect `(defun ,func (a b)
			  (funcall #',f
				   (fat-string-to-string a)
				   (fat-string-to-string b))))))
      `(progn ,@forms))))
(make-string-comparators)

;; The char= methods are pre-done.
(eval-when (:compile-toplevel)
  (defmacro make-char-comparators (prefix)
    (let ((forms
	   (loop :with func
	      :for f :in '(char< char> char<= char>=
			   char-lessp char-greaterp char-equal
			   char-not-equal char-not-lessp
			   char-not-greaterp)
	      :do
	      (setf func (symbolify (s+ prefix f)))
	      :collect `(defun ,func (a b)
			  (funcall #',f
				   (fatchar-c a)
				   (fatchar-c b))))))
      `(progn ,@forms))))
(make-char-comparators "FAT")

;;;;;;;;;;;;;;;;;;
;; ochar methods

(eval-when (:compile-toplevel)
  (defmacro make-char-comparator-methods (prefix)
    (let ((forms
	   (loop :with func
	      :for f :in '(char< char> char<= char>=
			   char-lessp char-greaterp char-equal
			   char-not-equal char-not-lessp
			   char-not-greaterp)
	      :do
	      (setf func (symbolify (s+ prefix f)))
	      :collect `(defmethod ,func ((a fatchar) (b fatchar))
			  (funcall #',f
				   (fatchar-c a)
				   (fatchar-c b))))))
      `(progn ,@forms))))
(make-char-comparator-methods "O")

;; All the rest that are just wrappers
(eval-when (:compile-toplevel)
  (defmacro make-char-wrapper-methods (prefix)
    (let ((forms
	   (loop :with func
	      :for f :in '(alpha-char-p alphanumericp graphic-char-p
			   char-upcase char-downcase upper-case-p lower-case-p
			   both-case-p char-code char-int char-name)
	      :do
	      (setf func (symbolify (s+ prefix f)))
	      :collect `(defmethod ,func ((character fatchar))
			  (,f (fatchar-c character))))))
      `(progn ,@forms))))

(defmethod ocharacterp ((object fatchar)) T)
(defmethod odigit-char (weight (type (eql 'fatchar)) &optional radix)
  (make-fatchar :c (if radix (digit-char weight radix) (digit-char weight))))

(defmethod odigit-char-p ((character fatchar) &optional radix)
  (if radix (digit-char-p (fatchar-c character) radix)
      (digit-char-p (fatchar-c character))))

(defmethod ostandard-char-p ((character fatchar)) nil) ;; @@@ Right?

;; I think this was intended to encode the attributes too, but we've made a
;; character that's bigger than a fixnum. Should we really construct a bizzarely
;; formatted bignum? Also we would have to define a limited fixed set of
;; attributes. So this is inherently lossy.
(defmethod ochar-int ((character fatchar))
  (let ((int 0)
	(fg (convert-color-to (lookup-color (fatchar-fg character)) :rgb8))
	(bg (convert-color-to (lookup-color (fatchar-bg character)) :rgb8))
	(line (logior (fatchar-line character) #b1111)))
    (flet ((add (value width)
	     (setf int (logior (ash int width) value)))
	   (attr-bits ()
	     (loop :with result = 0
		:for a :in (rest *known-attrs*)
		:as i = 0 :then (1+ i)
		:do
		(when (find a (fatchar-attrs character))
		  (setf result (logior result (ash 1 i))))
		:finally (return result))))
      (add (attr-bits) (length (rest *known-attrs*)))
      (add line 4)
      (add (color-component fg :red)   8)
      (add (color-component fg :green) 8)
      (add (color-component fg :blue)  8)
      (add (color-component bg :red)   8)
      (add (color-component bg :green) 8)
      (add (color-component bg :blue)  8)
      (add (char-int (fatchar-c character)) 32))
    int))

(defmethod ocode-char (code (type (eql 'fatchar)))
  (make-fatchar :c (code-char code)))

(defmethod oname-char (name (type (eql 'fatchar)))
  (make-fatchar :c (name-char name)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Spans
;;
;; ([objects ...])
;; (:keyword [objects ...])
;; (:keyword [attribute ...] [objects ...])
;;
;; attribute => :keyword object
;;
;; (:fg :color #(:rgb 0 0 1) "hello")
;; (:fg-blue "hello")
;;
;; Some things may want to allow evaluation by letting an "object" be
;; a function call or a symbol that gets evaluated, instead of just literal
;; objects.

(defun span-length (span)
  "Calculate the length in characters of the span."
  (the fixnum (loop :for e :in span
		 :sum (typecase e
			(string (length e))
			(cons (span-length e))
			;; @@@ shouldn't we princ-to-string other some things?
			(t 0)))))

(defun listify-fake-span (fake-span)
  "Take a list of characters, strings, and keywords and make nested lists out
of them indicated by the parentheses. Actual parens should be given as
strings."
  (let ((str (make-string-output-stream))
	cur save tmp)
    (flet ((push-if-any ()
	     (when (> (length (setf tmp (get-output-stream-string str))) 0)
	       (push tmp cur))))
      (loop
	 :for x :in fake-span :do
	 (cond
	   ((eql x #\()
	    (push-if-any)
	    (push cur save)
	    (setf cur '()))
	   ((eql x #\))
	    (push-if-any)
	    (setf cur (nreverse cur))
	    (setf tmp (pop save))
	    (push cur tmp)
	    (setf cur tmp))
	   (t
	    (typecase x
	      ((or character string)
	       (princ x str))
	      (t
	       (push x cur)))))
;;;       (format t "~w~%" cur)
	 )
    (push-if-any)
    (nreverse cur))))

;; TODO:
;;  - Add END key

;; (fatchar:fat-string-to-span (pager::process-grotty-line (nth 4 (!_ "/bin/cat grotish.txt"))))

(defun fatchar-diffs (c1 c2)
  "The differences between c1 and c2, a list of :ATTR :FG :BG. NIL if the same."
  (let (diffs)
    (when (set-exclusive-or (and c1 (fatchar-attrs c1)) (fatchar-attrs c2)
				 :test #'eq)
      (push :attr diffs))
    (when (not (equal (and c1 (fatchar-fg c1)) (fatchar-fg c2)))
      (push :fg diffs))
    (when (not (equal (and c1 (fatchar-bg c1)) (fatchar-bg c2)))
      (push :bg diffs))
    ;; (when (not diffs)
    ;;   (error "bug-a-roony: it twernt a difference ~s ~s" c1 c2))
    diffs))

(defun span-start (type value)
  "Return the reversed starting list for a span of TYPE and VALUE."
  (ecase type
    (:attr (fatchar-attrs value))
    (:fg (if (keywordp (fatchar-fg value))
	     (list (keywordify (s+ "FG-" (fatchar-fg value))))
	     (list (fatchar-fg value) :color :fg)))
    (:bg (if (keywordp (fatchar-bg value))
	     (list (keywordify (s+ "BG-" (fatchar-bg value))))
	     (list (fatchar-bg value) :color :bg)))
    ((nil) nil)))

#|

c    | foothebar0000
fg   |    rrrrrr
bg   |       bbbbbbb
attr | iiiiiiii

((:i "foo" (:fg-r "the" (:bg-b "ba"))) (:fg-r (:bg-b "r")) (:bg-b "0000"))
|#

;; This is the average line length of my code.
(defparameter *starting-string-size* 33
  "How many characters allocate initially for a span piece.")

;; @@@ remove all the debugging junk someday.
(defun fatchar-string-to-span (fatchar-string &key (start 0) pause)
  "Convert a FATCHAR line to tagged spans."
  (let ((i start)
	(len (length fatchar-string))
	(piece (make-stretchy-string *starting-string-size*))
	last
	c)
    (labels
	((add-chars ()
	   "Add characters to piece until a change or the end. Return true
                if we added one."
	   (let (did-one)
	     (loop
		:do (setf c (aref fatchar-string i))
		:while (and (< i len) (not (and did-one
						(fatchar-diffs last c))))
		:do
		(stretchy-append piece (fatchar-c c))
		(dbugf :fatchar "char ~s ~s ~%" i (fatchar-c c))
		(incf i)
		(setf last (copy-fatchar c)
		      did-one t))
	     did-one))
	 (sub-rendition-of-p (a b)
	   "True if fatchar A is sub-rendition of B, i.e. B can be nested in A."
	   (and (subsetp (fatchar-attrs a) (fatchar-attrs b))
		(or (not (fatchar-fg a))
		    (and (fatchar-fg a) (equal (fatchar-fg a) (fatchar-fg b))))
		(or (not (fatchar-bg a))
		    (and (fatchar-bg a) (equal (fatchar-bg a) (fatchar-bg b))))))
	 (build-span (type value rendition in)
	   "Build a span of TYPE and VALUE."
	   (dbugf :fatchar "build-span ~s ~a ~s ~s~%" type value rendition in)
	   (let (sub-span new-type added)
	     (when pause
	       (format *debug-io* "-> ") (finish-output *debug-io*)
	       (read-line *debug-io*))
	     (cond
	       ((> (length type) 1)
		(dbugf :fatchar "subtype ~s~%" type)
		(setf sub-span (span-start (pop type) value))
		(push (build-span type c rendition (cons (first type) in))
		      sub-span))
	       (t
		(dbugf :fatchar "actual type ~s~%" type)
		(setf sub-span (span-start (pop type) value))
		(when (add-chars)
		  (push (copy-seq piece) sub-span)
		  (stretchy-truncate piece))
		(when (< i len)
		  (setf new-type (fatchar-diffs last c))
		  (dbugf :fatchar "differnce type ~s ~a ~a~%"
			 new-type last c)
		  ;; (when (and (not (member (first type) new-type))
		  ;; 	     (not (intersection new-type in)))
		  (when (and (sub-rendition-of-p rendition c)
			     (not (intersection new-type in)))
		    (if (eq (first new-type) :attr)
			(progn
			  (setf added (set-difference
				       (fatchar-attrs c)
				       (and last (fatchar-attrs last)))
				;; removed (set-difference
				;; 		(fatchar-attrs last)
				;; 		(fatchar-attrs c))
				)
			  (when added
			    (dbugf :fatchar "add attr ~s~%" added)
			    (setf last nil)
			    (push (build-span new-type c c
					      (cons (first new-type) in))
				  sub-span)
			    (pop new-type)))
			(progn
			  (dbugf :fatchar "add color ~s~%" c)
			  (setf last nil)
			  (push (build-span new-type c c
					    (cons (first new-type) in))
				sub-span)
			  (pop new-type)))))))
	     ;; Reverse it and return it.
	     (setf sub-span (nreverse sub-span))
	     sub-span)))
      (dbugf :fatchar "~&############################~%")
      (dbugf :fatchar "~&### string to span start ###~%")
      (dbugf :fatchar "~&############################~%")
      (loop
	 :with rendition = (make-fatchar)
	 :while (< i len)
	 :do (dbugf :fatchar "Blurp ~s.~%" i)
	 (setf c (aref fatchar-string i))
	 :collect
	 (let ((cc (build-span (fatchar-diffs rendition c) c rendition nil)))
	   (dbugf :fatchar "collected ~s~%" cc)
	   cc)))))

#|
(defun OLD2-fatchar-string-to-span (fatchar-string &key (start 0) pause)
  "Convert a FATCHAR line to tagged spans."
  (let ((i start)
	(len (length fatchar-string))
	(piece (make-stretchy-string *starting-string-size*))
	;;(last (make-fatchar))
	last
	c)
    (labels
	((add-chars (X-last)
	   "Add characters to piece until a change or the end. Return true
                if we added one."
	   (declare (ignore X-last))
	   (let (did-one)
	     (loop
		:do (setf c (aref fatchar-string i))
		:while (and (< i len) (not (and did-one
						(fatchar-diffs last c))))
		:do
		(stretchy-append piece (fatchar-c c))
		(dbugf :fatchar "char ~s ~s ~%" i (fatchar-c c))
		(incf i)
		(setf last (copy-fatchar c)
		      did-one t))
	     did-one))
	 (build-span (type value X-last in)
	   "Build a span of TYPE and VALUE."
	   (declare (ignore X-last))
	   (dbugf :fatchar "build-span ~s ~a ~s ~s~%" type value last in)
	   (let (sub-span new-type added #| removed |#)
	     (when pause
	       (format *debug-io* "-> ") (finish-output *debug-io*)
	       (read-line *debug-io*))
	     (if (> (length type) 1)
		 (progn
		   (setf sub-span (span-start (pop type) value))
		   (push (build-span type c last in) sub-span))
		 (progn
		   (setf sub-span (span-start (pop type) value))
		   (when (add-chars last)
		     (push (copy-seq piece) sub-span)
		     (stretchy-truncate piece))
		   (when (< i len)
		     (setf new-type (fatchar-diffs last c))
		     (dbugf :fatchar "differnce type ~s ~s ~s~%"
			    new-type last c)
		     (when (and (not (member (first type) new-type))
				(not (intersection new-type in)))
		       (if (eq (first new-type) :attr)
			   (progn
			     (setf added (set-difference
					  (fatchar-attrs c)
					  (and last (fatchar-attrs last)))
				   ;; removed (set-difference
				   ;; 		(fatchar-attrs last)
				   ;; 		(fatchar-attrs c))
				   )
			     (when added
			       (dbugf :fatchar "add attr ~s~%" added)
			       (setf last nil)
			       (push (build-span new-type c last
						 (cons (first new-type) in))
				     sub-span)
			       (pop new-type)))
			   (progn
			     (dbugf :fatchar "add color ~s~%" c)
			     (setf last nil)
			     (push (build-span new-type c last
					       (cons (first new-type) in))
				   sub-span)
 			     (pop new-type)))))
		   ;; Reverse it and return it.
		   (setf sub-span (nreverse sub-span))
		   sub-span)))))
      (dbugf :fatchar "~&### string to span start ###~%")
      (loop :while (< i len)
	 :do (dbugf :fatchar "Blurp ~s.~%" i)
	 (setf c (aref fatchar-string i))
	 :collect (build-span (fatchar-diffs last c) c last nil)))))

(defun OLD-fatchar-string-to-span (fatchar-string &key (start 0))
  "Convert a FATCHAR line to tagged spans."
  (when (= (length fatchar-string) 0)
    ;; (return-from fatchar-string-to-span fatchar-string))
    (return-from OLD-fatchar-string-to-span nil))
  (let ((last (make-fatchar))
	(result '())
	(open-count 0)
	added removed did-one last-paren-type)
;;    (push #\( result)
    (loop :with c
       :for i :from start :below (length fatchar-string) :do
       (setf c (aref fatchar-string i)
	     did-one nil)
       ;; Attributes
       (setf added (set-difference (fatchar-attrs c) (fatchar-attrs last))
	     removed (set-difference (fatchar-attrs last) (fatchar-attrs c)))
       (loop :for a :in removed :do
	  ;; Only close up here if the attr removed is the nearest enclosing one
	  (when (and (eq (car (first last-paren-type)) :attr)
		     (eq (cdr (first last-paren-type)) a))
	    (push #\) result)
	    (decf open-count)
	    (pop last-paren-type)))
       (loop :for a :in added :do
	  (push #\( result)
	  (incf open-count)
	  (push a result)
	  (setf did-one t)
	  (push (cons :attr a) last-paren-type))
       ;; Foreground
       (when (not (eql (fatchar-fg c) (fatchar-fg last)))
	 (when (and (fatchar-fg last) (not did-one)
		    (eq (car (first last-paren-type)) :fg)
		    (eq (cdr (first last-paren-type)) (fatchar-fg last)))
	   (push #\) result)
	   (decf open-count)
	   (pop last-paren-type))
	 (when (fatchar-fg c)
	   (push #\( result)
	   (incf open-count)
	   (if (keywordp (fatchar-fg c))
	       (push (keywordify (s+ "FG-" (fatchar-fg c))) result)
	       (progn
		 (push :fg result)
		 (push :color result)
		 (push (fatchar-fg c) result)))
	   (setf did-one t)
	   (push (cons :fg (fatchar-fg c)) last-paren-type)))
       ;; Background
       (when (not (eql (fatchar-bg c) (fatchar-bg last)))
	 (when (and (fatchar-bg last) (not did-one)
		    (eq (car (first last-paren-type)) :bg)
		    (eq (cdr (first last-paren-type)) (fatchar-bg last)))
	   (push #\) result)
	   (decf open-count)
	   (pop last-paren-type))
	 (when (fatchar-bg c)
	   (push #\( result)
	   (incf open-count)
	   (if (keywordp (fatchar-fg c))
	       (push (keywordify (s+ "BG-" (fatchar-bg c))) result)
       	       (progn
		 (push :bg result)
		 (push :color result)
		 (push (fatchar-bg c) result)))
	   (setf did-one t)
	   (push (cons :bg (fatchar-bg c)) last-paren-type)))
       ;; Character
       (case (fatchar-c c)
	 (#\( (push "(" result))
	 (#\) (push ")" result))
	 (#\" (push "\"" result))
	 (t (push (fatchar-c c) result)))
       (setf last c))
    (dotimes (n open-count)
      (push #\) result))
    (setf result (nreverse result))
;;    (format t "result = ~w~%" result)
    (listify-fake-span result)
      ))

(defun fat-string-to-span (fat-string &key (start 0) last (depth 0))
  "Convert a FATCHAR line to tagged spans."
  (when (= (length fat-string) 0)
    (return-from fat-string-to-span fat-string))
  (when (> depth 10)
    (break))
  (when (not last)
    (setf last (make-fatchar)))
  (let ((str (make-stretchy-string (- (length fat-string) start)))
	(len (length fat-string))
	(attr (fatchar-attrs (aref fat-string start)))
	added removed c (span '()))
    (loop :with i = start
       :do
       (setf c (aref fat-string i))
       (setf added (set-difference (fatchar-attrs c) (fatchar-attrs last))
	     removed (set-difference (fatchar-attrs last) (fatchar-attrs c)))
       ;; (format t "~a str=~a span=~w added=~w removed=~w~%"
       ;; 	       (fatchar-c c) str span added removed)
       (cond
	 (removed
	  (when (/= 0 (length str))
	    (push str span))
	  (setf span (nreverse span))
	  (return-from fat-string-to-span `(,@attr ,@span)))
	 (added
	  (when (/= 0 (length str))
	    (push (copy-seq str) span))
	  (let ((s (fat-string-to-span fat-string :start i :last c
				       :depth (1+ depth))))
	    (setf attr nil)
	    (push s span)
	    (incf i (span-length s)))
	  (stretchy-truncate str))
	 (t
	  (stretchy-append str (fatchar-c c))
	  (incf i)
	  (setf last c)))
       :while (< i len))
    (when (/= 0 (length str))
      (push str span))
    (setf span (nreverse span))
    `(,@attr ,@span)))
|#

(defun fat-string-to-span (fat-string &key (start 0))
  (fatchar-string-to-span (fat-string-string fat-string) :start start))

(defmethod ostring-to-span ((string fat-string))
  (fat-string-to-span string))

(defun span-to-fat-string (span &key (start 0) end fatchar-string
				  unknown-func filter)
"Make a FAT-STRING from SPAN. See the documentation for SPAN-TO-FATCHAR-STRING."
  (make-fat-string
   :string
   (span-to-fatchar-string span :start start :end end
			   :fatchar-string fatchar-string
			   :unknown-func unknown-func
			   :filter filter)))

;; Wherein I inappropriately appropriate more of latin1.
(defalias 'ß 'span-to-fat-string)

;; @@@ Consider dealing with the overlap between this and
;; lish:symbolic-prompt-to-string and terminal:with-style.

(defun span-to-fatchar-string (span &key (start 0) end fatchar-string
				      unknown-func filter)
  "Make a FATCHAR-STRING from SPAN. A span is a list representation of a
fatchar string.  The grammar is something like:

span ->
  string | fat-string |
  character | fatchar |
  span-list

span-list ->
  ([color-name] [span]*)
  ([attribute-name] [span]*)
  (:fg-[color-name] [span]*)
  (:bg-[color-name] [span]*)
  (:fg :color [color] [span]*)
  (:bg :color [color] [span]*)

Known colors are from color:*simple-colors* and known attributes are in
fatchar:*known-attrs*.

  - START and END are character index limits.
  - FATCHAR-STRING can be provided as an already created adjustable string with a
    fill-pointer to put the result into.
  - UNKNOWN-FUNC is a fuction to call with un-recognized attributes, colors, or
    object types.
  - FILTER is a function which is called with every string, which should return
    similar typed string to use as a replacement."
  (when (not fatchar-string)
    (setf fatchar-string (make-array 40
				     :element-type 'fatchar
				     :initial-element (make-fatchar)
				     :fill-pointer 0
				     :adjustable t)))
  (setf (fill-pointer fatchar-string) 0)
  (let (fg bg attrs (i 0))
    (declare (special fg bg attrs))
    (labels
	((spanky (s)
	   (when s
	     (typecase s
	       (string
		(loop :for c :across (if filter (funcall filter s) s)
		   :do
		   (when (and (>= i start)
			      (or (not end) (< i end)))
		     (vector-push-extend
		      (make-fatchar :c c :fg (car fg) :bg (car bg) :attrs attrs)
		      fatchar-string))
		   (incf i)))
	       (fat-string
		(loop :for c :across (fat-string-string
				      (if filter (funcall filter s) s))
		   :do
		   (when (and (>= i start)
			      (or (not end) (< i end)))
		     (vector-push-extend
		      (make-fatchar :c (fatchar-c c)
				    :fg (fatchar-fg c)
				    :bg (fatchar-bg c)
				    :line (fatchar-line c)
				    :attrs (union attrs (fatchar-attrs c))); <--
		      fatchar-string))
		   (incf i)))
	       (character
		(vector-push-extend
		 (make-fatchar :c s :fg (car fg) :bg (car bg) :attrs attrs)
		 fatchar-string)
		(incf i))
	       (list
		(let* ((f (first s))
		       (tag (and (or (keywordp f) (symbolp f)) f))
		       (rest (cdr s)))
		  (if tag
		      (let ((fg fg) (bg bg) (attrs attrs)
			    (tag-str (string tag)))
			(declare (special fg bg attrs))
			(cond
			  ((and (> (length tag-str) 3)
				(string= (subseq tag-str 0 3) "FG-"))
			   (push (keywordify (subseq (string tag) 3)) fg))
			  ((and (> (length tag-str) 3)
				(string= (subseq tag-str 0 3) "BG-"))
			   (push (keywordify (subseq (string tag) 3)) bg))
			  ((member tag *simple-colors*)
			   ;; An un-prefixed color is a foreground color.
			   (push tag fg))
			  ((member tag *known-attrs*)
			   (push tag attrs))
			  ((and (eq tag :fg) (eq (second s) :color))
			   (push (third s) fg)
			   (setf rest (cdddr s)))
			  ((and (eq tag :bg) (eq (second s) :color))
			   (push (third s) bg)
			   (setf rest (cdddr s)))
			  (t
			   (if unknown-func
			       (spanky (funcall unknown-func s))
			       (push tag attrs))))
			;; (format t "tag ~s attrs ~s (cdr s) ~s~%"
			;; 	tag attrs (cdr s))
			(spanky rest)
			;;(setf fg nil bg nil)
			;;(pop attrs)
			)
		      (progn
			(spanky f)
			(spanky (cdr s))))))
	       (t
		(when unknown-func
		  (spanky (funcall unknown-func s))))))))
      (spanky span)))
  fatchar-string)

#|
(defun map-span-strings (span &key (start 0) end fat-string)
  "Make a fat string from a span."
  (labels ((spanky (s)
	     (when s
	       (typecase s
		 (string
		  )
		 (list
		  (let* ((f (first s))
			 (tag (and (or (keywordp f) (symbolp f)) f)))
		    (if tag
			(progn
			  (spanky (cdr s)))
			(progn
			  (spanky f)
			  (spanky (cdr s)))))))))))
      (spanky span)))
  fat-string)
|#

(defparameter *xterm-256-color-table* nil
  "Table for old-timey xterm colors.")

;; see xterm/256colres.pl
(defun make-xterm-color-table ()
  (setf *xterm-256-color-table* (make-array 256))
  ;; colors 16-231 are a 6x6x6 color cube
  (loop :for red :from 0 :below 6 :do
     (loop :for green :from 0 :below 6 :do
	(loop :for blue :from 0 :below 6 :do
	   (setf (aref *xterm-256-color-table*
		       (+ 16 (* red 36) (* green 6) blue))
		 (make-color :rgb8
			     :red   (if (= red   0) 0 (+ (* red   40) 55))
			     :green (if (= green 0) 0 (+ (* green 40) 55))
			     :blue  (if (= blue  0) 0 (+ (* blue  40) 55)))))))
  ;; colors 232-255 are a grayscale ramp, without black & white
  (loop :with level
     :for gray :from 0 :below 24 :do
     (setf level (+ (* gray 10) 8)
	   (aref *xterm-256-color-table* (+ 232 gray))
	   (make-color :rgb8 :red level :green level :blue level))))

;;; ^[[00m	normal
;;; ^[[01;34m	bold, blue fg
;;; ^[[m	normal
;;; ^[[32m	green fg
;;; ^[[1m	bold

;; We drink of the color and become the color.
(defun grok-ansi-color (str &key (start 0))
  "Take an string with an ANSI terminal color escape sequence, starting after
the ^[[ and return NIL if there was no valid sequence, or an integer offset
to after the sequence, the foreground, background and a list of attributes.
NIL stands for whatever the default is, and :UNSET means that they were not
set in this string."
  (let* ((i start)
	 (len (length str))
	 (hi-color nil)
	 (fg :unset)
	 (bg :unset)
	 (attr '())
	 num offset attr-was-set hi-color-type r g b)
    (loop
       :do
       (setf (values num offset) (parse-integer str :start i :junk-allowed t))
       (dbugf :fatchar "@~s num ~s offset ~s~%" i num offset)
       (if (or (not num) (not offset))
	   (progn
	     ;; Just an #\m without arguments means no attrs and unset color
	     (dbugf :fatchar "@~s done ~a" i
		    (if (eql (char str i) #\m) "final m" "no numbers?"))
	     (when (eql (char str i) #\m)
	       (setf attr '() fg nil bg nil attr-was-set t i (1+ i)))
	     (return))
	   (progn
	     (setf i offset)
	     (when (and (< i len)
			(or (eql (char str i) #\;)
			    (eql (char str i) #\m)))
	       (incf i)
	       (cond
		 ((and hi-color (not hi-color-type))
		  (dbugf :fatchar "@~s hi-color ~s~%" i num)
		  (case num
		    (2 (setf hi-color-type :3-color))
		    (5 (setf hi-color-type :1-color))))
		 ((eq hi-color-type :1-color)
		  (dbugf :fatchar "@~s 1-color ~s ~s~%" i hi-color num)
		  (when (not *xterm-256-color-table*)
		    (make-xterm-color-table))
		  (if (eq hi-color :fg)
		      (setf fg (aref *xterm-256-color-table* num))
		      (setf bg (aref *xterm-256-color-table* num)))
		  (setf hi-color nil hi-color-type nil))
		 ((eq hi-color-type :3-color)
		  (dbugf :fatchar "@~s 3-color ~s ~s~%" i hi-color num)
		  (cond
		    ((not r) (setf r num))
		    ((not g) (setf g num))
		    ((not b) (setf b num)
		     (dbugf :fatchar "@~s 3-color end ~s ~s~%" i hi-color num)
		     (if (eq hi-color :fg)
			 (setf fg (make-color :rgb8 :red r :green g :blue b))
			 (setf bg (make-color :rgb8 :red r :green g :blue b)))
		     (setf hi-color nil hi-color-type nil r nil g nil b nil))))
		 (t
		  (dbugf :fatchar "@~s num ~s~%" i num)
		  (case num
		    (0  (setf attr '() fg nil bg nil attr-was-set t))
		    (1  (pushnew :bold attr)      (setf attr-was-set t))
		    (2  (pushnew :dim attr)       (setf attr-was-set t))
		    (3  (pushnew :italic attr)    (setf attr-was-set t))
		    (4  (pushnew :underline attr) (setf attr-was-set t))
		    (5  (pushnew :blink attr)     (setf attr-was-set t))
		    (7  (pushnew :inverse attr)   (setf attr-was-set t))
		    (8  (pushnew :invisible attr) (setf attr-was-set t))
		    (9  (pushnew :crossed-out attr) (setf attr-was-set t))
		    (21 (pushnew :double-underline attr) (setf attr-was-set t))
		    (22 (setf attr (delete :bold attr))
			(setf attr-was-set t))
		    (23 (setf attr (delete :italic attr))
			(setf attr-was-set t))
		    (24 (setf attr (delete :underline attr))
			(setf attr-was-set t))
		    (25 (setf attr (delete :blink attr))
			(setf attr-was-set t))
		    (27 (setf attr (delete :inverse attr))
			(setf attr-was-set t))
		    (28 (setf attr (delete :invisible attr))
			(setf attr-was-set t))
		    (29 (setf attr (delete :crossed-out attr))
			(setf attr-was-set t))
		    (30 (setf fg :black))
		    (31 (setf fg :red))
		    (32 (setf fg :green))
		    (33 (setf fg :yellow))
		    (34 (setf fg :blue))
		    (35 (setf fg :magenta))
		    (36 (setf fg :cyan))
		    (37 (setf fg :white))
		    (38 (setf hi-color :fg))
		    (39 (setf fg nil))
		    (40 (setf bg :black))
		    (41 (setf bg :red))
		    (42 (setf bg :green))
		    (43 (setf bg :yellow))
		    (44 (setf bg :blue))
		    (45 (setf bg :magenta))
		    (46 (setf bg :cyan))
		    (47 (setf bg :white))
		    (48 (setf hi-color :bg))
		    (49 (setf bg nil))
		    (otherwise #| just ignore unknown colors or attrs |#))))
	       (when (eql (char str (1- i)) #\m)
		 (dbugf :fatchar "@~s done ~s~%" i num)
		 (return)))))
       :while (< i len))
    (values
     ;; (if (and (eq fg :unset) (eq bg :unset) (not attr-was-set))
     ;; 	 1
     ;; 	 (- i start))
     i
     fg bg (if (not attr-was-set) :unset attr))))

(defun process-ansi-colors (fat-line)
  "Convert ANSI color escapes into colored fatchars."
  (when (zerop (length fat-line))
    (return-from process-ansi-colors fat-line))
  (let ((new-fat-line (make-stretchy-vector (length fat-line)
					    :element-type 'fatchar))
	(i 0)
	(len (length fat-line))
	;; @@@ Figure out how to get rid of this extra copy.
	(line (map 'string #'(lambda (x) (fatchar-c x)) fat-line))
	fg bg attrs)
    (labels ((char-at (i)
	       (fatchar-c (aref fat-line i)))
	     (looking-at-attrs ()
	       "Return true if might be looking at some attrs."
	       (and (< i (1- len))
		    (char= (char-at i) #\escape)
		    (char= (char-at (1+ i)) #\[)))
	     (get-attrs ()
	       "Get the attrs we might be looking at."
	       (incf i 2)		; the ^[ and [
	       (multiple-value-bind (offset i-fg i-bg i-attrs)
		   (grok-ansi-color line :start i)
		 (dbugf :fatchar "grok offset ~s fg ~s bg ~s attrs ~s~%" offset
			i-fg i-bg i-attrs)
		 (when offset
		   (unless (eq i-fg    :unset) (setf fg i-fg))
		   (unless (eq i-bg    :unset) (setf bg i-bg))
		   (unless (eq i-attrs :unset) (setf attrs i-attrs))
		   ;;(incf i inc))))	; for the parameters read
		   (setf i offset))))	; for the parameters read
	     (copy-char ()
	       "Copy the current character to result."
	       ;;(dbug "attrs = ~a~%" attrs)
	       ;;(dbug "(aref fat-line i) = ~a~%" (aref fat-line i))
	       (let ((new-attrs (union attrs (fatchar-attrs (aref fat-line i)))))
		 (stretchy:stretchy-append
		  new-fat-line (make-fatchar
				:c (fatchar-c (aref fat-line i))
				:fg fg :bg bg
				:attrs new-attrs)))
	       (incf i)))
      (loop :while (< i len) :do
	 (if (looking-at-attrs)
	     (get-attrs)
	     (copy-char))))
    new-fat-line))

(defun remove-effects (string)
  "Remove any terminal colors or attributes from STRING."
  (fatchar-string-to-string (process-ansi-colors (make-fatchar-string string))))

;; Methods from char-util:

(defmethod display-length ((c fatchar))
  "Return the length of the fat character for display."
  (cond
    ((not (zerop (fatchar-line c)))
     1)				    ; assume line drawing can happen in 1 cell
    ;; ((char= #\nul (fatchar-c c))
    ;;  0)		; since an unset fatchar is #\nul
    (t (display-length (fatchar-c c)))))

(defmethod display-length ((s fat-string))
  "Return the length of the string for display."
  (display-length (fat-string-to-string s)))

(defmethod simplify-string ((s fat-string))
  "Return the fat-string as a string."
  (fat-string-to-string s))

(defmethod simplify-char ((c fatchar))
  "Return the FATCHAR as a character."
  (fatchar-c c))

(defmethod graphemes ((string fat-string))
  (dbugf :fatchar "fat grapheme ~s ~s~%" (type-of string) string)
  (let (result)
    (do-graphemes (g (fat-string-string string)
		     :result-type fatchar :key fatchar-c)
      (push g result))
    (nreverse result)))

;; EOF
