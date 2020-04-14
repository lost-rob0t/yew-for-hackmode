;;
;; unix/terminals.lisp - Unix interface to terminals
;;

(in-package :opsys-unix)

(declaim #.`(optimize ,.(getf opsys-config::*config* :optimization-settings)))

#-(or darwin sunos linux freebsd openbsd)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (error "Your platform is not really supported yet."))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro deftermio (name doc array)
    `(progn
       (define-constants-from ,array)
       (define-name-list-from ,name ,array ,doc))))
      ;; (with-unique-names (tt-var)
      ;; `(progn
      ;; 	 (defparameter ,tt-var ,array)
      ;; 	 (define-constants-from ,tt-var)
      ;; 	 (define-name-list-from ,name ,tt-var ,doc)))


#+(and darwin 64-bit-target) (defctype tcflag-t :unsigned-long)
#-(and darwin 64-bit-target) (defctype tcflag-t :unsigned-int)
#+(and darwin 64-bit-target) (defctype speed-t :unsigned-long)
#-(and darwin 64-bit-target) (defctype speed-t :unsigned-int)
(defctype cc-t :unsigned-char)

;; control chars (c_cc)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (deftermio *cchars* "A list of all the control character symbols." #(
;; Name         Darwin Linux SunOS FreeBSD OpenBSD
#(+VEOF+	0      4     4     0       0)
#(+VEOL+	1      11    5     1       1)
#(+VEOL2+	2      16    6     2       2)
#(+VERASE+	3      2     2     3       3)
#(+VWERASE+	4      14    14    4       4)
#(+VKILL+	5      3     3     5       5)
#(+VREPRINT+	6      12    12    6       6)
#(+VERASE2+	nil    nil   nil   7       nil)
#(+VINTR+	8      0     0     8       8)
#(+VQUIT+	9      1     1     9       9)
#(+VSUSP+	10     10    10    10      10)
#(+VDSUSP+	11     nil   11    11      11)
#(+VSWTCH+	nil    nil   7     nil     nil)
#(+VSTART+	12     8     8     12      12)
#(+VSTOP+	13     9     9     13      13)
#(+VLNEXT+	14     15    15    14      14)
#(+VDISCARD+	15     13    13    15      15)
#(+VMIN+	16     6     4     16      16)
#(+VTIME+	17     5     5     17      17)
#(+VSTATUS+	18     nil   nil   18      18)
)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defconstant +NCCS+ #+darwin 20
                      #+sunos 19
                      #+linux 32
                      #+freebsd 20
                      #+openbsd 20))

(defcstruct termios
    "POSIX terminal driver interface structure"
  (c_iflag  tcflag-t)			; input flags
  (c_oflag  tcflag-t)			; output flags
  (c_cflag  tcflag-t)			; control flags
  (c_lflag  tcflag-t)			; local flags
  #+linux (c_line cc-t)			; line discipline
  (c_cc     cc-t :count #.+NCCS+)	; control chars
  (c_ispeed speed-t)			; input speed
  (c_ospeed speed-t))			; output speed

;; input flags (c_iflag)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (deftermio *iflags* "List of the input flag symbols." #(
;; Name         Darwin     Linux     SunOS     FreeBSD    OpenBSD
#(+IGNBRK+	#x00000001 #o0000001 #o0000001 #x00000001 #x00000001 "Ignore BREAK condition")
#(+BRKINT+	#x00000002 #o0000002 #o0000002 #x00000002 #x00000002 "Map BREAK to SIGINTR")
#(+IGNPAR+	#x00000004 #o0000004 #o0000004 #x00000004 #x00000004 "Ignore (discard) parity errors")
#(+PARMRK+	#x00000008 #o0000010 #o0000010 #x00000008 #x00000008 "Mark parity and framing errors")
#(+INPCK+	#x00000010 #o0000020 #o0000020 #x00000010 #x00000010 "Enable checking of parity errors")
#(+ISTRIP+	#x00000020 #o0000040 #o0000040 #x00000020 #x00000020 "Strip 8th bit off chars")
#(+INLCR+	#x00000040 #o0000100 #o0000100 #x00000040 #x00000040 "Map NL into CR")
#(+IGNCR+	#x00000080 #o0000200 #o0000200 #x00000080 #x00000080 "Ignore CR")
#(+ICRNL+	#x00000100 #o0000400 #o0000400 #x00000100 #x00000100 "Map CR to NL (ala CRMOD)")
#(+IXON+	#x00000200 #o0002000 #o0002000 #x00000200 #x00000200 "Enable output flow control")
#(+IXOFF+	#x00000400 #o0010000 #o0010000 #x00000400 #x00000400 "Enable input flow control")
#(+IXANY+	#x00000800 #o0004000 #o0004000 #x00000800 #x00000800 "Any char will restart after stop")
#(+IMAXBEL+	#x00002000 #o0020000 #o0020000 #x00002000 #x00002000 "Ring bell on input queue full")
#(+IUCLC+	nil        #o0001000 #o0001000 nil        #x00001000 "Map uppercase to lowercase")
#(+IUTF8+	nil        #o0040000 nil       nil        nil        "Input is UTF-8")
#(+DOSMODE+	nil        nil       #o0100000 nil        nil        "DOS mode")
)))

;; output flags (c_oflag)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (deftermio *oflags* "List of oflags symbols." #(
;; Name       Darwin     Linux     SunOS     FreeBSD    OpenBSD
#(+OPOST+     #x00000001 #o0000001 #o0000001 #x00000001 #x00000001 "Enable following output processing")
#(+ONLCR+     #x00000002 #o0000004 #o0000004 #x00000002 #x00000002 "Map NL to CR-NL (ala CRMOD)")
#(+OXTABS+    #x00000004 #o0014000 #o0014000 #x00000004 #x00000004 "Expand tabs to spaces")
#(+ONOEOT+    #x00000008 nil       nil       #x00000008 #x00000008 "Discard EOT's (^D) on output)")
#(+OLCUC+     nil        #o0000002 #o0000002 nil        #x00000020 "Output lowercase to uppercase")
#(+OCRNL+     nil        #o0000010 #o0000010 #x00000010 #x00000010 "Map CR to NL on output")
#(+ONOCR+     #x00000020 #o0000020 #o0000020 #x00000020 #x00000040 "No CR output at column 0")
#(+ONLRET+    #x00000040 #o0000040 #o0000040 #x00000040 #x00000080 "NL performs CR function")
#(+OFILL+     nil        #o0000100 #o0000100 nil        nil        "Send fill chars for delay")
#(+OFDEL+     nil        #o0000200 #o0000200 nil        nil        "Fill char is DEL (ASCII 127)")
#(  +NLDLY+   nil        #o0000400 #o0000400 nil        nil)
#(    +NL0+   nil        #o0000000 #o0000000 nil        nil)
#(    +NL1+   nil        #o0000400 #o0000400 nil        nil)
#(  +CRDLY+   nil        #o0003000 #o0003000 nil        nil)
#(    +CR0+   nil        #o0000000 #o0000000 nil        nil)
#(    +CR1+   nil        #o0001000 #o0001000 nil        nil)
#(    +CR2+   nil        #o0002000 #o0002000 nil        nil)
#(    +CR3+   nil        #o0003000 #o0003000 nil        nil)
#( +TABDLY+   nil        #o0014000 #o0014000 #x00000004 nil)
#(   +TAB0+   nil        #o0000000 #o0000000 #x00000000 nil)
#(   +TAB1+   nil        #o0004000 #o0004000 nil        nil)
#(   +TAB2+   nil        #o0010000 #o0010000 nil        nil)
#(   +TAB3+   nil        #o0014000 #o0014000 #x00000004 nil)
#(  +BSDLY+   nil        #o0020000 #o0020000 nil        nil)
#(    +BS0+   nil        #o0000000 #o0000000 nil        nil)
#(    +BS1+   nil        #o0020000 #o0020000 nil        nil)
#(  +FFDLY+   nil        #o0100000 #o0100000 nil        nil)
#(    +FF0+   nil        #o0000000 #o0000000 nil        nil)
#(    +FF1+   nil        #o0100000 #o0100000 nil        nil)
#(  +VTDLY+   nil        #o0040000 #o0040000 nil        nil)
#(    +VT0+   nil        #o0000000 #o0000000 nil        nil)
#(    +VT1+   nil        #o0040000 #o0040000 nil        nil)
#(  +XTABS+   nil        #o0014000 nil       nil        nil)
#(+PAGEOUT+   nil        nil       #o0200000 nil        nil)
#(   +WRAP+   nil        nil       #o0400000 nil        nil))))

;; Control flags - hardware control of terminal (c_cflag)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (deftermio *cflags* "List of the control flag symbols." #(
;; Name        Darwin     Linux          SunOS          FreeBSD    OpenBSD
#(+CIGNORE+    #x00000001 nil            nil            #x00000001 #x00000001 "Ignore control flags")
#(+CSIZE+      #x00000300 #o0000060      #o0000060      #x00000300 #x00000300 "Character size mask")
#(+CS5+        #x00000000 #o0000000      #o0000000      #x00000000 #x00000000 "5 bits (pseudo)")
#(+CS6+        #x00000100 #o0000020      #o0000020      #x00000100 #x00000100 "6 bits")
#(+CS7+        #x00000200 #o0000040      #o0000040      #x00000200 #x00000200 "7 bits")
#(+CS8+        #x00000300 #o0000060      #o0000060      #x00000300 #x00000300 "8 bits")
#(+CSTOPB+     #x00000400 #o0000100      #o0000100      #x00000400 #x00000400 "Send 2 stop bits")
#(+CREAD+      #x00000800 #o0000200      #o0000200      #x00000800 #x00000800 "Enable receiver")
#(+PARENB+     #x00001000 #o0000400      #o0000400      #x00001000 #x00001000 "Parity enable")
#(+PARODD+     #x00002000 #o0001000      #o0001000      #x00002000 #x00002000 "Odd parity, else even")
#(+HUPCL+      #x00004000 #o0002000      #o0002000      #x00004000 #x00004000 "Hang up on last close")
#(+CLOCAL+     #x00008000 #o0004000      #o0004000      #x00008000 #x00008000 "Ignore modem status lines")
#(+CCTS_OFLOW+ #x00010000 nil            #o010000000000 #x00010000 #x00100000 "CTS flow control of output")
#(+CRTS_IFLOW+ #x00020000 nil            #o020000000000 #x00020000 #x00100000 "RTS flow control of input")
#(+CRTSCTS+    #x00030000 #o020000000000 #o020000000000 #x00030000 #x00100000 "RTS/CTS full-duplex flow control")
#(+CDTR_IFLOW+ #x00040000 nil            nil            #x00040000 #x00040000 "DTR flow control of input")
#(+CDSR_OFLOW+ #x00080000 nil            nil            #x00080000 #x00080000 "DSR flow control of output")
#(+CCAR_OFLOW+ #x00100000 nil            nil            #x00100000 #x00100000 "DCD flow control of output")
#(+MDMBUF+     #x00100000 nil            nil            #x00100000 #x00100000 "old name for CCAR_OFLOW")
#(+CBAUDEX+    nil        #o0010000      nil            nil        nil        "")
#(+CMSPAR+     nil        #o010000000000 nil            nil        nil        "mark or space (stick) parity"))))

;; local flags (c_lflag)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (deftermio *lflags* "List of lflag symbols." #(
;; Name        Darwin     Linux     SunOS     FreeBSD    OpenBSD
#(+ECHOKE+     #x00000001 #o0004000 #o0004000 #x00000001 #x00000001 "visual erase for line kill")
#(+ECHOE+      #x00000002 #o0000020 #o0000010 #x00000002 #x00000002 "visually erase chars")
#(+ECHOK+      #x00000004 #o0000040 #o0000040 #x00000004 #x00000004 "echo NL after line kill")
#(+ECHO+       #x00000008 #o0000010 #o0000010 #x00000008 #x00000008 "enable echoing")
#(+ECHONL+     #x00000010 #o0000100 #o0000100 #x00000010 #x00000010 "echo NL even if ECHO is off")
#(+ECHOPRT+    #x00000020 #o0002000 #o0002000 #x00000020 #x00000020 "visual erase mode for hardcopy")
#(+ECHOCTL+    #x00000040 #o0001000 #o0001000 #x00000040 #x00000040 "echo control chars as ^(Char)")
#(+ISIG+       #x00000080 #o0000001 #o0000001 #x00000080 #x00000080 "enable signals INTR, QUIT, [D]SUSP")
#(+ICANON+     #x00000100 #o0000002 #o0000002 #x00000100 #x00000100 "canonicalize input lines")
#(+ALTWERASE+  #x00000200 nil       nil       #x00000200 #x00000200 "use alternate WERASE algorithm")
#(+IEXTEN+     #x00000400 #o0100000 #o0100000 #x00000400 #x00000400 "enable DISCARD and LNEXT")
#(+EXTPROC+    #x00000800 nil       nil       #x00000800 #x00000800 "external processing")
#(+TOSTOP+     #x00400000 #o0000400 #o0000400 #x00400000 #x00400000 "stop background jobs from output")
#(+FLUSHO+     #x00800000 #o0010000 #o0020000 #x00800000 #x00800000 "output being flushed (state)")
#(+NOKERNINFO+ #x02000000 nil       nil       #x02000000 #x02000000 "no kernel output from VSTATUS")
#(+PENDIN+     #x20000000 #o0040000 #o0040000 #x20000000 #x20000000 "XXX retype pending input (state)")
#(+NOFLSH+     #x80000000 #o0000200 #o0000200 #x80000000 #x80000000 "don't flush after interrupt"))))

#+sunos (defconstant +TIOC+ (ash 84 8))

;; Commands passed to tcsetattr() for setting the termios structure.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-constants #(
;; Name       Darwin Linux SunOS              FreeBSD OpenBSD
#(+TCSANOW+   0      0     (logior +TIOC+ 14) 0       0       "make change immediate")
#(+TCSADRAIN+ 1      1     (logior +TIOC+ 15) 1       1       "drain output, then change")
#(+TCSAFLUSH+ 2      2     (logior +TIOC+ 16) 2       2       "drain output, flush input")
#(+TCSASOFT+  #x10   nil   nil                #x10    #x10    "flag - don't alter h.w. state"))))

;; Standard speeds
(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-constants #(
;; Name     Darwin Linux      SunOS FreeBSD OpenBSD
#(+B0+      0       #o0000000  0    0       0     )
#(+B50+     50      #o0000001  1    50      50    )
#(+B75+     75      #o0000002  2    75      75    )
#(+B110+    110     #o0000003  3    110     110   )
#(+B134+    134     #o0000004  4    134     134   )
#(+B150+    150     #o0000005  5    150     150   )
#(+B200+    200     #o0000006  6    200     200   )
#(+B300+    300     #o0000007  7    300     300   )
#(+B600+    600     #o0000010  8    600     600   )
#(+B1200+   1200    #o0000011  9    1200    1200  )
#(+B1800+   1800    #o0000012  10   1800    1800  )
#(+B2400+   2400    #o0000013  11   2400    2400  )
#(+B4800+   4800    #o0000014  12   4800    4800  )
#(+B9600+   9600    #o0000015  13   9600    9600  )
#(+B19200+  19200   #o0000016  14   19200   19200 )
#(+B38400+  38400   #o0000017  15   38400   38400 )
#(+B7200+   7200    nil        nil  7200    7200  )
#(+B14400+  14400   nil        nil  14400   14400 )
#(+B28800+  28800   nil        nil  28800   28800 )
#(+B57600+  57600   nil        16   57600   57600 )
#(+B76800+  76800   nil        17   76800   76800 )
#(+B115200+ 115200  nil        18   115200  115200)
#(+B230400+ 230400  nil        20   230400  230400)
#(+B460800+ nil     nil        nil  460800  nil   )
#(+B921600+ nil     nil        nil  921600  nil   )
#(+EXTA+    19200   #o0000016  nil  19200   19200 )
#(+EXTB+    38400   #o0000017  nil  38400   38400 )))

  (define-constants #(
;; Name       Darwin Linux SunOS FreeBSD OpenBSD
#(+TCIFLUSH+  1      0     0     1       1)
#(+TCOFLUSH+  2      1     1     2       2)
#(+TCIOFLUSH+ 3      2     2     3       3)
#(+TCOOFF+    1      0     0     1       1)
#(+TCOON+     2      1     1     2       2)
#(+TCIOFF+    3      2     2     3       3)
#(+TCION+     4      3     3     4       4))))

(defcfun cfgetispeed speed-t (tio :pointer))
(defcfun cfgetospeed speed-t (tio :pointer))
(defcfun cfsetispeed :int (tio :pointer) (speed speed-t))
(defcfun cfsetospeed :int (tio :pointer) (speed speed-t))
(defcfun tcgetattr :int (fd :int) (tio :pointer))
(defcfun tcsetattr :int (fd :int) (action :int) (tio :pointer))
(defcfun tcdrain :int (fd :int))
(defcfun tcflow :int (fd :int) (action :int))
(defcfun tcflush :int (fd :int) (action :int))
(defcfun tcsendbreak :int (fd :int) (len :int))

#-sunos (defcfun cfmakeraw :void (tio :pointer))
#-sunos (defcfun cfsetspeed :int (tio :pointer) (speed speed-t))

;; The tty also stores the process group to know who to send job control
;; signals to.
(defcfun tcsetpgrp :int (fd :int) (pgid pid-t))
(defcfun tcgetpgrp pid-t (fd :int))

(defcfun isatty  :int (fd :int))
(defcfun ttyname :string (fd :int))

;; Now for even more non-standard freakshow!

#+(or darwin freebsd openbsd) ;; & maybe others?
(progn
  (defconstant +IOCPARM_MASK+ #x1fff "Parameter length, at most 13 bits")
  (defmacro IOCPARM_LEN (x) `(logand (ash ,x -16) +IOCPARM_MASK+))
  (defmacro IOCBASECMD (x) `(logand ,x (lognot (ash +IOCPARM_MASK+ -16))))
  (defmacro IOGROUP (x) `(logand (ash ,x -8) #xff))
  (defconstant +IOCPARM_MAX+ (1+ +IOCPARM_MASK+) "Max size of ioctl args")
  (defconstant +IOC_VOID+    #x20000000 "No parameters")
  (defconstant +IOC_OUT+     #x40000000 "Copy parameters out")
  (defconstant +IOC_IN+	     #x80000000 "Copy parameters in")
  (defconstant +IOC_INOUT+   (logior +IOC_IN+ +IOC_OUT+) "Copy paramters in and out")
  (defconstant +IOC_DIRMASK+ #xe0000000 "mask for IN/OUT/VOID")

  (defmacro _IOC (inout group num len)
    (let ((grp (etypecase group
		 (integer group)
		 (character (char-int group)))))
      `(logior ,inout (ash (logand ,len +IOCPARM_MASK+) 16)
	       (ash ,grp 8) ,num)))

  (defmacro _IO   (g n)    `(_IOC +IOC_VOID+  ,g ,n 0))
  (defmacro _IOR  (g n ty) `(_IOC +IOC_OUT+   ,g ,n ,(foreign-type-size ty)))
  (defmacro _IOW  (g n ty) `(_IOC +IOC_IN+    ,g ,n ,(foreign-type-size ty)))
  (defmacro _IOWR (g n ty) `(_IOC +IOC_INOUT+ ,g ,n ,(foreign-type-size ty))))

;; "Window sizes. Not used by the kernel. Just for applications."
(defcstruct winsize
  (ws_row    :unsigned-short)		; rows, in characters
  (ws_col    :unsigned-short)		; columns, in characters
  (ws_xpixel :unsigned-short)		; horizontal size, pixels
  (ws_ypixel :unsigned-short))		; vertical size, pixels

;; @@@ Hold off on these
#|
(defconstant TIOCMODG (_IOR 't'  3 :int) "get modem control state")
(defconstant TIOCMODS (_IOW 't'  4 :int) "set modem control state")

(defconstant +TIOCM_LE+	   0001		"line enable")
(defconstant +TIOCM_DTR+   0002		"data terminal ready")
(defconstant +TIOCM_RTS+   0004		"request to send")
(defconstant +TIOCM_ST+	   0010		"secondary transmit")
(defconstant +TIOCM_SR+	   0020		"secondary receive")
(defconstant +TIOCM_CTS+   0040		"clear to send")
(defconstant +TIOCM_CAR+   0100		"carrier detect")
(defconstant +TIOCM_CD+	   +TIOCM_CAR+)
(defconstant +TIOCM_RNG+   0200		"ring")
(defconstant +TIOCM_RI+	   +TIOCM_RNG+)
(defconstant +TIOCM_DSR+   0400		"data set ready")
					    ; 8-10 compat
(defconstant +TIOCEXCL+	 (_IO #\t 13)	    "set exclusive use of tty")
(defconstant +TIOCNXCL+	 (_IO #\t 14)	    "reset exclusive use of tty")
					    ;; 15 unused
(defconstant +TIOCFLUSH+ (_IOW #\t 16 :int) "flush buffers")
					    ;; 17-18 compat
(defconstant +TIOCGETA+	 (_IOR #\t 19 (:struct termios)) "get termios struct")
(defconstant +TIOCSETA+	 (_IOW #\t 20 (:struct termios)) "set termios struct")
(defconstant +TIOCSETAW+ (_IOW #\t 21 (:struct termios)) "drain output, set")
(defconstant +TIOCSETAF+ (_IOW #\t 22 (:struct termios)) "drn out, fls in, set")
(defconstant +TIOCGETD+	 (_IOR #\t 26 int)   "get line discipline")
(defconstant +TIOCSETD+	 (_IOW #\t 27 int)   "set line discipline")
					     ;; 127-124 compat
(defconstant +TIOCSBRK+	 (_IO #\t 123)	     "set break bit")
(defconstant +TIOCCBRK+	 (_IO #\t 122)	     "clear break bit")
(defconstant +TIOCSDTR+	 (_IO #\t 121)	     "set data terminal ready")
(defconstant +TIOCCDTR+	 (_IO #\t 120)	     "clear data terminal ready")
(defconstant +TIOCGPGRP+ (_IOR #\t 119 :int) "get pgrp of tty")
(defconstant +TIOCSPGRP+ (_IOW #\t 118 :int) "set pgrp of tty")
					     ;; 117-116 compat
(defconstant +TIOCOUTQ+	 (_IOR #\t 115 :int) "output queue size")
 |#

;; SunOS TIOC and tIOC constants

;;#+sunos (defconstant little-tioc #.(ash 116 8)) ; 166 = (char-int #\t)
;;#+sunos (defconstant big-tioc    #.(ash 84  8)) ;  84 = (char-int #\T)
;;#+sunos (defconstant little-tioc (ash (char-int #\t) 8)) ; 166 << 8 = 42496
;;#+sunos (defconstant big-tioc    (ash (char-int #\T) 8)) ;  84 << 8 = 21504
;;#+sunos (defmacro l-tioc (n) (logior n little-tioc))
;;#+sunos (defmacro b-tioc (n) (logior n big-tioc))
#+sunos (defmacro l-tioc (n) (logior n (ash (char-int #\t) 8)))
#+sunos (defmacro b-tioc (n) (logior n (ash (char-int #\T) 8)))

;; Who wouldn't love this one.
;; @@@ I don't understand why it doesn't work on Lispworks.
#+(or darwin freebsd openbsd)
(defconstant TIOCSTI #-lispworks (_IOW #\t 114 :char) "simulate terminal input")
#+sunos   (defconstant TIOCSTI (l-tioc 23)          "simulate terminal input")
#+linux   (defconstant TIOCSTI #x5412               "simulate terminal input")

#|
(defconstant +TIOCNOTTY+         (_IO #\t 113)	      "void tty association")
(defconstant +TIOCPKT+	         (_IOW #\t 112 :int)  "pty: set/clear packet mode")
(defconstant +TIOCPKT_DATA+       #x00		      "data packet")
(defconstant +TIOCPKT_FLUSHREAD+  #x01		      "flush packet")
(defconstant +TIOCPKT_FLUSHWRITE+ #x02		      "flush packet")
(defconstant +TIOCPKT_STOP+       #x04		      "stop output")
(defconstant +TIOCPKT_START+      #x08		      "start output")
(defconstant +TIOCPKT_NOSTOP+     #x10		      "no more ^S, ^Q")
(defconstant +TIOCPKT_DOSTOP+     #x20		      "now do ^S ^Q")
(defconstant +TIOCPKT_IOCTL+      #x40		      "state change of pty driver")
(defconstant +TIOCSTOP+	          (_IO #\t 111)	      "stop output, like ^S")
(defconstant +TIOCSTART+          (_IO #\t 110)	      "start output, like ^Q")
(defconstant +TIOCMSET+	          (_IOW #\t 109 :int) "set all modem bits")
(defconstant +TIOCMBIS+	          (_IOW #\t 108 :int) "bis modem bits")
(defconstant +TIOCMBIC+	          (_IOW #\t 107 :int) "bic modem bits")
(defconstant +TIOCMGET+	          (_IOR #\t 106 :int) "get all modem bits")
(defconstant +TIOCREMOTE+         (_IOW #\t 105 :int) "remote input editing")
|#

;; These are actually useful!
#+(or darwin freebsd openbsd)
(defconstant +TIOCGWINSZ+
	   #-lispworks (_IOR #\t 104  (:struct winsize))
	   #+lispworks #x40087468
	   "get window size")

#+(or darwin freebsd openbsd)
(defconstant +TIOCSWINSZ+
	   #-lispworks (_IOW #\t 103  (:struct winsize))
	   #+lispworks #x80087467
	   "set window size")

#+sunos (defconstant +TIOCGWINSZ+ (b-tioc 104) "get window size")
#+sunos (defconstant +TIOCSWINSZ+ (b-tioc 103) "set window size")

#+linux (defconstant +TIOCGWINSZ+ #x5413 "get window size")
#+linux (defconstant +TIOCSWINSZ+ #x5414 "set window size")

#|
(defun UIOCCMD (n) "User control OP 'n'" (_IO #\u n))
(defconstant +TIOCUCNTL+       (_IOW #\t 102 :int)	       "pty: set/clr usr cntl mode")
(defconstant +TIOCSTAT+	       (_IO #\t 101)		       "simulate ^T status message")
(defconstant +TIOCSCONS+       (_IO #\t 99))
(defconstant +TIOCCONS+	       (_IOW #\t 98 :int)	       "become virtual console")
(defconstant +TIOCSCTTY+       (_IO #\t 97)		       "become controlling tty")
(defconstant +TIOCEXT+	       (_IOW #\t 96 :int)	       "pty: external processing")
(defconstant +TIOCSIG+	       (_IO #\t 95)		       "pty: generate signal")
(defconstant +TIOCDRAIN+       (_IO #\t 94)		       "wait till output drained")
(defconstant +TIOCMSDTRWAIT+   (_IOW #\t 91 :int)	       "modem: set wait on close")
(defconstant +TIOCMGDTRWAIT+   (_IOR #\t 90 :int)	       "modem: get wait on close")
(defconstant +TIOCTIMESTAMP+   (_IOR #\t 89 (:struct timeval)) "enable/get timestamp of last input event")
(defconstant +TIOCDCDTIMESTAMP+ (_IOR #\t 88, struct timeval)  "enable/get timestamp of last DCd rise")
(defconstant +TIOCSDRAINWAIT+  (_IOW #\t 87, int)	       "set ttywait timeout")
(defconstant +TIOCGDRAINWAIT+  (_IOR #\t 86, int)	       "get ttywait timeout")
(defconstant +TIOCDSIMICROCODE+ (_IO #\t 85)		       "download microcode to DSI Softmodem")

(defconstant +TTYDISC+	0 "termios tty line discipline")
(defconstant +TABLDISC+	3 "tablet discipline")
(defconstant +SLIPDISC+	4 "serial IP discipline")
(defconstant +PPPDISC+	5 "PPP discipline")

|#

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Miscellaneous testing and insanity

(defun getch (tty &optional (debug nil))
  "Read a character from the tty."
  (with-foreign-object (c :char)
    (let ((status (posix-read tty c 1)))
      (cond
	((< status 0)
	 (error "getch Read error ~d~%" status))
	((= status 0)
	 nil)
	((= status 1)
	 (format debug "read ~d~%" (mem-ref c :char))
	 (mem-ref c :unsigned-char))))))

;; @@@ This should go in some testing thing.
(defun pushcat-file (tty filename &optional (debug nil))
  "Show a file by characters or lines, controlled by the user."
  (handler-case
      (with-open-file (d filename)
	(handler-case
	    (let ((quit-flag nil))
	      (loop do
		    (case (code-char (getch tty debug))
		      ((#\q #\Q nil)
		       (setf quit-flag t))
		      (#\space
		       (write-char (read-char d))
		       (finish-output))
		      ((#\newline #\return)
		       (write-line (read-line d))))
		    while (not quit-flag)))
	  (end-of-file ())))
    (file-error (c)
	(format t "~a" c))))
;; Check out the graceful shwoop!

(defun raw-echo (tty)
  "Output each character input immediately without processing. This is like of
like 'local' mode in real old fashioned terminals. This is useful for doing
experiments directly with the terminal emulator."
  (format t "You're talking directly to the terminal now.~c~c"
	  #\return #\linefeed)
  (format t "Press <ESC> four times in a row to stop.~c~c" #\return #\linefeed)
  (let ((escape 0) c)
    (loop :while (< escape 4)
       :do
       (setf c (code-char (getch tty)))
       (princ c) (finish-output)
       (if (eql c #\escape)
	   (incf escape)
	   (setf escape 0)))))

;; @@@ This should go in some testing thing.
(defun input-test (tty)
  (format t "Testing input characters.~c~c" #\return #\linefeed)
  (format t "Press <ESC> four times in a row to stop.~c~c" #\return #\linefeed)
  (let ((escape 0) c)
    (loop :while (< escape 4)
       :do
       (setf c (getch tty))
       (if c
	   (progn
	     (format t "~d #x~x #o~o ~s~c~c" c c c (code-char c)
		     #\return #\linefeed)
	     (finish-output))
	   (format t "no character read~c~c" #\return #\linefeed))
       (if (eql (code-char c) #\escape)
	   (incf escape)
	   (setf escape 0)))))

(defun call-with-raw (tty func &key very-raw timeout)
  "Call the FUNC with the TTY set for raw input. FUNC is called with the TTY
as it's argument. It sets up the file descriptor for raw input, and cleans up
afterwards. If VERY-RAW is true, set the terminal to the most raw state, which
doesn't even process interrupts. If TIMEOUT is true, it's a number of
deciseconds, (by setting VTIME) to wait before a read returns nothing."
  (let (raw cooked result)
    (unwind-protect
	 (progn
	   (setf cooked    (foreign-alloc '(:struct termios))
		 raw       (foreign-alloc '(:struct termios)))

	   (syscall (tcgetattr tty cooked))
	   (syscall (tcgetattr tty raw))
	   (with-foreign-slots ((c_lflag c_iflag c_oflag c_cc) raw
				(:struct termios))
	     (if timeout
		 ;; Read returns immediately only after one character read,
		 ;; or times out after TIMEOUT deciseconds.
		 (progn
		   (setf (mem-aref c_cc :unsigned-char +VMIN+) 0)
		   (setf (mem-aref c_cc :unsigned-char +VTIME+) timeout))
		 ;; Read returns immediately only after one character read
		 (progn
		   (setf (mem-aref c_cc :unsigned-char +VMIN+) 1)
		   (setf (mem-aref c_cc :unsigned-char +VTIME+) 0)))
	     ;; Turn off any input processing
	     (setf c_iflag (logand c_iflag
				   (lognot (logior +ISTRIP+ +INLCR+
						   +IGNCR+ +ICRNL+ +IXON+
						   +IXOFF+))))
	     ;; Turn off output processing
	     (when very-raw
	       (setf c_oflag (logand c_oflag (lognot (logior +OPOST+)))))
	     ;; Turn off canonical input and echo and signals
	     (if very-raw
		 (setf c_lflag (logand c_lflag
				       (lognot
					(logior +ICANON+ +ECHO+ +ISIG+))))
		 (setf c_lflag (logand c_lflag
				       (lognot (logior +ICANON+ +ECHO+)))))
	     ;; Actually set it
	     (syscall (tcsetattr tty +TCSANOW+ raw)))

	   ;; Do something
	   (setf result (funcall func tty)))
      (progn
	;; Clean up
	(when (and tty (>= tty 0) cooked)
	  (syscall (tcsetattr tty +TCSANOW+ cooked)))	; reset terminal modes
	(when cooked (foreign-free cooked))
	(when raw (foreign-free raw))))
;;    (format t "result = ~w~%" (map 'list #'identity result))
    result))

(defun raw-test (func &key debug very-raw timeout tty)
  "Test the termio package, by doing something with raw input.
FUNC is the thing to do with raw input. It's called with the POSIX file
descriptor as it's only argument. It sets up the file descriptor for raw
input, and cleans up afterwards. If DEBUG is true, print debugging details.
If VERY-RAW is true, set the terminal to the most raw state, which doesn't
even process interrupts. If TIMEOUT is true, it's a number of deciseconds,
 (by setting VTIME) to wait before returning nothing."
  (let (our-tty raw cooked raw-check result)
    (unwind-protect
	 (progn
	   ;; perhaps we should just use 0, aka /dev/stdin aka /dev/fd/0
	   (setf our-tty   (or tty (posix-open "/dev/tty" +O_RDWR+ 0))
                 cooked    (foreign-alloc '(:struct termios))
		 raw       (foreign-alloc '(:struct termios))
		 raw-check (foreign-alloc '(:struct termios)))
	   (format debug "our-tty = ~a~%" our-tty)
	   (when (< our-tty 0)
	     (error "Error opening /dev/tty ~d~%" our-tty))

	   (when (= -1 (tcgetattr our-tty cooked))
	     (error "Can't get cooked mode. errno = ~d" *errno*))
	   (format debug "cooked = ~x~%" cooked)
	   (when (= -1 (tcgetattr our-tty raw))
	     (error "Can't get raw mode. errno = ~d" *errno*))
	   (format debug "raw    = ~x~%" raw)
	   (with-foreign-slots ((c_lflag c_iflag c_oflag c_cc) raw
				(:struct termios))
	     (format debug "cooked c_lflag = ~x~%" c_lflag)
	     (if timeout
		 ;; Read returns immediately only after one character read,
		 ;; or times out after TIMEOUT deciseconds.
		 (progn
		   (setf (mem-aref c_cc :unsigned-char +VMIN+) 0)
		   (setf (mem-aref c_cc :unsigned-char +VTIME+) timeout))
		 ;; Read returns immediately only after one character read
		 (progn
		   (setf (mem-aref c_cc :unsigned-char +VMIN+) 1)
		   (setf (mem-aref c_cc :unsigned-char +VTIME+) 0)))
	     ;; Turn off any input processing
	     (setf c_iflag (logand c_iflag (lognot (logior
						    +ISTRIP+ +INLCR+ +IGNCR+
						    +ICRNL+ +IXON+ +IXOFF+))))
	     ;; Turn off output processing
	     (when very-raw
	       (setf c_oflag (logand c_oflag (lognot (logior +OPOST+)))))
	     ;; Turn off canonical input and echo and signals
	     (if very-raw
		 (setf c_lflag (logand c_lflag (lognot (logior +ICANON+ +ECHO+
							       +ISIG+))))
		 (setf c_lflag (logand c_lflag (lognot (logior +ICANON+ +ECHO+)))))
	     ;; Actually set it
	     (when (= -1 (tcsetattr our-tty +TCSANOW+ raw))
	       (error "Can't set raw mode. errno = ~d" *errno*)))

	   ;; Check that things were set right
	   (when (= -1 (tcgetattr our-tty raw-check))
	     (error "Can't get raw-check mode. errno = ~d" *errno*))

	   (with-foreign-slots ((c_lflag c_cc) raw-check (:struct termios))
	     (format debug "c_cc[~a] = ~a~%" +VMIN+
		     (mem-aref c_cc :unsigned-char +VMIN+))
	     (format debug "c_cc[~a] = ~a~%" +VTIME+
		     (mem-aref c_cc :unsigned-char +VTIME+))

	     (format debug "c_lflag = ~x~%" c_lflag)
	     (format debug "c_lflag = ~a ICANON  ~a ECHO~%"
		     (if (= 0 (logand c_lflag +ICANON+)) "NOT" "")
		     (if (= 0 (logand c_lflag +ECHO+))   "NOT" "")))

	   ;; Do something
	   (setf result (funcall func our-tty)))
      (progn
	;; Clean upp
	(when (and our-tty (>= our-tty 0) cooked)
	  (tcsetattr our-tty +TCSANOW+ cooked))	; reset terminal modes
	(when (and our-tty (>= our-tty 0) (not tty))
	  (posix-close our-tty))	; close the terminal if we opened it
	(when cooked (foreign-free cooked))
	(when raw (foreign-free raw))))
    result))

(defun terminal-test (&key (filename "termios.lisp") (debug nil))
  "This is pushcat."
  (raw-test #'(lambda (tty) (pushcat-file tty filename debug)) :debug debug))

(defun test-echo ()
  (raw-test #'(lambda (tty) (raw-echo tty)) :very-raw t))

(defun test-input ()
  (raw-test #'(lambda (tty) (input-test tty)) :very-raw t))

(defmacro with-raw-input (&body body)
  `(raw-test #'(lambda (tty) (declare (ignorable tty)) ,@body)))

(defmacro with-very-raw-input (&body body)
  `(raw-test #'(lambda (tty) (declare (ignorable tty)) ,body) :very-raw t))

#|
(defun terminal-query (query &key max tty)
  "Output the string to the terminal and wait for a response. Read up to MAX
characters. If we don't get anything after a while, just return what we got."
  (raw-test
   #'(lambda (tty)
       (with-foreign-string (q query)
	 (posix-write tty q (length query)))
       (let ((str (with-output-to-string (stream)
		    (if max
			(loop :with c
			   :for i :from 0 :below max
			   :while (setf c (getch tty))
			   :do (princ (code-char c) stream))
			(loop :with c
			   :while (setf c (getch tty))
			   :do (princ (code-char c) stream))))))
	 (make-array (length str) :initial-contents str)))
   :very-raw t
   :tty tty
   :timeout 1))
|#

;; This is just what I consider sane. You might not. You can change them if
;; you want to.
;;
;; This is output from "stty -g" on Darwin 9.8.0:
;; cflag=5b00:iflag=300:lflag=200005cf:oflag=7:discard=ff:dsusp=ff:eof=4:eol=ff:eol2=0:erase=7f:intr=3:kill=15:lnext=11:min=1:quit=1c:reprint=ff:start=ff:status=14:stop=ff:susp=1a:time=0:werase=ff:ispeed=38400:ospeed=38400
;;
;; Of course this has to be customized for every OS.
;; @@@ But we could make a default base POSIX one, which might not be perfect
;; but would hopefully do the job?

#+darwin (progn
(defparameter *sane-iflag*   #x300)	 ; ICRNL | IXON
(defparameter *sane-oflag*   #x7)	 ; OPOST | ONLCR | OXTABS
(defparameter *sane-cflag*   #x5b00)	 ; PARENB | HUPCL | CS6 | CS7 | CREAD
(defparameter *sane-lflag*   #x200005cf) ; ECHOKE | ECHOE | ECHOK | ECHO |
					 ; ECHOCTL | ISIG | ICANON | IEXTEN |
					 ; PENDIN
(declaim (type (unsigned-byte 8) *sane-discard*))
(defparameter *sane-discard* #xff)	 ; undef
(defparameter *sane-dsusp*   #xff)	 ; undef
(defparameter *sane-eof*     #x4)	 ; ^D
(defparameter *sane-eol*     #xff)	 ; undef
(defparameter +sane-eol2+    #x0)	 ; ^@
(defparameter *sane-erase*   #x7f)	 ; Delete
(defparameter *sane-intr*    #x3)	 ; ^C
(defparameter *sane-kill*    #x15)	 ; ^U
(defparameter *sane-lnext*   #x11)	 ; ^Q
(defparameter *sane-min*     #x1)	 ; ^A
(defparameter *sane-quit*    #x1c)	 ; ^\
(defparameter *sane-reprint* #xff)	 ; undef
(defparameter *sane-start*   #xff)	 ; undef
(defparameter *sane-status*  #x14)	 ; ^T
(defparameter *sane-stop*    #xff)	 ; undef
(defparameter *sane-susp*    #x1a)	 ; ^Z
(defparameter *sane-time*    #x0)	 ; ^@
(defparameter *sane-werase*  #xff)	 ; undef
(defparameter *sane-ispeed*  38400)
(defparameter *sane-ospeed*  38400)

(defparameter *sanity*
  `((,*sane-iflag* ,*sane-oflag* ,*sane-cflag* ,*sane-lflag*
     ,*sane-ispeed* ,*sane-ospeed*)
    #(,*sane-discard* ,*sane-dsusp* ,*sane-eof* ,*sane-eol* ,+sane-eol2+
      ,*sane-erase* ,*sane-intr* ,*sane-kill* ,*sane-lnext* ,*sane-min*
      ,*sane-quit* ,*sane-reprint* ,*sane-start* ,*sane-status* ,*sane-stop*
      ,*sane-susp* ,*sane-time* ,*sane-werase*)))
)

#+sunos (progn
; @@@ not verified, from ttywtf
;cflag 0xf01bf iflag 0x102 lflag 0x8a3b oflag 0x1805
(defparameter *sane-iflag*   #x00102)	;
(defparameter *sane-oflag*   #x01805)	;
(defparameter *sane-cflag*   #xf01bf)	;
(defparameter *sane-lflag*   #x08a3b) ;
(declaim (type (unsigned-byte 8) *sane-discard*))
(defparameter *sane-discard* #xff)	; undef
(defparameter *sane-dsusp*   #xff)	; undef
(defparameter *sane-eof*     #x4)	; ^D
(defparameter *sane-eol*     #xff)	; undef
(defparameter +sane-eol2+    #x0)	; ^@
(defparameter *sane-erase*   #x7f)	; Delete
(defparameter *sane-intr*    #x3)	; ^C
(defparameter *sane-kill*    #x15)	; ^U
(defparameter *sane-lnext*   #x11)	; ^Q
(defparameter *sane-min*     #x1)	; ^A
(defparameter *sane-quit*    #x1c)	; ^\
(defparameter *sane-reprint* #xff)	; undef
(defparameter *sane-start*   #xff)	; undef
(defparameter *sane-status*  #x14)	; ^T
(defparameter *sane-stop*    #xff)	; undef
(defparameter *sane-susp*    #x1a)	; ^Z
(defparameter *sane-time*    #x0)	; ^@
(defparameter *sane-werase*  #xff)	; undef
(defparameter *sane-ispeed*  38400)
(defparameter *sane-ospeed*  38400)

(defparameter *sanity*
  `((,*sane-iflag* ,*sane-oflag* ,*sane-cflag* ,*sane-lflag*
     ,*sane-ispeed* ,*sane-ospeed*)
    #(,*sane-discard* ,*sane-dsusp* ,*sane-eof* ,*sane-eol* ,+sane-eol2+
      ,*sane-erase* ,*sane-intr* ,*sane-kill* ,*sane-lnext* ,*sane-min*
      ,*sane-quit* ,*sane-reprint* ,*sane-start* ,*sane-status* ,*sane-stop*
      ,*sane-susp* ,*sane-time* ,*sane-werase*)))
)

#+linux (progn
; @@@ not verified, from ttywtf
;cflag 0xbf iflag 0x500 lflag 0x8a3b oflag 0x5
(defparameter *sane-iflag*   #x0500)	;
(defparameter *sane-oflag*   #x1805)	;
(defparameter *sane-cflag*   #x00b5)	; was #x0005
(defparameter *sane-lflag*   #x8a3b) ;
;cflag 0xb5 iflag 0x500 lflag 0x8a3b oflag 0x1805
(declaim (type (unsigned-byte 8) *sane-discard*))
(defparameter *sane-discard* #xff)	; undef
(defparameter *sane-dsusp*   #xff)	; undef
(defparameter *sane-eof*     #x4)	; ^D
(defparameter *sane-eol*     #xff)	; undef
(defparameter +sane-eol2+    #x0)	; ^@
(defparameter *sane-erase*   #x7f)	; Delete
(defparameter *sane-intr*    #x3)	; ^C
(defparameter *sane-kill*    #x15)	; ^U
(defparameter *sane-lnext*   #x11)	; ^Q
(defparameter *sane-min*     #x1)	; ^A
(defparameter *sane-quit*    #x1c)	; ^\
(defparameter *sane-reprint* #xff)	; undef
(defparameter *sane-start*   #xff)	; undef
(defparameter *sane-status*  #x14)	; ^T
(defparameter *sane-stop*    #xff)	; undef
(defparameter *sane-susp*    #x1a)	; ^Z
(defparameter *sane-time*    #x0)	; ^@
(defparameter *sane-werase*  #xff)	; undef
(defparameter *sane-ispeed*  38400)
(defparameter *sane-ospeed*  38400)

(defparameter *sanity*
  `((,*sane-iflag* ,*sane-oflag* ,*sane-cflag* ,*sane-lflag*
     ,*sane-ispeed* ,*sane-ospeed*)
    #(,*sane-discard* ,*sane-dsusp* ,*sane-eof* ,*sane-eol* ,+sane-eol2+
      ,*sane-erase* ,*sane-intr* ,*sane-kill* ,*sane-lnext* ,*sane-min*
      ,*sane-quit* ,*sane-reprint* ,*sane-start* ,*sane-status* ,*sane-stop*
      ,*sane-susp* ,*sane-time* ,*sane-werase*)))
)

#+freebsd (progn
(defparameter *sane-iflag*   #x300)	 ; ICRNL | IXON
(defparameter *sane-oflag*   #x7)	 ; OPOST | ONLCR | OXTABS
(defparameter *sane-cflag*   #x5b00)	 ; PARENB | HUPCL | CS6 | CS7 | CREAD
(defparameter *sane-lflag*   #x200005cf) ; ECHOKE | ECHOE | ECHOK | ECHO |
					 ; ECHOCTL | ISIG | ICANON | IEXTEN |
					 ; PENDIN
(declaim (type (unsigned-byte 8) *sane-discard*))
(defparameter *sane-discard* #xff)	 ; undef
(defparameter *sane-dsusp*   #xff)	 ; undef
(defparameter *sane-eof*     #x4)	 ; ^D
(defparameter *sane-eol*     #xff)	 ; undef
(defparameter +sane-eol2+    #x0)	 ; ^@
(defparameter *sane-erase*   #x7f)	 ; Delete
(defparameter *sane-intr*    #x3)	 ; ^C
(defparameter *sane-kill*    #x15)	 ; ^U
(defparameter *sane-lnext*   #x11)	 ; ^Q
(defparameter *sane-min*     #x1)	 ; ^A
(defparameter *sane-quit*    #x1c)	 ; ^\
(defparameter *sane-reprint* #xff)	 ; undef
(defparameter *sane-start*   #xff)	 ; undef
(defparameter *sane-status*  #x14)	 ; ^T
(defparameter *sane-stop*    #xff)	 ; undef
(defparameter *sane-susp*    #x1a)	 ; ^Z
(defparameter *sane-time*    #x0)	 ; ^@
(defparameter *sane-werase*  #xff)	 ; undef
(defparameter *sane-ispeed*  38400)
(defparameter *sane-ospeed*  38400)

(defparameter *sanity*
  `((,*sane-iflag* ,*sane-oflag* ,*sane-cflag* ,*sane-lflag*
     ,*sane-ispeed* ,*sane-ospeed*)
    #(,*sane-discard* ,*sane-dsusp* ,*sane-eof* ,*sane-eol* ,+sane-eol2+
      ,*sane-erase* ,*sane-intr* ,*sane-kill* ,*sane-lnext* ,*sane-min*
      ,*sane-quit* ,*sane-reprint* ,*sane-start* ,*sane-status* ,*sane-stop*
      ,*sane-susp* ,*sane-time* ,*sane-werase*)))
)

#+openbsd (progn
(defparameter *sane-iflag*   #x2b02)	 ; BRKINT | ICRNL | IMAXBEL | IXON | IXANY
(defparameter *sane-oflag*   #x7)	 ; OPOST | ONLCR | OXTABS
(defparameter *sane-cflag*   #x4b00)	 ; CREAD | CS8 | HUPCL
(defparameter *sane-lflag*   #x5cf)	 ; ECHOKE | ECHOE | ECHOK | ECHO |
					 ; ECHOCTL | ISIG | ICANON | IEXTEN
(declaim (type (unsigned-byte 8) *sane-discard*))
(defparameter *sane-discard* #xff)	 ; undef
(defparameter *sane-dsusp*   #xff)	 ; undef
(defparameter *sane-eof*     #x4)	 ; ^D
(defparameter *sane-eol*     #xff)	 ; undef
(defparameter +sane-eol2+    #x0)	 ; ^@
(defparameter *sane-erase*   #x7f)	 ; Delete
(defparameter *sane-intr*    #x3)	 ; ^C
(defparameter *sane-kill*    #x15)	 ; ^U
(defparameter *sane-lnext*   #x11)	 ; ^Q
(defparameter *sane-min*     #x1)	 ; ^A
(defparameter *sane-quit*    #x1c)	 ; ^\
(defparameter *sane-reprint* #xff)	 ; undef
(defparameter *sane-start*   #xff)	 ; undef
(defparameter *sane-status*  #x14)	 ; ^T
(defparameter *sane-stop*    #xff)	 ; undef
(defparameter *sane-susp*    #x1a)	 ; ^Z
(defparameter *sane-time*    #x0)	 ; ^@
(defparameter *sane-werase*  #xff)	 ; undef
(defparameter *sane-ispeed*  38400)
(defparameter *sane-ospeed*  38400)

(defparameter *sanity*
  `((,*sane-iflag* ,*sane-oflag* ,*sane-cflag* ,*sane-lflag*
     ,*sane-ispeed* ,*sane-ospeed*)
    #(,*sane-discard* ,*sane-dsusp* ,*sane-eof* ,*sane-eol* ,+sane-eol2+
      ,*sane-erase* ,*sane-intr* ,*sane-kill* ,*sane-lnext* ,*sane-min*
      ,*sane-quit* ,*sane-reprint* ,*sane-start* ,*sane-status* ,*sane-stop*
      ,*sane-susp* ,*sane-time* ,*sane-werase*)))
)

(defun sane (&key (device "/dev/tty") file-descriptor)
  "Reset standard input to sane modes."
  (when (not (boundp '*sanity*))
    (error "Sanity undefined."))
  (let (tty sane)
    (unwind-protect
      (progn
	(setf tty (or file-descriptor (posix-open device +O_RDWR+ 0))
	      sane (foreign-alloc '(:struct termios)))
	(when (< tty 0)
	  (error "Error opening ~a ~d~%" device tty))

	(with-foreign-slots ((c_iflag c_oflag c_cflag c_lflag c_cc
			      c_ispeed c_ospeed)
			     sane (:struct termios))
	  (setf c_iflag *sane-iflag*)
	  (setf c_oflag *sane-oflag*)
	  (setf c_cflag *sane-cflag*)
	  (setf c_lflag *sane-lflag*)
	  (setf (mem-aref c_cc :unsigned-char +VDISCARD+) *sane-discard*)
#-linux	  (setf (mem-aref c_cc :unsigned-char +VDSUSP+)   *sane-dsusp*)
	  (setf (mem-aref c_cc :unsigned-char +VEOF+)     *sane-eof*)
	  (setf (mem-aref c_cc :unsigned-char +VEOL+)     *sane-eol*)
	  (setf (mem-aref c_cc :unsigned-char +VEOL2+)    +sane-eol2+)
	  (setf (mem-aref c_cc :unsigned-char +VERASE+)   *sane-erase*)
	  (setf (mem-aref c_cc :unsigned-char +VINTR+)    *sane-intr*)
	  (setf (mem-aref c_cc :unsigned-char +VKILL+)    *sane-kill*)
	  (setf (mem-aref c_cc :unsigned-char +VLNEXT+)   *sane-lnext*)
	  (setf (mem-aref c_cc :unsigned-char +VMIN+)     *sane-min*)
	  (setf (mem-aref c_cc :unsigned-char +VQUIT+)    *sane-quit*)
	  (setf (mem-aref c_cc :unsigned-char +VREPRINT+) *sane-reprint*)
	  (setf (mem-aref c_cc :unsigned-char +VSTART+)   *sane-start*)
#+darwin  (setf (mem-aref c_cc :unsigned-char +VSTATUS+)  *sane-status*)
	  (setf (mem-aref c_cc :unsigned-char +VSTOP+)    *sane-stop*)
	  (setf (mem-aref c_cc :unsigned-char +VSUSP+)    *sane-susp*)
	  (setf (mem-aref c_cc :unsigned-char +VTIME+)    *sane-time*)
	  (setf (mem-aref c_cc :unsigned-char +VWERASE+)  *sane-werase*)
	  (setf c_ispeed *sane-ispeed*)
	  (setf c_ospeed *sane-ospeed*)

	  (when (= -1 (tcsetattr tty +TCSANOW+ sane))
	    (error "Can't set sane mode. errno = ~d" *errno*))))
      ;; close the terminal
      (when (and tty (>= tty 0) (not file-descriptor))
	(posix-close tty))
      ;; free C memory
      (when sane (foreign-free sane)))))

(defun reset-terminal-modes (&key file-descriptor (device "/dev/tty"))
  (sane :file-descriptor file-descriptor
	:device (or device "/dev/tty")))

(defparameter *control-chars*
  `((:end-of-file      . ,+VEOF+)
    (:end-of-line      . ,+VEOL+)
    (:end-of-line-2    . ,+VEOL2+)
    (:erase            . ,+VERASE+)
    (:word-erase       . ,+VWERASE+)
    (:kill-line        . ,+VKILL+)
    (:reprint          . ,+VREPRINT+)
    (:erase2           . ,+VERASE2+)
    (:interrupt        . ,+VINTR+)
    (:quit             . ,+VQUIT+)
    (:suspend          . ,+VSUSP+)
    (:delayed-suspend  . ,+VDSUSP+)
    (:switch           . ,+VSWTCH+)
    (:start            . ,+VSTART+)
    (:stop             . ,+VSTOP+)
    (:literal-next     . ,+VLNEXT+)
    (:discard          . ,+VDISCARD+)
    (:minimum          . ,+VMIN+)
    (:time             . ,+VTIME+)
    (:status           . ,+VSTATUS+)))

(defun control-char (tty name)
  "Return the control character named NAME, or NIL if it's undefined."
  (let ((char (assoc name *control-chars*)))
    (if char
	(setf char (cdr char))
	(error 'opsys-error
	       :format-control "Unknown control character ~s"
	       :format-arguments name))
    (when (not char)
      (error 'opsys-error
	     :format-control "Control character ~s is undefined on this system."
	     :format-arguments name))
    (with-foreign-object (mode '(:struct termios))
      (with-foreign-slots ((c_cc) mode (:struct termios))
	(syscall (tcgetattr tty mode))
	(code-char (mem-aref c_cc :char char))))))

(defun set-control-char (tty name character)
  "Set the control character NAME to CHARACTER."
  (let ((char (assoc name *control-chars*))
	(code (if character (char-code character) 0)))
    (if char
	(setf char (cdr char))
	(error 'opsys-error
	       :format-control "Unknown control character ~s."
	       :format-arguments name))
    (when (not char)
      (error 'opsys-error
	     :format-control "Control character ~s is undefined on this system."
	     :format-arguments name))
    (when (> code #xff)
      (error 'opsys-error
	     :format-control "The character must be 8 bits, not ~s."
	     :format-arguments code))
    (with-foreign-object (mode '(:struct termios))
      (syscall (tcgetattr tty mode))
      (with-foreign-slots ((c_cc) mode (:struct termios))
	(setf (mem-aref c_cc :char char) code)
	;; (syscall (tcsetattr tty +TCSANOW+ mode))
	(syscall (tcsetattr tty +TCSADRAIN+ mode))
	))
    character))

(defsetf control-char set-control-char)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The portable interface:

(defun file-handle-terminal-p (fd)
  "Return true if the system file descriptor FD is attached to a terminal."
  (= (isatty fd) 1))

(defun file-handle-terminal-name (fd)
  "Return the device name of the terminal attached to the system file
descriptor FD."
;;;  (let ((ttn (ttyname fd)))
;;;  (and (not (null-pointer-p ttn)) ttn)))
  ;; @@@ XXX We should probably use ttyname_r
  (ttyname fd))

(defvar *default-console-device-name* "/dev/tty"
  "Name of the default console device.")

(defun open-terminal (device-name direction)
  "Open a terminal. Return the system file handle."
  (ecase direction
    (:output
     (open device-name
	   :direction :output
	   #-(or clisp abcl) :if-exists
	   #-(or clisp abcl) :append
	   #+sbcl :external-format
	   #+sbcl '(:utf-8 :replacement #\replacement_character)
	   #+ccl :external-format
	   #+ccl '(:character-encoding :utf-8 :line-termination :default)
	   ))
    (:input
     (syscall (posix-open device-name +O_RDWR+ 0)))))

(defun close-terminal (terminal-handle)
  "Close a terminal."
  (cond
    ((streamp terminal-handle)
     (close terminal-handle))
    ((integerp terminal-handle)
     (syscall (posix-close terminal-handle)))
    (t
     (error "Unrecognized type of terminal handle."))))

(defmacro with-terminal-signals (() &body body)
  "Evaluate the BODY with signal handlers set appropriately for reading from
a terminal."
  `(with-signal-handlers ((+SIGWINCH+ . sigwinch-handler)
			  (+SIGTSTP+  . tstp-handler))
     ,@body))

;; I'm not really sure if this is a good interface. ☹
(defun set-terminal-mode (tty &key
				(echo    nil echo-supplied)
				(line    nil line-supplied)
				(raw     nil raw-supplied)
				(timeout nil timeout-supplied)
				(mode    nil mode-supplied))
  "Set the terminal mode. Arguments are:
  ECHO makes input automatically output back, so you can see what you typed.
  LINE makes input wait for a newline until returning.
  RAW ignores normal processing, like interrupt keys.
  TIMEOUT is the time in deciseconds to wait before returning with no input.
  MODE is a TERMINAL-MODE structure to take settings from.
The individual settings override the settings in MODE."
  (when (not (or echo-supplied line-supplied raw-supplied timeout-supplied
		 mode-supplied))
    (return-from set-terminal-mode))
  (let (new-mode)
    (unwind-protect
      (progn
	(setf new-mode (foreign-alloc '(:struct termios)))
	(syscall (tcgetattr tty new-mode))
	(with-foreign-slots ((c_lflag c_iflag c_oflag c_cc) new-mode
			     (:struct termios))
	  (labels
	      ((char-mode (state)
		 (if state
		     (progn
		       ;; We assume with character mode you want relatively
		       ;; raw characters.
		       (setf c_iflag
			     (logand c_iflag
				     (lognot (logior +ISTRIP+ +INLCR+
						     +IGNCR+ +ICRNL+ +IXON+
						     +IXOFF+))))
		       ;; Turn off "cannonical" input.
		       ;; Stuck in input modes of the ancients?
		       ;; We are the new canon!
		       (setf c_lflag
			     (logand c_lflag
				     (lognot (logior +ICANON+ +IEXTEN+))))
		       ;; Do we really need these?
		       (setf c_oflag
			     (logior c_oflag +ONLCR+ +OPOST+))
		       ;; These are the default values, but we set them since
		       ;; otherwise a read might not immediately return a
		       ;; char.
		       (setf (mem-aref c_cc :char +VMIN+) 1)
		       (setf (mem-aref c_cc :char +VTIME+) 0))
		     (progn
		       (setf c_iflag (logior c_iflag +ICRNL+ #| +IXON+ |#))
		       (setf c_oflag (logior c_oflag +ONLCR+ +OPOST+))
		       (setf c_lflag (logior c_lflag +ICANON+ +IEXTEN+)))))
	       (echo-mode (state)
		 (setf c_lflag
		       (if state
			   (logior c_lflag +ECHO+)
			   (logand c_lflag (lognot +ECHO+)))))
	       (raw-mode (state)
		 ;; Raw means the same as character mode AND don't process
		 ;; signals or do output processing.
		 (if state
		     (progn
		       (setf c_lflag (logand c_lflag (lognot +ISIG+)))
		       (setf c_oflag (logand c_oflag (lognot +OPOST+))))
		     (progn
		       (setf c_lflag (logior c_lflag +ISIG+))
		       (setf c_oflag (logior c_oflag +OPOST+)))))
	       (set-timeout (timeout)
		 (if timeout
		     (progn
		       (char-mode t) ;; char mode must be on
		       (setf (mem-aref c_cc :char +VMIN+) 0)
		       (setf (mem-aref c_cc :char +VTIME+) timeout))
		     (progn
		       (setf (mem-aref c_cc :char +VMIN+) 1)
		       (setf (mem-aref c_cc :char +VTIME+) 0)))))
	    (when mode-supplied
	      ;; Order is important here.
	      (echo-mode (terminal-mode-echo mode))
	      (char-mode (not (terminal-mode-line mode)))
	      (raw-mode (terminal-mode-raw mode))
	      (set-timeout (terminal-mode-timeout mode)))
	    ;; Order is important here, too.
	    (when echo-supplied (echo-mode echo))
	    (when line-supplied (char-mode (not line)))
	    (when raw-supplied (raw-mode raw))
	    (when timeout-supplied (set-timeout timeout))))
	;; Now actually set it.
	;; (when (< (tcsetattr tty +TCSANOW+ new-mode) 0)
	(when (< (tcsetattr tty +TCSADRAIN+ new-mode) 0)
	  (error "Can't set terminal mode. ~d ~d" *errno* tty)))
      (foreign-free new-mode))))

(defun get-terminal-mode (tty)
  "Return a TERMINAL-MODE structure with the current terminal settings."
  (let ((new-mode (foreign-alloc '(:struct termios)))
	(echo nil) (line nil) (raw nil) (timeout nil))
    (syscall (tcgetattr tty new-mode))
    (with-foreign-slots ((c_lflag c_iflag c_oflag c_cc) new-mode
			 (:struct termios))
      ;; Don't check in detail, just assume the full setting.
      (setf echo (not (zerop (logand c_lflag +ECHO+)))
	    line (not (zerop (logand c_lflag +ICANON+)))
	    raw  (and (zerop (logand c_lflag +ISIG+))
		      (zerop (logand c_lflag +ICANON+)))
	    timeout (if (zerop (mem-aref c_cc :char +VMIN+))
			(mem-aref c_cc :char +VTIME+)
			nil)))
    (make-terminal-mode :echo echo :line line :raw raw :timeout timeout)))

;; @@@ !!! Figure out how we can use this here and also in OPSYS
(defmacro with-BOGO-terminal-mode ((tty) &body body)
  "Evaluate the body, retoring terminal mode changes on exit."
  (with-unique-names (mode)
    `(let ((,mode (get-terminal-mode ,tty)))
       (unwind-protect
	    (progn ,@body)
	 (set-terminal-mode ,tty :mode ,mode)))))

(defun get-window-size (tty-fd)
  "Get the window size. First value is columns, second value is rows."
  (with-foreign-object (ws '(:struct winsize))
    (when (< (posix-ioctl tty-fd +TIOCGWINSZ+ ws) 0)
      (error "Can't get the tty window size."))
    (values
     (foreign-slot-value ws '(:struct winsize) 'ws_col)
     (foreign-slot-value ws '(:struct winsize) 'ws_row))))

(defun slurp-terminal (tty &key timeout)
  "Read until EOF. Return a string of the results. TTY is a file descriptor."
  (let* ((size (memory-page-size))
	 (result (make-array size
			     :element-type 'base-char
			     :fill-pointer 0 :adjustable t))
	 status)
    (with-BOGO-terminal-mode (tty)
      (when timeout
	(set-terminal-mode tty :timeout timeout))
      (with-output-to-string (str result)
	(with-foreign-object (buf :char size)
	  (loop
	     :do (setf status (posix-read tty buf size))
	     :while (= status size)
	     :do (princ (cffi:foreign-string-to-lisp buf) str))
	  (cond
	    ((> status size)
	     (error "Read returned too many characters? ~a" status))
	    ((< status 0)
	     (error "slurp-terminal Read error ~d errno ~d~%" status *errno*))
	    ((= status 0)
	     (or (and (length result) result) nil))
	    (t
	     (princ (cffi:foreign-string-to-lisp buf :count status) str)
	     result)))))))

(define-condition read-char-error (posix-error)
  ()
  (:report (lambda (c s)
	     (format s "Error reading a character: ~a"
			 (symbol-call :opsys :error-message
				      (opsys-error-code c)))))
  (:documentation "An error reading a character."))

(define-condition read-string-error (posix-error)
  ()
  (:report (lambda (c s)
	     (format s "Error reading a string: ~a"
			 (symbol-call :opsys :error-message
				      (opsys-error-code c)))))
  (:documentation "An error reading a string."))

(defun read-raw-char (terminal-handle c &optional test)
  (let (status)
    (loop
       :do
       (setf status (posix-read terminal-handle c 1))
       :while (or (and (< status 0)
		       (or (= *errno* +EINTR+) (= *errno* +EAGAIN+)))
		  (and test
		       (funcall test (mem-ref c :unsigned-char))))
       :do
       ;; Probably returning from ^Z or terminal resize, or something,
       ;; so keep trying. Enjoy your trip to plusering town.
       (cond
	 (*got-sigwinch*
	  (setf *got-sigwinch* nil)
	  (cerror "Try again?" 'opsys-resized))
	 (*got-tstp*
	  (when (not (eq *got-tstp* :dont-suspend))
	    (setf *got-tstp* nil)
	    ;; re-signal with the default, so we actually stop
	    (with-signal-handlers ((+SIGTSTP+ . :default))
	      (kill (getpid) +SIGTSTP+))
	    (cerror "Try again?" 'opsys-resumed))
	  (setf *got-tstp* nil))
	 (t
	  (when (< status 0)
	    (cerror "Try again?" 'read-char-error :error-code *errno*)))))
    status))

#|
(defun read-raw-string (terminal-handle string length)
  (let (status)
    (loop
       :do
       (setf status (posix-read terminal-handle string length))
       :while (and (< status 0)
		   (or (= *errno* +EINTR+) (= *errno* +EAGAIN+)))
       :do
       ;; Probably returning from ^Z or terminal resize, or something,
       ;; so keep trying. Enjoy your trip to plusering town.
       (cond
	 (*got-sigwinch*
	  (setf *got-sigwinch* nil)
	  (cerror "Try again?" 'opsys-resized))
	 (*got-tstp*
	  (setf *got-tstp* nil)
	  ;; re-signal with the default, so we actually stop
	  (with-signal-handlers ((+SIGTSTP+ . :default))
	    (kill (getpid) +SIGTSTP+))
	  (cerror "Try again?" 'opsys-resumed))
	 (t
	  (when (< status 0)
	    (cerror "Try again?" 'read-string-error :error-code *errno*)))))
    status))
|#

;; Simple, linear, non-event loop based programming was always an illusion!
(defun read-terminal-byte (terminal-handle &key timeout)
  (with-BOGO-terminal-mode (terminal-handle)
    (when timeout
      (set-terminal-mode terminal-handle :timeout timeout))
    (with-foreign-object (c :char)
      (flet ((read-it ()
	       (when (not (zerop (read-raw-char terminal-handle c)))
		 (mem-ref c :unsigned-char))))
	;; If a ^Z handler is active, don't overrride it.
	(if (not (member (signal-action +SIGTSTP+) '(:default :ignore)))
	    (with-signal-handlers ((+SIGWINCH+ . sigwinch-handler))
	      (read-it))
	    (with-signal-handlers ((+SIGWINCH+ . sigwinch-handler)
				   (+SIGTSTP+  . tstp-handler))
	      (read-it)))))))

(defun read-terminal-char (terminal-handle &key timeout)
  (code-char (read-terminal-byte terminal-handle :timeout timeout)))

#|
;; @@@ I would use stretchy, but I don't want to introduce dependencies.
(defun append-thing (array thing)
  "Append the THING to the array ARRAY."
  (let ((len (length array)))
    (when (>= (1+ len) (array-total-size array))
      (setf array (adjust-array
		   array (+ (array-total-size array) 1
			    (truncate (* (array-total-size array) 2/3))))))
    (incf (fill-pointer array))
    (setf (aref array len) thing)))

(defun old-read-until (tty stop-token &key timeout octets-p)
  "Read until STOP-TOKEN is read. Return a string of the results.
TTY is a file descriptor. TIMEOUT is in seconds."
  (let ((result (make-array 0 :element-type (if octets-p
						'(unsigned-byte 8)
						'character)
			    :fill-pointer 0 :adjustable t))
	(status nil) (got-eof nil)
	test-and-put-func)
    (labels ((test-and-put-char (c)
	       (let ((cc (code-char c)))
		 (and cc (char/= cc stop-token)
		      (append-thing result cc))))
	     (test-and-put-byte (c)
	       (let ((cc (code-char c)))
		 (and cc (char/= cc stop-token)
		      (append-thing result c)))))
      (setf test-and-put-func (if octets-p
				  #'test-and-put-byte
				  #'test-and-put-char))
      (with-BOGO-terminal-mode (tty)
        ;; (when (and timeout
	;; 	   (not (eql (truncate timeout 10)
	;; 		     (terminal-mode-timeout (get-terminal-mode tty)))))
	;;   ;; (format t "set timeout = ~s~%" timeout)
	;;   ;; (set-terminal-mode tty :timeout (truncate timeout 10)))
	(set-terminal-mode tty :echo nil :line nil :raw nil :timeout 0)
	(with-foreign-object (c :char)
	  (with-signal-handlers ((+SIGWINCH+ . sigwinch-handler)
				 (+SIGTSTP+  . tstp-handler))
	    (when timeout
	      (listen-for timeout tty))
	    (setf status (read-raw-char tty c test-and-put-func))
	    (when (zerop status)
	      (setf got-eof t)))))
      ;; (dbugf :ruru "ruru -> ~s ~s~%" (type-of result)
      ;;  	     (map 'list
      ;; 		  ;; (_ (symbol-call :char-util :displayable-char _))
      ;; 		  (_ (typecase _
      ;; 		       (character (char-code _))
      ;; 		       (number _)))
      ;; 		  result))
      (values
       (if (zerop (length result))
	   nil
	   result)
       got-eof))))
|#

(defparameter *read-until-buffer-size* 12
  "The default buffer size for read-until.")

(defparameter *time-quanta* 0.0002 ;; 0.0001
  "How long to sleep in seconds when input isn't available.")
(declaim (type single-float *delay-time*))

(defparameter *error-max* 4
  "The number of times we can get an error before giving up.")
(declaim (type fixnum *error-max*))

(defun full-response-p (buf len char)
  "Return true if we seem to have gotten a full response because there's a
CHAR."
  (loop :with c = (char-code char)
     :for i :from 0 :below len
     :when (= (cffi:mem-aref buf :unsigned-char i) c)
     :return t))

;; @@@ This should be improved to be less consing, probably use with-output-to-*
(defun convert-result (result count octets-p &optional partial)
  "Convert the result of ‘read-until’ into a string or an octet vector depending
on ‘octets-p’."
  (if octets-p
      (let* ((start (if partial (length partial) 0))
	     (a (make-array (+ count start) :element-type '(unsigned-byte 8))))
	;; We really don't want to hit the partial cases, since they're slow.
	;; If an ample buffer can't be supplied to read-until, consider
	;; using another technique.
	(if partial
	    (progn
	      (setf (subseq a 0 start) partial)
	      (loop :for i :from 0 :below count
		 :do (setf (aref a (+ start i))
			   (cffi:mem-aref result :unsigned-char i))))
	    (loop :for i :from 0 :below count
	       :do (setf (aref a i) (cffi:mem-aref result :unsigned-char i))))
	a)
      (if partial
	  (s+ partial (cffi:foreign-string-to-lisp result :count count))
	  (cffi:foreign-string-to-lisp result :count count))))

(defun done-check (string end-tag)
  "Return true if END-TAG is in STRING. END-TAG can be a string or a character."
  (and (etypecase end-tag
	 (character
	  (position end-tag string :from-end t))
	 ((or vector string)
	  (search end-tag string :from-end t))
	 (function
	  (funcall end-tag string)))
       t))

(defun read-until (fd end-tag &key (timeout 4) octets-p
				(buffer-size *read-until-buffer-size*))
  ;; (dbugf :fux "timeout ~s buffer-size ~s~%" timeout buffer-size)
  (when (not buffer-size)
    (setf buffer-size *read-until-buffer-size*))
  (cffi:with-foreign-object (buf :unsigned-char buffer-size)
    (prog ((fail-count 0)
	   (error-count 0)
	   (status 0)
	   (fail-max (/ (or timeout 4) *time-quanta*))
	   (real-end-tag
	    (if octets-p
		(make-array (length end-tag)
			    :element-type '(unsigned-byte 8)
			    :initial-contents
			    (map 'list #'char-code end-tag))
		end-tag))
	   partial)
       (declare (type fixnum status))
     AGAIN
       (setf status (posix-read fd buf buffer-size))
       ;; (dbugf :fux "status ~s *errno* ~s~%" status *errno*)
       (cond
	 ;; Got something
	 ((plusp status)
	  (setf partial (convert-result buf status octets-p partial))
	  (if (done-check partial real-end-tag)
	      (return partial)
	      (go AGAIN)))
	 ;; Nothing availabile
	 ((= status 0)
	  (when (> fail-count fail-max)
	    (cerror "Try again?" "Reapeatedly got nothing.")
	    (setf fail-count 0))
	  (incf fail-count)
	  ;; Try waiting, and going again, until the fail limit.
	  (sleep *time-quanta*)
	  (go AGAIN))
	 ;; Got an error.
	 ((< status 0)
	  (cond
	    ((> error-count *error-max*)
	     ;; (cerror "Try again?" ':read-char-error
	     ;; 	     :error-code *errno*))
	     (cerror "Try again?"
		     "read-until got too many errors. ~s" error-count))
	    ((> fail-count fail-max)
	     ;; (cerror "Try again?" 'read-char-error
	     ;; 	     :error-code *errno*))
	     (cerror "Try again?"
		     "read-until took too long. ~s" fail-count))
	    ((or (= *errno* +EWOULDBLOCK+))
	     ;; Nothing there yet.
	     (incf fail-count)
	     (sleep *time-quanta*)
	     (go AGAIN))
	    ((or (= *errno* +EINTR+) (= *errno* +EAGAIN+))
	     ;; If it's just normal plusering, go again.
	     (incf error-count)
	     (go AGAIN))
	    (t
	     ;; It's maybe a for real error.
	     (cerror "Try again?"
		     'read-char-error :error-code *errno*))))))))

(defmacro with-nonblocking-io ((fd) &body body)
  (with-unique-names (flags reset-it)
    `(let ((,flags 0) ,reset-it)
       (declare (type fixnum ,flags))
       ;; Get the file descriptor flags.
       (setf ,flags (syscall (fcntl ,fd +F_GETFL+)))
       (unwind-protect
	    (progn
	      ;; Set it to non-blocking.
	      (when (not (plusp (logand ,flags +O_NONBLOCK+)))
		(setf ,reset-it t)
		(syscall (fcntl ,fd +F_SETFL+ :int
				(logior ,flags +O_NONBLOCK+))))
	      ;; Do something with fd.
	      ,@body)
	 ;; Set the flags back to the original.
	 (when ,reset-it
	   (syscall (fcntl ,fd +F_SETFL+ :int ,flags)))))))

(defun terminal-query (fd query end-tag &key buffer-size)
  (let ((query-length (length query)))
    (cffi:with-foreign-string (buf query)
      (syscall (tcflush fd +TCIFLUSH+))
      ;; Send the query to the terminal.
      (syscall (posix-write fd buf query-length))
      (with-nonblocking-io (fd)
	;; Do the complicated read.
	(read-until fd end-tag :buffer-size buffer-size)))))

(defun write-terminal-char (terminal-handle char)
  "Write CHAR to the terminal designated by TERMINAL-HANDLE."
  (with-foreign-string ((s size) (string char))
    (syscall (posix-write terminal-handle s size))))

(defun write-terminal-string (terminal-handle string)
  "Write STRING to the terminal designated by TERMINAL-HANDLE."
  (with-foreign-string ((s size) string)
    (syscall (posix-write terminal-handle s size))))

(defun crap (&optional (device "/dev/tty"))
  "An horrible test."
  (let (tty)
    (unwind-protect
      (progn
	(setf tty (posix-open device +O_RDWR+ 0))
	(when (< tty 0)
	  (error "Error opening ~a ~d~%" device tty))

	(format t "No echo: ") (finish-output)
	(set-terminal-mode tty :echo nil)
	(format t "read: ~s~%" (read-line))

	(format t "Yes echo: ") (finish-output)
	(set-terminal-mode tty :echo t)
	(format t "read: ~s~%" (read-line))

	(format t "One char: ") (finish-output)
	(set-terminal-mode tty :line nil)
	(format t "read: ~s~%" (read-char))

	(format t "Whole line: ") (finish-output)
	(set-terminal-mode tty :line t)
	(format t "read: ~s~%" (read-line))

	(format t "Raw char: ") (finish-output)
	(set-terminal-mode tty :raw t)
	(format t "read: ~s~%" (read-char))

	(format t "Non-raw line: ") (finish-output)
	(set-terminal-mode tty :raw nil)
	(format t "read: ~s~%" (read-line))

	(format t "Time out (2 sec): ") (finish-output)
	(set-terminal-mode tty :timeout 20)
	(format t "read: ~s~%" (getch tty))

	(format t "No time out: ") (finish-output)
	(set-terminal-mode tty :timeout nil)
	(format t "read: ~s~%" (code-char (getch tty)))
	(set-terminal-mode tty :line t)
	)
      ;; close the terminal
      (when (and tty (>= tty 0))
	(posix-close tty)))))

;; End
