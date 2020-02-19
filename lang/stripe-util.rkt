#lang racket

(provide set-stripe-key!
         TEST
         LIVE
         
         set-product-name
         city->stripe
         course->stripe
         camp->stripe
         courses->stripe
         camps->stripe
         
         stripe-get-status
         stripe-get-data

         ;get-response-status
         ;get-response-data
         
         show-products
         show-skus
         delete-sku
         delete-product

         generate-random-sku
         generate-random-product-id
         )

(require stripe-integration
         metacoders-dot-org-lib
         uuid
         net/base64
         binaryio/integer)

(define TEST "/.stripe-test-api-key")
(define LIVE "/.stripe-api-key")

(define stripe-key TEST)

(define (set-stripe-key! k)
  (set! stripe-key k)
  (set-stripe-secret-key!) 
  )

(define (set-stripe-secret-key!)  
  (define stripe-key-path (~a
                           (path->string (find-system-path 'home-dir))
                           stripe-key))

  (define stripe-key-data (if (file-exists? stripe-key-path)
                              (string-trim
                               (file->string stripe-key-path))
                              ""))

  (stripe-secret-key (if (string=? stripe-key "")
                         (raise "ERROR: NO STRIPE API KEY")
                         stripe-key-data)))

(define (set-product-name prod-id name)
  (stripe-post (~a "/v1/products/" prod-id)
               (hash 'name name)))

(define (course->image-url c)
  (define grade-range (string-replace (course-grade-range c) " " ""))
  (cond [(string=? grade-range "K-2nd")    (~a "https://metacoders.org" (prefix/pathify stripe-k-2-course-img-path))]
        [(string=? grade-range "3rd-6th")  (~a "https://metacoders.org" (prefix/pathify stripe-3-6-course-img-path))]
        [(string=? grade-range "7th-10th") (~a "https://metacoders.org" (prefix/pathify stripe-7-10-course-img-path))]
        [else                         (~a "https://metacoders.org" (prefix/pathify stripe-3-6-course-img-path))]))

(define (camp->image-url c)
  (define grade-range (string-trim (string-replace (camp-grade-range c) " " "") "Entering"))
  (cond [(string=? grade-range "K-2nd")    (~a "https://metacoders.org" (prefix/pathify stripe-k-2-camp-img-path))]
        [(string=? grade-range "3rd-6th")  (~a "https://metacoders.org" (prefix/pathify stripe-3-6-camp-img-path))]
        [(string=? grade-range "7th-10th") (~a "https://metacoders.org" (prefix/pathify stripe-7-10-camp-img-path))]
        [else                         (~a "https://metacoders.org" (prefix/pathify stripe-3-6-camp-img-path))]))

(define (course->sku-name c)
  ; === SINGLE-LINE FORMATTING ===
  (~a (if (> (course-discount c) 0)
          (~a "Discounted from $" (course-price c) "/student! ")
          "")
      (course-location c) " - "
      (course-topic c) " (" (course-grade-range c) ") -  "
      (meeting-date->weekday (first (course-meeting-dates c)))"s from "
      (course-start-time c) "-" (course-end-time c) " - "
      "Dates: " (apply (curry ~a #:separator ", ") (course-meeting-dates c))))

(define-syntax-rule (get-response-status response)
  (let-values ([(status headers json ik) response])
    status))

(define (stripe-get-status url) (get-response-status (stripe-get url)))

(define-syntax-rule (get-response-data response)
    (let-values ([(status headers json ik) response])
    json))

(define (stripe-get-data url) (get-response-data (stripe-get url)))

;if it exists, update it, and if not, create it
(define (city->stripe prod-id city-name)
  (define name (~a "Coding Classes in " city-name))
  (if (eq? (stripe-get-status (~a "/v1/products/" prod-id)) 404)
      (get-response-data
       (stripe-post (~a "/v1/products")
                    (hash 'id prod-id
                          'name name
                          (string->symbol "attributes[]") "name"
                          'type "good")))
      (get-response-data
       (stripe-post (~a "/v1/products/" prod-id)
                    (hash 'name name)))))

(define (camp->sku-name c)
  (define lunch-time (camp-lunch-time c))
  (define lunch-or-blank (if (string=? lunch-time "")
                             ""
                             " (includes lunch)"))
  ; === SINGLE-LINE FORMATTING ===
  (~a (if (> (camp-discount c) 0)
          (~a "Discounted from $" (camp-price c) "/student! ")
          "")
      (camp-location c) " - "
      (camp-topic c) " (" (camp-grade-range c) ") -  "
      "Daily from "
      (camp-camp-time c) lunch-or-blank " - "
      "Dates: " (apply (curry ~a #:separator ", ") (camp-meeting-dates c))))

;if it exists, update it, and if not, create it
(define (course->stripe prod-id c)
  (define c-sku (course-sku c))
  (if (eq? (stripe-get-status (~a "/v1/skus/" c-sku)) 404)
      (get-response-data
       (stripe-post (~a "/v1/skus")
                    (hash (string->symbol "attributes[name]") (course->sku-name c)
                          'id c-sku
                          'image (course->image-url c) ;"https://metacoders.org/img/home/child-coding-in-weekly-class-camp.jpg"
                          'price (~a (exact-round (* 100 (- (course-price c) (course-discount c)))))
                          'currency "usd"
                          (string->symbol "inventory[type]") "infinite"
                          'product prod-id
                          )
                    ))
      (get-response-data
       (stripe-post (~a "/v1/skus/" c-sku)
                    (hash (string->symbol "attributes[name]")
                          (course->sku-name c)
                          'image (course->image-url c) ;"https://metacoders.org/img/weekly-classes.jpg"
                          'price (~a (exact-round (* 100 (- (course-price c) (course-discount c)))))
                          'product prod-id ;this will link the existing sku to a new product
                          )
                    ))))

;if it exists, update it, and if not, create it
(define (camp->stripe prod-id c)
  (define c-sku (camp-sku c))
  (if (eq? (stripe-get-status (~a "/v1/skus/" c-sku)) 404)
      (get-response-data
       (stripe-post (~a "/v1/skus")
                    (hash (string->symbol "attributes[name]") (camp->sku-name c)
                          'id c-sku
                          'image (camp->image-url c) ;"https://metacoders.org/img/home/child-coding-in-weekly-class-camp.jpg"
                          'price (~a (exact-round (* 100 (- (camp-price c) (camp-discount c)))))
                          'currency "usd"
                          (string->symbol "inventory[type]") "infinite"
                          'product prod-id
                          )
                    ))
      (get-response-data
       (stripe-post (~a "/v1/skus/" c-sku)
                    (hash (string->symbol "attributes[name]")
                          (camp->sku-name c)
                          'image (camp->image-url c) ;"https://metacoders.org/img/weekly-classes.jpg"
                          'price (~a (exact-round (* 100 (- (camp-price c) (camp-discount c)))))
                          'product prod-id ;this will link the existing sku to a new product
                          )
                    ))))

(define (courses->stripe prod-id . courses)
  (map (curry course->stripe prod-id) courses))

(define (camps->stripe prod-id . camps)
  (map (curry camp->stripe prod-id) camps))

; this only works if all linked skus are deleted first
(define (delete-product prod-id)
  (stripe-delete (~a "/v1/products/" prod-id)))

(define (delete-sku sku)
  (stripe-delete (~a "/v1/skus/" sku)))

(define (format-date d)
    (~a (date-month d) "/" (date-day d) "/" (date-year d)
      " " (date-hour d) ":" (date-minute d) ":" (date-second d)))

(define (show-products)
  (displayln (~a (~a "NAME"           #:width 40 #:limit-marker "...") "| "
                 (~a "PRODUCT ID"     #:width 20 #:limit-marker "...") "| "
                 (~a "LAST UPDATED " #:width 20 #:limit-marker "...") "\n"
                 (~a #:width 84 #:pad-string "-") "\n"
                 (apply ~a (map (λ(p) (~a (~a (hash-ref p 'name)    #:width 40 #:limit-marker "...") "| "
                                          (~a (hash-ref p 'id)      #:width 20 #:limit-marker "...") "| "
                                          (~a (format-date (seconds->date (hash-ref p 'updated))) #:width 20 #:limit-marker "...") "\n"))
                                (hash-ref (stripe-get-data "/v1/products?limit=100") 'data))))))

(define (show-skus [product-id #f])
  (displayln (~a (~a "NAME"       #:width 40 #:limit-marker "...") "| "
                 (~a "PRICE"      #:width 8 #:limit-marker "...") "| "
                 (~a "SKU ID"     #:width 28 #:limit-marker "...") "| "
                 (~a "PRODUCT ID"     #:width 20 #:limit-marker "...") "| "
                 (~a "LAST UPDATED " #:width 20 #:limit-marker "...") "\n"
                 (~a #:width 124 #:pad-string "-") "\n"
                 (apply ~a (map (λ(p) (~a (~a (hash-ref (hash-ref p 'attributes) 'name) #:width 40 #:limit-marker "...") "| "
                                           (~a "$" (~r (/ (hash-ref p 'price) 100) #:precision '(= 2))  #:width 8 #:limit-marker "...") "| "
                                           (~a (hash-ref p 'id)      #:width 28 #:limit-marker "...") "| "
                                           (~a (hash-ref p 'product)      #:width 20 #:limit-marker "...") "| "
                                           (~a (format-date (seconds->date (hash-ref p 'updated))) #:width 20 #:limit-marker "...") "\n"))
                                 (filter (if product-id
                                             (λ(s) (string=? (hash-ref s 'product) product-id))
                                             identity)
                                         (hash-ref (stripe-get-data "/v1/skus?limit=100") 'data)))))))

(define (uuid->base64 str)
  (bytes->string/utf-8 (base64-encode (integer->bytes (string->number (~a "#x" (string-replace str "-" "")))
                                                    16 #f) "")))

(define (base64->uuid str)
  (number->string (bytes->integer (base64-decode (string->bytes/utf-8 str)) #f) 16))

(define (generate-random-sku)
  (~a "sku_" ((compose (curryr string-replace "=" "")
                       (curryr string-replace "/" "")
                       (curryr string-replace "+" "")) (uuid->base64 (uuid-string)))))

(define (generate-random-product-id)
  (~a "prod_" ((compose (curryr string-replace "=" "")
                       (curryr string-replace "/" "")
                       (curryr string-replace "+" "")) (uuid->base64 (uuid-string)))))
