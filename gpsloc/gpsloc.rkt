#lang racket
(require racket/bytes)
(require racket/string)

(require db)
(require libserialport)

(require "lib/location.rkt")

(module+ test (require rackunit))

(define DB
  (make-parameter (let ([path (getenv "DB")])
                    (cond
                      [(not path) "./locations.sqlite"]
                      [else path]))))

(define COMMAND
  (make-parameter (let ([command (getenv "COMMAND")])
                    (cond
                      [(not command) 'loc]
                      [else (string->symbol command)]))))
(define TTY
  (make-parameter (let ([dev (getenv "TTY")])
                    (cond
                      [(not dev) "dev/ttyUSB0"]
                      [else dev]))))

(define DB_SCHEMA "CREATE TABLE IF NOT EXISTS locations (lat REAL, lon REAL, alt REAL, datetime TEXT)")
(define DB_INSERT_LOC "INSERT INTO locations VALUES ($1, $2, $3, datetime('now'))")

(define COMMANDS (hash 'poweron #"AT+CGNSPWR=1"
                      'poweroff #"AT+CGNSPWR=0"
                      'loc #"AT+CGNSINF"
                      'time #"AT+CCLK?"
                      'timesyncstatus #"AT+CLTS?"
                      'powerstatus #"AT+CGNSPWR?"
                      'gpsfixstatus #"AT+CGPSSTATUS?"))

(define RESULTS (hash 'loc "+CGNSINF: "
                      'error "ERROR\r"
                      'ok "OK\r"))

(define (send-command command port)
  (let* ([bytes (bytes-append* (hash-ref COMMANDS command) '(#"\n"))]
         [void (displayln (format "sending bytes ~s" bytes))]
         [bytes-sent (write-bytes bytes port)])
    (displayln (format "~a bytes sent" bytes-sent))))

(define (receive in)
  (let loop ()
    (let ([result (read-line in)])
      (displayln (format "received ~s" result))
      (cond [(equal? result (hash-ref RESULTS 'ok)) (displayln "done")]
            [(equal? result (hash-ref RESULTS 'error)) (displayln "oups!")]
            [(eof-object? result) (displayln "oups!")]
            [(string-prefix? result (hash-ref RESULTS 'loc))
             (and (store-location (decode-location result)) (loop))]
            [else (and (sleep 1) (loop))]))))

(define (decode-location locstr)
  (displayln (format "decoding location ~s." locstr))
  (apply location (string-split
                   (string-trim locstr (hash-ref RESULTS 'loc)) ",")))

(define (store-location loc)
  (displayln (format "storing location into ~s" (DB)))
  (let ([db (sqlite3-connect #:database (DB) #:mode 'create)])
    (query-exec db DB_SCHEMA)
    (query-exec db DB_INSERT_LOC
                (location-latitude loc)
                (location-longitude loc)
                (location-altitude loc))))

(define (main)
  (define s-ports (serial-ports))
  (unless (set-member? s-ports (TTY))
    (error (format "~s is not a valid serial port ~s" (TTY) s-ports)))

  (unless (sync/timeout 5
                        (thread (lambda ()
                                  (displayln "dialing... ")
                                  (define-values (in out) (open-serial-port (TTY) #:baudrate 115200))
                                  (send-command (COMMAND) out)
                                  (receive in))))
    (error (format "could not dial with ~s" (TTY)))))


(module* main #f
    (parse-command-line "gpsloc" (current-command-line-arguments)
                        `((once-each
                           [("-c" "--command") ,(lambda (f c) (COMMAND (string->symbol c)))
                                               ("command" "loc,poweron,poweroff")]
                           [("-d" "--db") ,(lambda (f c) (DB c))
                                          ("database path" "path")]
                           [("-t" "--tty") ,(lambda (f c) (TTY c))
                                           ("tty" "/dev/ttyUSB0")]))
                        (lambda (flags . args) (main))
                        '()))
