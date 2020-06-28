#lang racket

(require racket/date)
(require racket/string)
(require racket/logging)
(require gregor)

(require "lib/location.rkt")
(require "lib/gpsdialer.rkt")

(define commands (list gpsdialer/command-spec))
(define help-commands (map (lambda (c) (dict-ref c 'cmd)) commands))

(define verbose (make-parameter (cond
                                [(equal? "1" (getenv "GPSLOC_VERBOSE")) #t]
                                [else #f])))

(define (log-level) (if (verbose) 'debug 'info))

(define (print-log-msg! level msg)
  (eprintf "~a ~a ~a\n" (moment->iso8601 (with-timezone (now) (current-timezone))) (string-upcase (symbol->string level)) msg))

(define (call fn args)
  (let ([res
         (with-handlers ([exn:fail? (λ (exn)
                                      (print-log-msg! 'error (exn-message exn))
                                      )])
           (with-intercepted-logging
             (lambda (l) (print-log-msg! (vector-ref l 0) (vector-ref l 1)))
             (lambda () (fn args))
             (log-level)))])
    (if res
        (exit 0)
        (exit 1))))

(module* main #f
    (parse-command-line "gpsloc" (current-command-line-arguments)
                        `((once-each
                           [("-v" "--verbose") ,(lambda (f) (verbose #t))
                                               ("verbose mode")]
                           [("-d" "--db") ,(lambda (f c) (location/DB c))
                                          ("database path" "path")]
                           [("-t" "--tty") ,(lambda (f c) (gpsdialer/TTY c))
                                           ("tty" "/dev/ttyUSB0")]))
                        (lambda (flags . args) (cond
                                                 [(empty? args) (eprintf "missing command argument\n")]
                                                 [else (let ([cmd (findf (lambda (c) (equal? (first args) (dict-ref c 'cmd))) commands)])
                                                         (cond
                                                           [cmd (call (dict-ref cmd 'fn) (rest args))]
                                                           [else (eprintf "invalid command ~s\n" (first args))]))]))
                        help-commands))
