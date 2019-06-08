;;
;; inator.lisp - Generic UI applet
;;

(defpackage :inator
  (:documentation
"This is a little scaffolding for making a certain style of applet. The style
that's encouraged is what one might call ‘emacs-like’. I consider this as a
‘lesser’ Frobulator, in other words a style of interaction and editing that
can be applied to many types of data.

To make an app, you subclass INATOR and provide editing, input and display
methods. You can also provide a custom keymap. You can probably get by with
just providing methods for UPDATE-DISPLAY and AWAIT-EVENT, and then calling
EVENT-LOOP with an INATOR sub-class instance.

There's a separate file-inator, for things that work with files. There is a
terminal based TERMINAL-INATOR package, but please don't ever call it
a TERM-INATOR.
")
  (:use :cl :dlib :keymap :char-util)
  (:export
   ;; Inator class
   #:inator
   #:inator-keymap
   #:inator-point
   #:inator-mark
   #:inator-clipboard
   #:inator-quit-flag
   #:inator-command
   #:inator-last-command

   ;; Commands
   #:next
   #:previous
   #:forward-unit
   #:backward-unit
   #:forward-multiple
   #:backward-multiple
   #:next-page
   #:previous-page
   #:move-to-beginning
   #:move-to-end
   #:move-to-top
   #:move-to-bottom
   #:search-command
   #:sort-command
   #:jump-command
   #:quit
   #:accept
   #:redraw
   #:cut
   #:copy
   #:paste
   #:select
   #:default-action
   #:describe-key-briefly
   ;; Output
   #:message
   #:prompt
   #:help
   ;; Events
   #:event-loop
   #:update-display
   #:await-event
   #:process-event
   #:call-command
   #:start-inator
   #:finish-inator
   #:resize
   #:*default-inator-keymap*
   #:*default-inator-escape-keymap*
   #:read-key-sequence
   #:with-inator
   ))
(in-package :inator)

(defclass inator ()
  ((keymap
    :initarg :keymap :accessor inator-keymap
    :documentation "What to do when a key is pressed.")
   (point
    :initarg :point :accessor inator-point
    :documentation "Where the action is.")
   (clipboard
    :initarg :clipboard :accessor inator-clipboard
    :documentation "An object to copy and paste with.")
   (mark
    :initarg :mark :accessor inator-mark
    :documentation "An editing reference position.")
   (quit-flag
    :initarg :quit-flag :accessor inator-quit-flag :initform nil :type boolean
    :documentation "True to quit the inator.")
   (command
    :initarg :command :accessor inator-command :initform nil
    :documentation "The current command.")
   (last-command
    :initarg :last-command :accessor inator-last-command :initform nil
    :documentation "The last command."))
  (:documentation
   "Have some kind of editing style interaction."))

;; Navigation
(defgeneric next (inator))
(defgeneric previous (inator))
(defgeneric forward-unit (inator))
(defgeneric backward-unit (inator))
(defgeneric forward-multiple (inator))
(defgeneric backward-multiple (inator))
(defgeneric next-page (inator))
(defgeneric previous-page (inator))
(defgeneric move-to-beginning (inator))
(defgeneric move-to-end (inator))
(defgeneric move-to-top (inator))
(defgeneric move-to-bottom (inator))
(defgeneric search-command (inator))
(defgeneric sort-command (inator))
(defgeneric jump-command (inator)) ; or maybe leap?

;; Action
(defgeneric quit (inator)
  (:documentation "Quit the Inator.")
  (:method ((i inator)) (setf (inator-quit-flag i) t)))
(defgeneric accept (inator)
  (:documentation "Accept the data and usually exit."))
(defgeneric redraw (inator)
  (:documentation "Redraw the screen."))

;; Edit?
(defgeneric cut (inator))		; kill
(defgeneric copy (inator))
(defgeneric paste (inator))		; yank
(defgeneric select (inator))		; mark
(defgeneric default-action (inator))

;; Help / Output

(defgeneric message (inator format-string &rest args)
  (:documentation "Display a short message. Usually one line."))

(defgeneric prompt (inator format-string &rest args)
  (:documentation "Display a short message, asking the user for input."))

(defgeneric help (inator)
  (:documentation "Display help, usually describing what keys do."))

(defgeneric describe-key-briefly (inator)
  (:documentation "Describe what a key does very briefly."))

;; Whole Inator functions
(defgeneric event-loop (inator)
  (:documentation "Start the inator, then continue updating the display,
waiting for events, and processing events, util the quit-flag is set.
Finish the inator when done."))
(defgeneric update-display (inator))
(defgeneric await-event (inator)
  (:documentation "Wait for an event. Return NIL if there was no event, for
example if reading it timed out, in which case the event-loop normally does
not call process-event with it."))
(defgeneric process-event (inator event &optional keymap-in))
(defgeneric start-inator (inator))
(defgeneric finish-inator (inator))
(defgeneric resize (inator)
  (:documentation "Called when we get a resize event."))

(defkeymap *default-inator-keymap*
  `((,(ctrl #\n)	. next)
    (,(ctrl #\p)	. previous)
    (,(ctrl #\f)	. forward-unit)
    (,(ctrl #\b)	. backward-unit)
    (,(meta-char #\f)	. forward-multiple)
    (,(meta-char #\b)	. backward-multiple)
    (,(ctrl #\v)	. next-page)
    (:page-down		. next-page)
    (,(meta-char #\v)	. previous-page)
    (:page-up		. previous-page)
    (,(ctrl #\a)	. move-to-beginning)
    (,(ctrl #\e)	. move-to-end)
    (,(meta-char #\<)	. move-to-top)
    (,(meta-char #\>)	. move-to-bottom)
    (,(ctrl #\s)	. search-command)
    (,(meta-char #\s)	. sort-command)	; ?
    (,(meta-char #\j)	. jump-command)	; ?
    (,(meta-char #\=)   . describe-key-briefly)
    (#\return		. accept)
    (,(ctrl #\l)	. redraw)
    (,(ctrl #\g)	. quit)
    (:resize		. resize)
    (#\escape		. *default-inator-escape-keymap*)
    )
  :default-binding 'default-action)

(defparameter *default-inator-escape-keymap*
  (build-escape-map *default-inator-keymap*))

(defgeneric read-key-sequence (inator)
  (:documentation "Read a key sequence from the inator input."))

;; Default methods

(defmethod default-action ((inator inator))
  "Default method which does nothing."
  (declare (ignore inator)))

(defmethod initialize-instance
    :after ((o inator) &rest initargs &key &allow-other-keys)
  "Initialize a inator."
  (declare (ignore initargs))
  (when (not (slot-boundp o 'keymap))
    (setf (slot-value o 'keymap) *default-inator-keymap*)))

(defmethod start-inator ((inator inator))
  "Default method which does nothing."
  (declare (ignore inator)))

(defmethod finish-inator ((inator inator))
  "Default method which does nothing."
  (declare (ignore inator)))

(defmethod resize ((inator inator))
  "Default method which calls redraw."
  (redraw inator))

(defmethod call-command ((inator inator) function args)
  "Default method to invoke inator commands. This can be useful to extend
command invocation, or have something done on every command. The default
is just to call function with the INATOR as the first argument and the list ARGS
as the subsequent arguments."
  (apply function inator args))

;; @@@ This is quite hairy and not really reflected in keymap.lisp
(defmethod process-event ((inator inator) event &optional keymap-in)
  "Default way to process an event."
  (with-slots (command last-command keymap) inator
    (setf last-command command)
    (let ((outer-map (or keymap-in keymap))
	  event-list result saved-list)
      (labels
	  ((apply-symbol (s &optional args)
	     (if (typep (symbol-function s) 'generic-function)
		 (if (compute-applicable-methods (symbol-function s)
						 (cons inator args))
		     (call-command inator s args)
		     (message inator "(~S) has no applicable methods." s))
		 (call-command inator s args)))
	   (get-event ()
	     "Get a event from L, or if not L then push on event-list."
	     (dbugf :event "get-event ~s~%" saved-list)
	     (if saved-list
		 (pop saved-list)
		 (let ((ev (await-event inator)))
		   (push ev event-list)
		   ev)))
	   (sub-process (ev map)
	     "Look up the definition in keymap M and try to invoke it."
	     (dbugf :event "sub-process ~s ~s ~s~%" ev saved-list map)
	     (when (setf command (key-definition ev map))
	       (invoke)))
	   (invoke ()
	     "Try to invoke command."
	     (dbugf :event "invoke ~s ~s~%" saved-list command)
	     (cond
	       ;; a list to apply
	       ((consp command)
		(if (fboundp (car command))
		    (progn
		      (apply-symbol (car command) (cdr command))
		      t)
		    (progn
		      (message inator "(~S) is not defined." (car command))
		      (return-from process-event))))
	       ;; something represted by a symbol
	       ((symbolp command)
		(cond
		  ; a function
		  ((fboundp command)
		   (apply-symbol command)
		   t)
		  ; a keymap
		  ((keymap-p (symbol-value command))
		   (sub-process (get-event) (symbol-value command)))))
	       ;; a plain keymap
	       ((keymap-p command)
		(sub-process (get-event) command))
	       ;; a function object
	       ((functionp command)
		(call-command inator command nil)
		t)
	       (t ; anything else
		(message inator "Key binding ~S is not a function or a keymap."
			 command)
		(return-from process-event nil))
	       ((not command)
		nil)
	       (t ;; anything else is an error
		(error "Weird thing in keymap: ~s." command)))))
	;; (push event event-list)
	(if (listp outer-map)
	    ;; Try all the keymaps in outer-map, saving events in event-list,
	    ;; until one invocation returns true. Re-pull events from
	    ;; event-list for subsequent lookups.
	    (loop
	       :for m :in outer-map
	       :while (not (setf result (sub-process event m)))
	       :do
	       (dbugf :event "try map ~s saved-list ~s~%" m saved-list)
	       (setf saved-list (reverse event-list)))
	    ;; Just one to try.
	    (setf result (sub-process event outer-map)))
	(when (not result)
	  ;;;(message inator "Event ~a is not bound in keymap ~w."
	  (message inator "Event ~s is not bound in keymap ~w."
		   event keymap))))))

(defmethod event-loop ((inator inator))
  "The default event loop. Using this loop a sub-class only has to supply the
UPDATE-DISPLAY and and AWAIT-EVENT methods."
  (unwind-protect
       (progn
	 (start-inator inator)
	 (update-display inator)
	 (loop :with event
	    :do
	    (when (setf event (await-event inator))
	      (process-event inator event))
	    :while (not (inator-quit-flag inator))
	    :do
	    (update-display inator)))
    (finish-inator inator)))

;; Yet another thin defclass wrapper.
#|
(defmacro definator (name superclasses slots &rest options)
  "Define an INATOR with class"
  (let* ((var-name (intern (s+ #\* name #\*)))
	 (with (intern (s+ "WITH-" (string-upcase name))))
	 keymap
	 real-options
	 initargs)
    (setf real-options
	  ;; round 1 - pick out a :keymap option
	  (loop :for o :in options
	     :if (and (consp o) (eq (car o) :keymap))
	     :do (setf keymap (second o))
	     :else
	     :collect o)
	  ;; round 2 - put it back in a :default-initargs for the class
	  real-options
	  (if (setf initargs (find :default-initargs real-options #'car))
	      ;;
	      ))
    `(progn
       (defvar ,var-name nil ,(s+ "The current " name "."))
       (defclass ,name ,@superclasses ,@slots ,@real-options)
       (defmacro ,with (var)
	 `(let ((,var (make-ins
       )))
|#

;; “Unnecessary Syntactic Sugar”™
(defmacro with-inator ((var type &rest args) &body body)
  "Evaluate BODY with a new inator of type TYPE, made with ARGS passed to
MAKE-INSTANCE, with VAR bound to the new instance."
  `(let ((,var (make-instance ,type ,@args)))
     ,@body))

;; EOF
