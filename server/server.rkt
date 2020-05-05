#lang racket

(require web-server/servlet
         web-server/servlet-env
         web-server/http
         racket/system
         uuid)

(define (produce-result req)
  (define source (extract-binding/single 'source (request-bindings req)))

  (define uuid-base (uuid-string))
  (define tmp-source-file (build-path "/opt/associate/" (string-append uuid-base ".poly.pm")))
  (define out (open-output-file tmp-source-file))
  (write-string source out)
  (close-output-port out)
  
  (parameterize ([current-directory "/opt/associate"])
    (system (string-append "raco pollen render " uuid-base ".html") #:set-pwd? #t))

  (response/full 200
                 #"OK"
                 (current-seconds)
                 TEXT/HTML-MIME-TYPE
                 null
                 (list (port->bytes (open-input-file (string-append "/opt/associate/" uuid-base ".html")) #:close? #t))))

(define (start req)
  (define method (bytes->string/utf-8 (request-method req)))
  (cond
    [(equal? method "GET") (response/xexpr
                            `(html (head (meta ((charset "UTF-8")))
                                         (meta ((name "viewport") (content "width=device-width, initial-scale=1.0")))
                                         (title "Citations Demo (pollen-citations-mcgill)")
                                         (link ((rel "stylesheet") (href "site-style.css"))))
                                   (body (p "This is a demo of " (a ((href "https://github.com/sanchom/pollen-citations-mcgill")) "pollen-citations-mcgill")
                                            ", through its use in " (a ((href "https://github.com/sanchom/associate")) "associate") ", an article authoring engine. This demo will render your source "
                                            "text into a webpage. The full system can create Word documents and PDFs. " (b "Once you click submit/envoyer, please be patient. It might take up to 10 seconds."))
                                         (form ((method "POST"))
                                               (textarea ((name "source") (id "source") (rows "20") (cols "80"))
                                                         "#lang pollen\n\n"
                                                         "◊define-meta[title]{Example article}\n"
                                                         "◊define-meta[doc-type]{article}\n\n"
                                                         "◊declare-work[#:id \"Guignard\" #:type \"legal-case\" #:title \"R v "
                                                         "Guignard\" #:citation \"2002 SCC 14\" #:short-form \"*Guignard*\"]\n\n"
                                                         "◊declare-work[#:id \"Benecke\" #:type \"article\" #:author \"Olivia "
                                                         "Benecke\" #:author2-given \"Sarah Elizabeth\" #:author2-family \"DeYoung\" "
                                                         "#:title \"Anti-Vaccine Decision-Making and Measles Resurgence in the "
                                                         "United States\" #:journal \"Glob Pediatr Health\" #:year \"2019\" #:volume "
                                                         "\"6\" #:first-page \"1\"]\n\n"


                                                         
                                                         "Here is a sentence that cites Guignard.◊note-cite[\"Guignard\"]\n\n"
                                                         "Here is a sentence that cites something else.◊note-see[\"Benecke\"]\n\n"
                                                         "Citing Guignard again, with a pinpoint.◊note-cite[\"Guignard\" #:pinpoint \"para 5\"]\n\n"
                                                         )
                                               (br)
                                               (input ((type "submit")))))))]
    [(equal? method "POST") (produce-result req)]
    [else (response/xexpr
           `(html (head (title "Racket Heroku App"))
                  (body (h1 "Method not supported."))))]))

(define port (if (getenv "PORT")
                 (string->number (getenv "PORT"))
                 8080))

(serve/servlet start
               #:servlet-path "/"
               #:extra-files-paths `(,(build-path "/opt/static-files"))
               #:listen-ip #f
               #:port port
               #:command-line? #t)
