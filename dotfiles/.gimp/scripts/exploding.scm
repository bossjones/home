; exploding.scm 
; creates exploding logos
; (c) 1998 stefan stiasny
;
; The GIMP -- an image manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.


;; Functions to create spline curves to send to gimp-curves-spline
(define (set-pt a index x y)
  (prog1
   (aset a (* index 2) x)
   (aset a (+ (* index 2) 1) y)))

(define (spline-exploding)
  (let* ((a (cons-array 6 'byte)))
    (set-pt a 0 0 0)
    (set-pt a 1 127 255)
    (set-pt a 2 255 0)
    a))

(define (script-fu-exploding-logo text size font blur displace_loop hue blur_toggle crop_toggle)
  (let*	(
    (img (car (gimp-image-new size size RGB)))
    (theBgLayer (car (gimp-layer-new img size size RGB "Background" 100 NORMAL-MODE)))
    (oldfg (car (gimp-context-get-foreground)))
    (oldbg (car (gimp-context-get-background)))
    (theText)
    (theTextLayer)
    (theImageWidth)
    (theImageHeight)
    (theImageSize)
    (theBuffer)
    (thePolarLayer)
    (theNoiseLayer)
    (theGreyLayer)
    (theMergedLayer)
    (i)
    )
 
    (gimp-image-undo-disable img)
    (gimp-image-add-layer img theBgLayer 0)
    (gimp-context-set-background '(255 255 255))
    (gimp-context-set-foreground '(0 0 0))
    (gimp-edit-fill theBgLayer 0)
    (set! theTextLayer (car (gimp-layer-copy theBgLayer 0)))
    (gimp-drawable-set-name theTextLayer "Text")

    (gimp-image-add-layer img theTextLayer 0)
;    (set! theText (car (gimp-text img theTextLayer 50 0 text 0 1  size 1 "*" font "medium" "r" "*" "*" )))
    (set! theText (car (gimp-text img theTextLayer 50 0 text 0 TRUE  size 1 "*" font "medium" "r" "*" "*" "*" "*")))
    (set! theImageWidth (+ (car (gimp-drawable-width theText)) 100))
    (set! theImageHeight (+ (car (gimp-drawable-height theText)) 100))
    (set! theImageSize theImageWidth)

    (gimp-image-resize img theImageSize theImageSize 0 0) 
    (gimp-layer-resize theBgLayer theImageSize theImageSize 0 0) 
    (gimp-layer-resize theTextLayer theImageSize theImageSize 0 0) 
    (set! theBuffer (/ (- theImageSize (car(gimp-drawable-height theText))) 2 ))
    (gimp-layer-set-offsets theText 50 theBuffer)
    (gimp-floating-sel-anchor theText)
    (plug-in-gauss-iir 1 img theTextLayer blur TRUE TRUE)
    (gimp-curves-spline theTextLayer 0 6 (spline-exploding))
    (gimp-curves-spline theTextLayer 0 6 (spline-exploding))

    (set! thePolarLayer (car (gimp-layer-copy theTextLayer 0)))
    (gimp-drawable-set-name thePolarLayer "Polar")
    (gimp-image-add-layer img thePolarLayer 1)
    (plug-in-polar-coords 1 img thePolarLayer 100.000 0.000 FALSE TRUE FALSE)

    (set! theNoiseLayer (car (gimp-layer-new img theImageSize 10 RGB "Noise" 100 LIGHTEN-ONLY-MODE)))
    (set! theGreyLayer (car (gimp-layer-new img theImageSize theImageSize RGB "Grey" 100 NORMAL-MODE)))

    (gimp-image-add-layer img theNoiseLayer 2)
    (gimp-image-add-layer img theGreyLayer 3)
    (gimp-context-set-background '(128 128 128))
    (gimp-context-set-foreground '(0 0 0))
    (gimp-edit-fill theGreyLayer 1)
    (gimp-edit-fill theNoiseLayer 1)
    (gimp-edit-fill theBgLayer 0)

    (plug-in-noisify 1 img theNoiseLayer 1 0.20 0.20 0.20 0.00)
    (gimp-desaturate theNoiseLayer)
    (gimp-layer-scale theNoiseLayer theImageSize theImageSize 1)
    (gimp-layer-set-offsets theNoiseLayer 0 0)

    (gimp-drawable-set-visible theBgLayer 0)
    (gimp-drawable-set-visible theTextLayer 0)
    (gimp-drawable-set-visible thePolarLayer 0)
    (set! theMergedLayer (car (gimp-image-merge-visible-layers img 2)))

    (plug-in-displace 1 img thePolarLayer 0.000 -100.000 FALSE TRUE theMergedLayer theMergedLayer 0)
  ;;(plug-in-blur 1 img thePolarLayer)
    (plug-in-gauss-iir 1 img thePolarLayer blur TRUE TRUE)

    (set! i displace_loop)
    (while (> i 0)
        (plug-in-displace 1 img thePolarLayer 0.000 -100.000 FALSE TRUE theMergedLayer theMergedLayer 0)
        (if (= TRUE blur_toggle)
        (plug-in-gauss-iir 1 img thePolarLayer blur TRUE TRUE))
        (set! i (- i 1)))
    
    (plug-in-polar-coords 1 img thePolarLayer 100.000 0.000 FALSE TRUE TRUE)
    (gimp-edit-bucket-fill thePolarLayer FG-BUCKET-FILL NORMAL-MODE 100 1 0 1 1)
    (gimp-colorize thePolarLayer hue 100 0)

    (gimp-drawable-set-visible theBgLayer 1)
    (gimp-drawable-set-visible theTextLayer 1)
    (gimp-drawable-set-visible thePolarLayer 1)
    (gimp-drawable-set-visible theMergedLayer 0)
    (gimp-layer-set-mode theTextLayer OVERLAY-MODE)

    (if (= crop_toggle TRUE) 
        (gimp-image-crop img theImageSize (/ theImageSize 3) 0 (/ theImageSize 3)))

    (gimp-context-set-foreground oldfg)
    (gimp-context-set-background oldbg)
    (gimp-display-new img)
    (gimp-image-undo-enable img)
  )
)

(script-fu-register "script-fu-exploding-logo"
                    "Exploding"
                    "Creates anything you can create with it :)"
                    "Stefan Stiasny <sc@oeh.net>"
                    "Stefan Stiasny"
                    "11/08/1998"
                    ""
                    SF-STRING     _"Text"        "SNOWCRASH"
                    SF-ADJUSTMENT _"Font size (pixels)" '(60 2 1000 1 10 0 1)
                    SF-FONT       _"Font"        "Baskerville Bold"
                    SF-ADJUSTMENT _"               "  '(5 1 100 1 10 0 1)
                    SF-ADJUSTMENT _"               "  '(3 1 100 1 10 0 1)
                    SF-ADJUSTMENT _"      "        '(32 1 100 1 10 0 1)
                    SF-TOGGLE      "                  " FALSE
                    SF-TOGGLE      "               "   TRUE)

(script-fu-menu-register "script-fu-exploding-logo"
                    _"<Toolbox>/Xtns/Script-Fu/Extra Logos")

