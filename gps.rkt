#lang racket
(require libserialport)
(require racket/bytes)
(require racket/string)
(require db)


(define DB
  (make-parameter (let ([path (getenv "DB")])
                    (cond
                      [(not path) "./locations.sqlite"]
                      [else path]))))

(define ACTION
  (make-parameter (let ([action (getenv "ACTION")])
                    (cond
                      [(not action) 'loc]
                      [else (string->symbol action)]))))
(define TTY
  (make-parameter (let ([dev (getenv "TTY")])
                    (cond
                      [(not dev) "dev/ttyUSB0"]
                      [else dev]))))

(define DB_SCHEMA "CREATE TABLE IF NOT EXISTS locations (lat REAL, lon REAL, alt REAL, datetime TEXT)")
(define DB_INSERT_LOC "insert into locations values ($1, $2, $3, datetime('now'))")

(define ACTIONS (hash 'poweron #"AT+CGNSPWR=1"
                      'poweroff #"AT+CGNSPWR=0"
                      'loc #"AT+CGNSINF"
                      'time #"AT+CCLK?"
                      'timesyncstatus #"AT+CLTS?"
                      'powerstatus #"AT+CGNSPWR?"
                      'gpsfixstatus #"AT+CGPSSTATUS?"))


(define RESULTS (hash 'loc "+CGNSINF: "
                      'error "ERROR\r"
                      'ok "OK\r"))

(struct location (GNSSrunstatus
                  Fixstatus
                  UTCdatetime
                  latitude
                  longitude
                  altitude
                  speedOTG
                  course
                  fixmode
                  Reserved1
                  HDOP
                  PDOP
                  VDOP
                  Reserverd2
                  GNSSsatellitesinview
                  GNSSsatellitesused
                  GLONASSsatellitesused
                  Reserved3
                  cn0max
                  HPA
                  VPA))


(define (send-action action port)
  (let* ([bytes (bytes-append* (hash-ref ACTIONS action) '(#"\n"))]
         [void (displayln (format "sending bytes ~s" bytes))]
         [bytes-sent (write-bytes bytes port)])
    (displayln (format "~a bytes sent" bytes-sent))))

(define (decode-location locstr)
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

(define-values (in out) (open-serial-port (TTY) #:baudrate 115200))
(displayln "dialing... ")
(send-action (ACTION) out)
(let loop ()
  (let ((result (read-line in)))
    (displayln (format "received ~s" result))
    (cond [(equal? (hash-ref RESULTS 'ok) result) (displayln "done")]
          [(equal? (hash-ref RESULTS 'error) result) (displayln "oups!")]
          [(string-prefix? result (hash-ref RESULTS 'loc))
           (and (store-location (decode-location result)) (loop))]
          [else (and (sleep 1) (loop))])))
