(module gpsdialer racket
  (provide (rename-out [dial gpsdialer/dial]))
  (provide (rename-out [TTY gpsdialer/TTY]))
  (provide (rename-out [command-spec gpsdialer/command-spec]))

  (require racket/bytes)
  (require racket/string)
  (require libserialport)
  (require "location.rkt")

  (module+ test (require rackunit))

  (define TTY
    (make-parameter (let ([dev (getenv "TTY")])
                      (cond
                        [(not dev) "/dev/ttyUSB0"]
                        [else dev]))))

  (define COMMANDS (hash 'on #"AT+CGNSPWR=1"
                         'off #"AT+CGNSPWR=0"
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
           [void (log-debug (format "sending bytes ~s" bytes))]
           [bytes-sent (write-bytes bytes port)])
      (log-debug (format "~a bytes sent" bytes-sent))))

  (define (receive in)
    (let loop ()
      (let ([result (read-line in)])
        (log-debug (format "received ~s" result))
        (cond [(equal? result (hash-ref RESULTS 'ok)) (log-info "done")]
              [(equal? result (hash-ref RESULTS 'error)) (log-error "oups!")]
              [(eof-object? result) (log-error "oups!")]
              [(string-prefix? result (hash-ref RESULTS 'loc))
               (and (location/store (decode-location result)) (loop))]
              [else (and (sleep 1) (loop))]))))

  (define (decode-location locstr)
    (log-debug (format "decoding location ~s." locstr))
    (apply location (string-split
                     (string-trim locstr (hash-ref RESULTS 'loc)) ",")))

  (define (dial command)
    (define s-ports (serial-ports))
    (unless (set-member? s-ports (TTY))
      (error (format "~s is not a valid serial port ~s" (TTY) s-ports)))

    (unless (sync/timeout 5
                          (thread (lambda ()
                                    (log-info "dialing... ")
                                    (define-values (in out) (open-serial-port (TTY) #:baudrate 115200))
                                    (send-command command out)
                                    (receive in))))
      (error (format "could not dial with ~s" (TTY)))))

  (define (command args)
    (parse-command-line "gpsloc dial" args `()
                        (lambda (flag-accum action . args) (dial (string->symbol action)))
                        '("on|off|loc")))

  (define command-spec (hash 'cmd "dial" 'fn command 'desc "dial on/off/loc")))
