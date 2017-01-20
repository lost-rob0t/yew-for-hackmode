;;;								-*- Lisp -*-
;;; rl.asd -- System definition for RL package
;;;

(defsystem rl
  :name               "rl"
  :description        "A line editor."
  :version            "0.1.0"
  :author             "Nibby Nebbulous <nibbula -(. @ .)- gmail.com>"
  :licence            "GPLv3"
  :long-description   "A line editor which is not so tiny."
  :depends-on (:dlib :dlib-misc :dl-list :stretchy :char-util
	       ;; :cffi
	       :opsys :termios
	       :terminal :terminal-ansi :terminal-curses :fatchar
	       :completion :keymap :syntax-lisp
	       :unipose)
  :serial t	; not entirely correct, but convenient
  :components
  ((:file "package")
   (:file "editor")
   (:file "history")
   (:file "undo")
   (:file "buffer")
   (:file "display")
   (:file "complete")
   (:file "commands")
   (:file "rl"))
  :in-order-to ((test-op (load-op "rl-test")))
  :perform (test-op (o c) (symbol-call :rl-test :run)))
