;;;
;;; prompt.lisp - Things to make the prompt
;;;

(in-package :lish)

(defvar *lish-level* nil
  "Number indicating the depth of lish recursion. Corresponds to the ~
LISH_LEVEL environment variable.")

(defun fixed-homedir ()
  "(user-homedir-pathname) with a trailing slash removed if there was one."
  (let ((h (safe-namestring (truename (user-homedir-pathname)))))
    (if (equal #\/ (aref h (1- (length h))))
	(subseq h 0 (1- (length h)))
	h)))

(defun twiddlify (name)
  "Turn (user-homedir-pathname) occuring in name into a tilde."
  (replace-subseq (safe-namestring (fixed-homedir)) "~"
		  (safe-namestring name) :count 1))

;; This is mostly for bash compatibility.

(defun format-prompt (sh prompt &optional (escape-char #\%))
  "Return the prompt string with bash-like formatting character replacements.
So far we support:
%%      A percent.
%a      #\\bell
%e      #\\escape
%n      #\\newline
%r      #\\return
%NNN    The character whose ASCII code is the octal value NNN.
%s      The name of the shell, which is usually “Lish”.
%v      Shell version.
%V      Even more shell version.
%u      User name.
%h      Host name truncated at the first dot.
%H      Host name.
%w      Working directory, tildified.
%W      The basename of `$PWD', tildified.
%$      If the effective UID is 0, `#', otherwise `$'.
%i      The lisp implementation nickname.
%p      The shortest nickname of *lish-user-package*.
%P      The current value of *lish-user-package*.
%d      <3 char weekday> <3 char month name> <date>.
%t      24 hour HH:MM:SS
%T      12 hour HH:MM:SS
%@      The time, in 12-hour am/pm format.
%A      The time, in 24-hour HH:MM format.
Not implemented yet:
%!      The history number of this command.
%#      The command number of this command.
%[      Start of non-printing characters.
%]      End of non-printing characters.
%l      The basename of the shell's terminal device name.
%D{FORMAT}
        Some date formated by Unix strftime. Without the FORMAT just put some
        locale-specific date.
%j      The number of jobs currently managed by the shell.
"
  (declare (ignore sh))
  ;;(let ((out (make-stretchy-string 80)))
  (let ((out (make-stretchy-string (length prompt))))
    (with-output-to-string (str out)
      (loop :with c :for i :from 0 :below (length prompt) :do
	 (setf c (aref prompt i))
	 (if (equal c escape-char)
	     (progn
	       (incf i)
	       (when (< i (length prompt))
		 (setf c (aref prompt i))
		 (case c
		   (#\% (write-char escape-char str))
		   (#\a (write-char #\bell str))
		   (#\e (write-char #\escape str))
		   (#\n (write-char #\newline str))
		   (#\r (write-char #\return str))
		   ((#\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9)
		    (write-char (code-char
				 (parse-integer
				  (subseq prompt i (+ i 3)) :radix 8))
				str))
		   (#\s (write-string (princ-to-string *shell-name*) str))
		   (#\v (princ *major-version* str))
		   (#\V (write-string (princ-to-string *version*) str))
		   (#\u (write-string (nos:user-name) str))
		   (#\h (write-string
			 (initial-span (os-machine-instance) ".") str))
		   (#\H (write-string (machine-instance) str))
		   (#\w (write-string (twiddlify (nos:current-directory)) str))
		   (#\W (write-string
			 (twiddlify (basename (nos:current-directory))) str))
		   (#\$ (write-char
			 (if (= (nos:user-id :effective t) 0) #\# #\$) str))
		   (#\i (write-string (princ-to-string
				       *lisp-implementation-nickname*) str))
		   (#\p (write-string
			 (s+ (and *lish-user-package*
				  (shortest-package-nick *lish-user-package*)))
			 str))
		   (#\P (write-string
			 (s+ (and *lish-user-package*
				  (package-name *lish-user-package*))) str))
		   (#\d (write-string
			 (format-date "~3a ~3a ~2d"
				      (:day-abbrev :month-abbrev :date)) str))
		   (#\t (write-string
			 (format-date "~2,'0d:~2,'0d:~2,'0d"
				      (:hours :minutes :seconds)) str))
		   (#\T (write-string
			 (format-date "~2,'0d:~2,'0d:~2,'0d"
				      (:12-hours :minutes :seconds)) str))
		   (#\@ (write-string
			 (format-date "~2,'0d:~2,'0d ~2a"
				      (:12-hours :minutes :am)) str))
		   (#\A (write-string
			 (format-date "~2,'0d:~2,'0d" (:hours :minutes)) str))
		   )))
	     (write-char c str))))
    out))

(defun symbolic-prompt-to-string (sh symbolic-prompt #| &optional ts-in |#)
  "Take a symbolic prompt and turn it into a fat-string. This uses
span-to-fatchar-string with a filter of format-prompt and with the addition of
evaluation, so see the documentation of those for more detail,

Briefly, a symbolic prompt can be any printable lisp object, which is converted
to a fat string. If it is a list, it translates sublists starting with certain
keywords, to characters with text effects applied to the enclosed objects.
Some of the keywords recognized are:
  :BOLD :UNDERLINE :INVERSE
and the colors
  :BLACK :RED :GREEN :YELLOW :BLUE :CYAN :WHITE and :DEFAULT.
The colors can be prefixed by :FG- or :BG- for the foreground or background.
Complex colors are also supported, for example (:fg :color [color]), where
[color] can be something supported the color package, e.g. #(:RGB 0.1 0.7 0.9).

Evaluation is supported, so symbols will be replaced by their value and
functions will be evaluated with the primary result printed as a string.

Strings can have '%' directives which are expanded by format-prompt."
  ;; @@@ This docstring could use improvement?
  (fatchar:span-to-fat-string
   symbolic-prompt
   :filter (_ (format-prompt sh _))
   :unknown-func
   (lambda (x) ; eval is magic
     (cond
       ((and (listp x) (symbolp (car x)) (fboundp (car x)))
	;; (apply (car x) (cdr x))
	;; Actually we need a full eval here.
	(values (eval x) t)
	)
       ((symbolp x)
	(when (boundp x)
	  (values (symbol-value x) nil)))
       (t (values (princ-to-string x) nil))))))

#|
(defun fill-prompt ()
  (#\f (let ((len (length out)) out-char cols)
	 (when (> len 1)
	   (setf out-char (aref out (1- len))
		 cols (terminal-window-columns
		       (rl:line-editor-terminal
			(lish-editor sh))))
	   (loop :repeat (- cols len)
	      :do (write-char out-char str))))))

1. Expand the %<things> in the symbolic version.
2. Convert to fatchar and expand the %fill which can now know the true size
3. Convert from fatchar to final device form

|#

(defvar *fallback-prompt* "Lish> "
  "Prompt to use as a last resort.")

(defgeneric make-prompt (shell prompt)
  (:documentation "Return a string to prompt with."))
(defmethod make-prompt ((sh shell) prompt)
  "Return a string to prompt with."
  (or (and prompt
	   ;; (format-prompt
	   ;;  sh (symbolic-prompt-to-string (lish-prompt sh))))
	   (symbolic-prompt-to-string sh prompt))
      ;; (if (and (lish-prompt-char sh)
      ;; 	       (characterp (lish-prompt-char sh)))
      ;; 	  (format nil "~a "
      ;; 		  (make-string (+ 1 *lish-level*)
      ;; 			       :initial-element (lish-prompt-char sh)))
	  *fallback-prompt*))

;; This isn't even "safe".
(defun safety-prompt (sh &optional side)
  "Return a prompt, in a manner unlikely to fail."
  (let (prompt-error)
    (macrolet ((handle-it (&body body)
		 `(catch 'problems
		    (handler-case
			(progn ,@body)
		      (error (c)
			(setf prompt-error c)
			(throw 'problems nil))))))
      (if (eq side :right)
	  (or (and (lish-right-prompt sh)
		   (or
		    (handle-it (make-prompt sh (lish-right-prompt sh)))
		    (progn
		      (format t "Your right prompt is broken: ~s~%" prompt-error)
		      "")))
	      "")
	  (or (and (lish-prompt-function sh)
		   (or (handle-it (funcall (lish-prompt-function sh) sh))
		       (format t "Your prompt function failed: ~s.~%"
			       prompt-error)))
	      (or (handle-it (make-prompt sh (lish-prompt sh)))
		  (progn
		    (format t "Your prompt is broken: ~s~%" prompt-error)
		    *fallback-prompt*)))))))

(defun is-lisp-expr-p (expr)
  "Return true if the the shell expr is likely just a wrapped Lisp expr."
  (and (= 1 (length (shell-expr-words expr)))
       (or (consp (elt (shell-expr-words expr) 0))
	   (consp (word-word (elt (shell-expr-words expr) 0))))))

(defun is-probably-a-lisp-expr-p (word)
  (let ((trimmed (ltrim word)))
    (and (not (zerop (length trimmed)))
	 (eql #\( (aref trimmed 0)))))

(defun colorize-function (form env)
  (declare (ignore env))
  `(#\( (:fg-magenta ,(string-downcase (car form))) ,@(cdr form) #\)))

(defun colorize-atom (form env)
  (declare (ignore env))
  (s+ " " (string-downcase form)))

(defun colorize-lisp (expr fat-string)
  "Colorize a lisp expression."
  (declare (ignore expr fat-string))
  #|
  (dbugf :recolor "boglar-ize ~s~%" expr)
  (let* ((sexp (word-word (first (shell-expr-words expr))))
	 (colorized-span
	  (agnostic-lizard:walk-form sexp nil
				     :on-function-form #'colorize-function
				     :on-every-atom #'colorize-atom))
	 )
    (dbugf :recolor "smooty span ~s ~s ~s~%" sexp colorized-span
	   (olength fat-string))
    ;; (loop :with new = (span-to-fatchar-string colorized-span)
    ;;    :for i :from 0 :below (olength new)
    ;;    :do (setf (oelt fat-string i) (oelt new i)))
    (dbugf :recolor "smoot string ~s ~s~%" fat-string (olength fat-string)))
  |#
  )

(defun themify-shell-word-in-fat-string (word string theme-item)
  "Apply the THEME-ITEM, which should be a style, to the WORD in the fat
string STRING. Don't do anything if theme-item isn't found or is nil."
  (when (theme:theme-value theme:*theme* theme-item)
    (let* ((fcs string #| (fat-string-string string) |#)
	   (style (oelt (style:themed-string theme-item '("x")) 0)))
      ;; (dbugf :recolor "word ~s~%style ~s~%item ~s~%string ~s~%"
      ;; 	     word style theme-item string)
      (when (not (zerop (length (word-word word))))
	(loop :for i :from (shell-word-start word) :below (shell-word-end word)
	   :do (copy-fatchar-effects style (aref fcs i)))))))

(defun unthemify-shell-word-in-fat-string (word string)
  (loop :for i :from (shell-word-start word) :below (shell-word-end word)
     :do (remove-effects (aref string i))))

(defun colorize-expr (expr fat-str)
  "Colorize a shell expression."
  (let* ((first-word (and (shell-expr-p expr) (first (shell-expr-words expr))))
	 type)
    (flet ((theme-it (tt word)
	     "Apply theme TT to WORD."
	     (themify-shell-word-in-fat-string word fat-str tt)))
      (cond
	((is-lisp-expr-p expr)
	 (colorize-lisp expr fat-str))
	((and (listp first-word) (keywordp (first first-word)))
	 ;; colorize the sub-expression of a compound expression
	 (colorize-expr (second first-word) fat-str))
	((shell-expr-p expr)
	 (when (and first-word (stringp (word-word first-word)))
	   ;; @@@ stupid hack to not turn lisp red
	   (if (is-probably-a-lisp-expr-p (word-word first-word))
	       (progn
		 (dbugf :recolor "smellman ~s~%" (word-word first-word))
		 ;; (colorize-lisp (word-word first-word) fat-str)
		 (colorize-lisp expr fat-str)
		 )
	       (progn
		 (setf type (command-type *shell* (word-word first-word)
					  :already-known t))
		 ;; (dbugf :recolor "command-type ~s~%" type)
		 (case type
		   ((:external-command :builtin-command :shell-command :command
                     :alias :global-alias :function :loadable-system)
		    (dbugf :recolor "melgor ~s~%" first-word)
		    (theme-it `(:command ,type :style) first-word))
		   (:file
		    (theme-it '(:command :system-command :style) first-word))
		   (:directory
		    (theme-it '(:command :directory :style) first-word))
		   (otherwise
		    (dbugf :recolor "glorb ~s~%" first-word)
		    (theme-it '(:command :not-found :style) first-word))))))
	 (loop :for w :in (rest (shell-expr-words expr))
	    :do
	      (when (stringp (word-word w))
		(cond
		  ;; ((handler-case
		  ;;      (nos:file-exists (glob:expand-tilde (word-word w)))
		  ;;    (opsys-error (c)
		  ;;      (declare (ignore c))))
		  ((ignore-errors
		     (nos:file-exists (glob:expand-tilde (word-word w))))
		   (theme-it '(:command-arg :existing-path :style) w))
		  (t
		   (unthemify-shell-word-in-fat-string w fat-str))))))))))

(defun colorize (e)
  "Colorize the editor buffer."
  (when (lish-colorize *shell*)
    ;;(format t "buf = ~s ~s~%" (type-of (rl::buf e)) (rl::buf e))
    (catch 'whatever
      (handler-case
	  (progn
	    (let ((expr (shell-read (char-util:simplify-string (rl::buf e))
				    :partial t)))
	      (if (shell-expr-p expr)
		  (progn
		    (colorize-expr expr (rl::buf e)))
		  (progn
		    (dbugf :recolor "moomar ~s~%" expr))
		)))
	(error ()
	  ;; Errors are particularly useless and annoying here. 
	  (throw 'whatever nil))
	))))

;; EOF