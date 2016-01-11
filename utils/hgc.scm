#!/usr/bin/guile \
-L ../modules -e main -s
!#

;;; hgc.scm -- Herd Guile Compiler

;; Copyright (C) 2016 Artyom V. Poptsov <poptsov.artyom@gmail.com>
;;
;; This file is a part of Guile-Herd.
;;
;; Guile-Herd is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Guile-Herd is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Guile-Herd.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:


;;; Code:

(use-modules (ice-9 getopt-long)
             (ice-9 rdelim)
             (srfi srfi-26)
             (scripts frisk)
             (ssh auth)
             (ssh session)
             (ssh sftp)
             (herd io)
             (herd compiler))

(define %default-host "localhost")


;;;

(define (establish-ssh-session host)
  "Establish a new SSH session with a HOST and return the session."
  (let ((session (make-session #:host host)))
    (connect! session)
    (authenticate-server session)
    (userauth-agent! session)
    session))

;;;

(define (get-dependency-list file)
  (let ((frisker (make-frisker)))
    ((frisker (list file)) 'x-down)))


;;;


(define (print-help-and-exit)
  (display (string-append "\
Usage: gdc [options] file1 file2 ...

Options:
  -h, --help            Print this message and exit.
  -L, --load-path=DIR   Add DIR to the front of the module load path.
  -T, --target=TRIPLET  Produce bytecode for host TRIPLET.
                        Default: " %host-type "
"))
  (exit))


(define (main args)
  "Entry point."
  (let* ((option-spec  '((help           (single-char #\h) (value #f))
                         (load-path      (single-char #\L) (value #t))
                         (target         (single-char #\T) (value #t))))
         (options      (getopt-long args option-spec))
         (help-needed? (option-ref options 'help #f))
         (load-path    (option-ref options 'load-path (getcwd)))
         (target       (option-ref options 'target %host-type))
         (files        (option-ref options '()   #f)))

    (and help-needed?
         (print-help-and-exit))

    (format #t "target: ~a~%" target)

    (let* ((session      (establish-ssh-session %default-host))
           (sftp-session (make-sftp-session session))
           (tmpdir       (remote-mktemp session)))
      (format #t "tmpdir: '~a'~%" tmpdir)

      (let* ((remote-files
              (map (cut push sftp-session <> tmpdir)
                   files))
             (zzz (format #t "remote files: ~a~%" remote-files))
             (compiled-files
              (map (lambda (remote-file)
                     (format #t "remote file: '~a'~%" remote-file)
                     (let ((compiled-file (remote-compile session
                                                          remote-file
                                                          #:target target)))
                       (format #t "compiled file: '~a'~%" compiled-file)
                       compiled-file))
                   remote-files)))
        (format #t "remote files: ~a~%" remote-files)
        (for-each (lambda (compiled-file)
                    (pull sftp-session compiled-file
                          (basename compiled-file))
                    (format #t "wrote: '~a'~%"
                            (string-append (getcwd) "/"
                                           (basename compiled-file))))
                  compiled-files)))))

;;; hgc.scm ends here.
