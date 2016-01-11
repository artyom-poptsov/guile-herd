;;; compiler.scm -- Herd Guile Compiler procedures.

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

(define-module (herd compiler)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 rdelim)
  #:use-module (ssh popen)
  #:export (remote-compile remote-guild-compile))

(define* (remote-guild-compile session file
                               #:key target load-path)
  (open-remote-input-pipe* session
                           "guild compile"
                           (string-append "--load-path=" (dirname file))
                           (string-append "--target=" target)
                           (string-append "--output=" file ".go")
                           file))

(define %pattern (make-regexp "wrote `(.*)'"))

(define* (remote-compile session file #:key target)
  (let ((pipe (remote-guild-compile session file
                                    #:target target
                                    #:load-path (dirname file))))
    (let r ((line   (read-line pipe))
            (output ""))
          (let ((m (regexp-exec %pattern line)))
            (cond
             ((eof-object? line)
              (display "REMOTE COMPILATION ERROR:\n")
              (display (string-append output line))
              (error "Could not compile a file" session file))
             ((regexp-match? m)
              (match:substring m 1))
             (else
              (r (read-line pipe)
                 (string-append output line))))))))

;;; compiler.scm ends here.
