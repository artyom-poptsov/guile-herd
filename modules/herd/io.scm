;;; io.scm -- I/O procedures.

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

(define-module (herd io)
  #:use-module (ice-9 rdelim)
  #:use-module (rnrs io ports)
  #:use-module (ssh sftp)
  #:use-module (ssh popen)
  #:export (push pull cat rcat remote-mktemp))


(define (->stdout)
  "Read all input data and print it to stdout."
  (let r ((octet (get-u8 (current-input-port))))
    (unless (eof-object? octet)
      (put-u8 (current-output-port) octet)
      (r (get-u8 (current-input-port))))))

(define (cat file)
  "Print a FILE to stdout."
  (with-input-from-file file ->stdout))

(define (rcat sftp-session remote-file)
  "Print a REMOTE-FILE to stdout."
  (with-input-from-remote-file sftp-session remote-file ->stdout))

(define (remote-mktemp session)
  (let ((p (open-remote-input-pipe* session
                                    "mktemp"
                                    "--directory"
                                    "--tmpdir=/tmp"
                                    "tmp.hgc.XXXXXXXXXX")))
    (read-delimited "\r" p 'trim)))

(define (local-file->remote-file dir filename)
  (string-append dir "/" (basename filename)))


(define (push sftp-session file dir)
  "Push a FILE to a remote host for compilation, return name of remote
file."
  (let ((remote-file (local-file->remote-file dir file)))
    (with-output-to-remote-file sftp-session remote-file
      (lambda () (cat file)))
    remote-file))

(define (pull sftp-session file local-file)
  (with-output-to-file local-file
    (lambda ()
      (rcat sftp-session file))))

;;; io.scm ends here.
