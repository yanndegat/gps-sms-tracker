(module location racket
  (provide (struct-out location))

  (module+ test (require rackunit))

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
                  VPA)
  #:guard (λ (GNSSrunstatus
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
              VPA
              name)
            (unless (and (real? (string->number latitude))
                         (real? (string->number longitude))
                         (real? (string->number altitude)))
              (error "not a valid location"))
            (values GNSSrunstatus
                    Fixstatus
                    UTCdatetime
                    (string->number latitude)
                    (string->number longitude)
                    (string->number altitude)
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
                    VPA)))

(module+ test
  (check-exn exn:fail? (lambda () (location "GNSSrunstatus"
                                            "Fixstatus"
                                            "UTCdatetime"
                                            "" ;; empty latitude
                                            "" ;; empty longitude
                                            "" ;; empty altitude
                                            "speedOTG"
                                            "course"
                                            "fixmode"
                                            "Reserved1"
                                            "HDOP"
                                            "PDOP"
                                            "VDOP"
                                            "Reserverd2"
                                            "GNSSsatellitesinview"
                                            "GNSSsatellitesused"
                                            "GLONASSsatellitesused"
                                            "Reserved3"
                                            "cn0max"
                                            "HPA"
                                            "VPA")))

  (check-exn exn:fail? (lambda () (location "GNSSrunstatus"
                                            "Fixstatus"
                                            "UTCdatetime"
                                            "lat" ;; wrong latitude
                                            "lon" ;; wrong longitude
                                            "alt" ;; wrong altitude
                                            "speedOTG"
                                            "course"
                                            "fixmode"
                                            "Reserved1"
                                            "HDOP"
                                            "PDOP"
                                            "VDOP"
                                            "Reserverd2"
                                            "GNSSsatellitesinview"
                                            "GNSSsatellitesused"
                                            "GLONASSsatellitesused"
                                            "Reserved3"
                                            "cn0max"
                                            "HPA"
                                            "VPA")))

  (check-not-exn (lambda () (location "GNSSrunstatus"
                                      "Fixstatus"
                                      "UTCdatetime"
                                      "0" ;; ok latitude
                                      "0" ;; ok longitude
                                      "0" ;; ok altitude
                                      "speedOTG"
                                      "course"
                                      "fixmode"
                                      "Reserved1"
                                      "HDOP"
                                      "PDOP"
                                      "VDOP"
                                      "Reserverd2"
                                      "GNSSsatellitesinview"
                                      "GNSSsatellitesused"
                                      "GLONASSsatellitesused"
                                      "Reserved3"
                                      "cn0max"
                                      "HPA"
                                      "VPA")))))
