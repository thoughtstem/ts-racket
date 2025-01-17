#lang scribble/manual

@(require scribble/eval
          2htdp/image)

@(define helper-eval (make-base-eval))
@interaction-eval[#:eval helper-eval
                  (require "../main.rkt"
                           2htdp/image)]

@title{TS-Racket}

@section{General}

@defproc[(save [resource resource?])
         resource?]

Stores the resource on the database (either dev or production,
depending on the @racket[set-env!]

Example:

@racketblock[
             (save (new-meeting #:course 1000
                                #:start (string->time "2018-09-10 3:30pm")
                                #:duration 60))
 ]

@defproc[(set-env! [k dev-or-prod?])
         void?]

Takes either DEV or PROD. Default is DEV.

REMINDER!! Only set to PROD after sufficient testing in DEV.

@defproc[(host-image! [x (or/c image? string?)])
         string?]

Takes either an image or a string of a path to a saved file and uploads that file to S3. Returns the link to
the file.

@section{Flyers}

How to use ts-racket to automate flyer generation from a course ID.

@defproc[(course->flyer [course flyer-ready-course?]
                        [selling-points (listof string?) (selling-points course)]
                        [registration-link string? "https://secure.thoughtstem.com"])
         image?]

Builds a flyer out of one course. 

NOTE: alternative spelling of flyer (flier) in this function also works.

@racketblock[(course->flyer (course 1137))]

@bitmap["resources/flyer.png"]

Alternatively, you can define the individual images on a flyer like this:

@racketblock[(course->flyer (course 1206)
                            #:bg (make-flier-bg
                                  (bitmap "resources/template-image.jpg")
                                  (bitmap "resources/template-image.jpg")
                                  (bitmap "resources/template-image.jpg")))]


@defproc[(courses->flyer [course flyer-ready-course?]
                         [course2 flyer-ready-course?]
                         [selling-points (listof string?) (selling-points course)]
                         [selling-points2 (listof string?) (selling-points course2)]
                         [registration-link string? "https://secure.thoughtstem.com"])
         image?]

Builds a flyer out of 2 courses (to be used for two courses at one location).

NOTE: alternative spelling of flyer (flier) in this function also works.


@racketblock[(courses->flyer (course 1137) (course 1128))]

@bitmap["resources/2panel-flyer.png"]

Alternatively, you can define the titles for 2-panel fliers like this:

@racketblock[(courses->flyer
              #:first-title "Superhero Digital Animation"
              #:second-title "Code Survival Games"
              (course 1258) (course 1259))]

@section{Students}

@defproc[(badges [course course?]) (listof image?)]

Produces a list of student badges for all students enrolled in a course.

@examples[
     #:eval helper-eval
     (badges (course 1208))
   ]}

@;racketblock[(badges (course 1208))]

@;bitmap["resources/badge-list.png"]

@defproc[(build-badge [student student?]
                      [course-id number?]
                      [name (string?) (first-name student)])
         image?]

Produces a single badge. Good to use if you want to change the name
on single badge to a nickname for example.

@examples[
     #:eval helper-eval
     (build-badge (student 1753) 1205)
     (build-badge (student 1753) 1208 "Triceratops")
   ]}

@;racketblock[(build-badge (student 1753) 1205)]

@;bitmap["resources/badge1.png"]

@;racketblock[(build-badge (student 1753) 1208 "Triceratops")]

@;bitmap["resources/badge2.png"]

@defproc[(print-badges! [courses course?] ...)
         boolean?]

Creates and prints badges for all listed courses 3 by 3.

WARNING -- currently only works for Macs. Sorry. :(

@section{Courses}

@defproc[(course [id number?])
         course?]

Returns a course in the form of hash. 

@defproc[(set-room-id [resource (or/c meeting? course?)]
                      [room-id number?])
         (or/c meeting? course?)]

Using this function, you can set the room id for either a singular
meeting or all the meetings in a course.

Reminder!! This does not update information in the environment. You must call
@racket[save] or @racket[save-meetings!] to make changes permanently to the
environment.

@defproc[(save-meetings! [course course?])
         course?]

Calls @racket[save] on all meetings in a course.


@defproc[(make-course-with-meetings! [name string?]
                                     [description string?]
                                     [location-id number?]
                                     [price    positive?]
                                     [duration positive?]
                                     [foreign-enrollment-site string?]
                                     [screenshot-url string?]
                                     [meeting-time moment?] ...)
         course?]

Creates a course with the supplied info.

You can pass in as many meeting times as you want.  Meeting times
are Gregor moments.  See the Gregor docs for more info on moments.

@racketblock[
  (make-course-with-meetings! "Coding and Robotics"
                              coding-and-engineering-description
                              sycamore-ridge
                              330
                              60
                              "https://www.someotherschoolsite.org/Page/30492291103"
                              coding-and-engineering-screenshot

                              (string->time "2018-10-11 2:35pm")
                              (string->time "2018-10-18 2:35pm")
                              (string->time "2018-10-25 2:35pm")
                              )
 ]

@defproc[(make-course-with-meetings-from-bundle! [bundle (listof string?)]
                                                 [location-id number?]
                                                 [price    positive?]
                                                 [duration positive?]
                                                 [foreign-enrollment-site string?]
                                                 [screenshot-url string?]
                                                 [meeting-time moment?] ...)
         course?]

Creates a course with the supplied info.

You can pass in as many meeting times as you want.  Meeting times
are Gregor moments.  See the Gregor docs for more info on moments.

@racketblock[
 (make-course-with-meetings-from-bundle! (code-your-game-bundle-spring "Doyle Elementary")
                                         doyle
                                         160
                                         60
                                         ""
 
                                         (date-strings->dates "2:05pm"
                                                              "12/8/2019, 12/15/2019, 12/22/2019, 12/29/2019, 1/6/2020, 1/13/2020, 1/20/2020")
                                         )


 ]

@section{Constants for use in course creation}

A list of constants defined to be used in course creation. Last updated 9/7/2018

@larger{locations}

@racketblock[
  albert-einstein
  ocean-air
  ashley-falls
  sage-canyon
  sycamore-ridge
  torrey-hills
  carmel-del-mar
  del-mar-hills
  kumeyaay
  liberal-arts
  jerabek
  JCS
  deer-canyon
  language-academy
 ]

@larger{descriptions}

@racketblock[
  python-racket-description
  robotics-course-description
  code-your-game-decription
  digital-comics-description
  game-design-and-robotics-description
  coding-and-engineering-description
 ]

@larger{screenshots}

@racketblock[
 code-your-game-screenshot
 digital-comics-screenshot
 game-design-and-robotics-screenshot
 ]

@larger{selling points}

@racketblock[
 k-2nd-selling-points
 3rd-5th-selling-points
 k-2nd-del-mar-selling-points
 3rd-5th-del-mar-selling-points
 
 ]













@section{image-util}

@defproc[(buffer [n number?]
                 [i image?])
         image?]

Adds a transparent "buffer" around an image to assist with spacing and/or printing.
First argument is the size in pixels fo the buffer.

@examples[
     #:eval helper-eval
     ;no buffer
     (beside
      (square 30 'solid 'green)
      (square 30 'solid 'blue))

     ;with buffer
     (beside
      (buffer 5 (square 30 'solid 'green))
      (buffer 5 (square 30 'solid 'blue)))]

@defproc[(scale-to-fit [image image?]
                       [width number?])
         image?]

Scales an image to fit a specific dimention rather than percentage of size.

@examples[
 #:eval helper-eval
 (scale-to-fit logo 100)]

@defproc[(safe-above [imgs image?] ...)
         image?]

An above function that handles being called with 0 or 1 images. Perfect for
use in complex image building functions that will be given a range of images
and might run into a list of 0 or 1.

@defproc[(safe-beside [imgs image?])
         image?]

A beside function that handles being called with 0 or 1 images. Perfect for
use in complex image building functions that will be given a range of images
and might run into a list of 0 or 1.

@defproc[(safe-overlay [imgs image?])
         image?]

An overlay function that handles being called with 0 or 1 images. Perfect for
use in complex image building functions that will be given a range of images
and might run into a list of 0 or 1.


@defproc[(pad-list [imgs (listof image?)])
         (listof image?)]

Adds transparent images to bring the length of a list up to a number divisible
by 3. Build with the purpose of buffering lists of cards being sent to
print so they will all scale to the same size no matter how many cards are
on the final page.

@defproc[(cards->pages [imgs (listof (or/c image? pict?))])
         (listof image?)]

Creates a 3 by 3 page of images (usually used for cards or badges). Ideal for printing!

@racketblock[(cards->pages
              (append
               (badges (course 1208))
               (list
                (build-badge (student 1753) 1208 "Triceratops"))))]


@defproc[(quest-cards->pages [imgs (listof pict?)])
         (listof image?)]

Like @racket[cards->pages], this creates a 3 by 3 page of images.
Handles the fact that our quest cards are usually fairly large.  Scales them down.

@racketblock[(quest-cards->pages
              quest)]





@defproc[(print-image! [image image?])
         boolean?]

Saves an image to a temporary file and uses system commands to print said file.

NOTE: Only works on macs for now.

@racketblock[(print-image
              (bitmap "happyface.png"))]

@racketblock[(map print-image!
                  (cards->pages
                   (append
                     (badges (course 1208))
                     (list
                      (build-badge (student 1753) 1208 "Triceratops")))))]





@defproc[(code+hints [#:settings settings (hint-settings?) (hints-on-top)]
                     [code pict?]
                     [hints list?])
         pict?]

Built for use in curriculum -- for launch codes etc.

@larger{Example uses:}

@centered{@bold{Defining a code image with one hint.}}

Inside this definition, you need two additional definitions prior to calling @racket[code+hints].
@bold{First} define the code snippet you wish to hint. @bold{Second}, define the rest of the code,
inserting the previously defined code snippet where it belongs. @bold{Lastly}, call @racket[code+hints].

@examples[
 #:eval helper-eval
 #:escape potato
 (require pict/code)
 
 (define (example-code)

   (define target (code "Triceritops"))

   (define all-code (code (build-badge (student 1753) 1208 #,target)))

   (code+hints all-code
               (list target (hint "This argument is optional."
                                  "This nickname will replace"
                                  "the name in the student struct."))))

 (example-code)]

@centered{@bold{Defining a code image with multiple hints.}}

In this case, you need pull out and define each snippet of code you want to hint.

@examples[
 #:eval helper-eval
 #:escape potato
 (require pict/code)
 
 (define (example-code)

   (define id (code 1753))

   (define course (code 1208))
   
   (define nickname (code "Triceritops"))

   (define all-code (code (build-badge (student #,id) #,course #,nickname)))

   (code+hints all-code
               (list id (hint "Cannot be negative number."))
               (list course (hint "This neither."))
               (list nickname (hint "This argument is optional."
                                    "This nickname will replace"
                                    "the name in the student struct."))))

 (example-code)]

@centered{@bold{Defining a code image with hints to the right of the code.}}

You will want to use the optional keyword parameter @racket[#:settings].

@examples[
 #:eval helper-eval
 #:escape potato
 (require pict/code)
 
 (define (example-code)
   
   (define nickname (code "Triceritops"))

   (define all-code (code (build-badge (student 1753) 1208 #,nickname)))

   (code+hints all-code
               #:settings hints-on-right
               (list nickname (hint "Please don't replace student"
                                    "names with dinosaurs."))))

 (example-code)]
















@section{Alerts}

@defproc[(send-alerts [alerts alerts?])
         void?]

Sends alerts.  Alerts should be created with @racket[create-alerts].
For example, this will send an alert to all computers at meeting 6686.

@racketblock[
 (send-alerts
  (create-alerts
   (computer-ids (meeting 6686))
   voice-alert
   "Test!"))
]

@defproc[(create-alerts [computer-ids (or/c (listof number?)
                                            string?)]
                        [alert-type alert-type?]
                        [message string?])
         alerts?]

Creates alerts for some list of computer ids.  The computer
ids can either be a comma separated string (for easy pasting):

@racket["1,2,3"]

Or it can be a list of numbers:

@racket['(1 2 3)]


@defproc[(alert-type? [x any/c])
         boolean?]

Can be any member of the following constants.

@racketblock[
 (define phone-alert   "phone")
 (define help-alert    "help")
 (define full-alert    "full")
 (define block-alert   "block")
 (define voice-alert   "voice")
 (define message-alert "message")
 (define link-alert    "link")
 (define command-alert "common")
 ]










