; The GIMP -- an img manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
; -----------------------------------------------------------------------
; The GIMP script-fu  Toy Camera.scm  for GIMP2.2
; Copyright (C) 2005 Tamagoro <tamagoro_1@excite.co.jp>
; -----------------------------------------------------------------------
;                                                                                     
; LOMO                                                                     
;                                                                             
;                                                                   
; ************************************************************************

(define (script-fu-toycamera image drawable contrast dark focus fringe new-image)

 (let* (
 	    (W (car (gimp-drawable-width drawable)))
 	    (H (car (gimp-drawable-height drawable)))
 	    (mX (/ W 2)) (mY (/ H 2))
 	    (wh (/ (- W H) 4)) (hw (/ (- H W) 4))
 	    (type (car (gimp-drawable-type drawable)))
 	    (img (car (gimp-image-new W H 0)))
 	    (base (car (gimp-layer-new img W H RGBA-IMAGE "Toy Camera" 100 NORMAL))) 
 	    (channel-1 (car (gimp-channel-new img W H "channel" 0 '(0 0 0))))
 	    (old-fg (car (gimp-context-get-foreground))) 
 	    (old-bg (car (gimp-context-get-background)))
 	    (channel-2)
 	    (copy-layer)
 	    (mblur-layer)
 	    (focus-layer)
 	    (edge-layer)
 	    (opacity)
 	    (mask)
 	    (blur-layer)
 	    (blur-layer1)
 	    (blur-layer2)
 	    (blur-layer3)
 	    (contrast-layer)
 	    (merge-layer) )


 	(gimp-image-undo-group-start image)
 	(gimp-image-undo-disable img)
 	(gimp-context-set-foreground '(255 255 255))
 	(gimp-context-set-background '(0 0 0))

; New image --------------------------------------------------------------------
 	(gimp-selection-none image)
 	(gimp-edit-copy drawable)
 	(gimp-image-add-layer img base -1)
 	(if (> type 1)(gimp-convert-grayscale img))
 	(gimp-floating-sel-anchor (car (gimp-edit-paste base FALSE)))

; Make channel -----------------------------------------------------------------
 	(gimp-image-add-channel img channel-1 0)
 	(gimp-edit-fill channel-1 1)
 	(if (> wh 1)
 	     (gimp-ellipse-select img wh 0 (- W (* wh 2)) H REPLACE TRUE FALSE 0)
 	     (gimp-ellipse-select img 0 hw W (- H (* hw 2)) REPLACE TRUE FALSE 0) )
 	(gimp-selection-shrink img 1)
 	(gimp-selection-feather img (/ (+ W H) (- 5.5 (/ dark 100))) )
 	(gimp-edit-fill channel-1 0)
 	(gimp-selection-none img)
 	(gimp-levels-auto channel-1)
 	(set! channel-2 (car (gimp-channel-copy channel-1)))
 	(plug-in-rgb-noise 1 image channel-1 FALSE FALSE 0.03 0.03 0.03 0.00)

 	(gimp-image-add-channel img channel-2 0)
 	(gimp-selection-invert img)
 	(gimp-brightness-contrast channel-2 127 115)
 	(gimp-invert channel-2)

; Equalize ---------------------------------------------------------------------
 	(set! copy-layer (car (gimp-layer-copy base TRUE)))
 	(gimp-image-add-layer img copy-layer -1)
 	(if (< type 2)
 	    (begin
  	      (plug-in-colorify 1 img copy-layer '(255 255 255))
  	      (gimp-invert copy-layer))
  	    (gimp-invert copy-layer) )
 	(gimp-selection-load channel-1)
 	(gimp-edit-clear copy-layer)
 	(gimp-selection-invert img)
 	(gimp-levels base 0 0 255 1.00 20 235)
 	(gimp-selection-none img)
 	(gimp-levels copy-layer 4 0 255 1.00 125 255)
 	(gimp-layer-set-mode copy-layer OVERLAY)
 	(set! base (car (gimp-image-merge-down img copy-layer 1)))

; Around darkness --------------------------------------------------------------
 	(set! copy-layer (car (gimp-layer-copy base TRUE)))
 	(gimp-image-add-layer img copy-layer -1)
 	(gimp-invert copy-layer)
 	(if (< type 2)(gimp-hue-saturation copy-layer 0 180 0 0))
 	(gimp-levels copy-layer 0 0 255 1.00 0 128)
 	(gimp-selection-load channel-1)
 	(gimp-edit-clear copy-layer)
 	(gimp-layer-set-mode copy-layer MULTIPLY)
 	(gimp-layer-set-opacity copy-layer (/ dark 2))
 	(set! base (car (gimp-image-merge-down img copy-layer 1)))

 	(gimp-selection-invert img)
 	(gimp-bucket-fill base BG-BUCKET-FILL OVERLAY (+ 5 (/ dark 2)) 255 FALSE 0 0)
 	(if (< type 2)(gimp-levels base 3 0 250 1.00 0 255))

 	(gimp-selection-load channel-2)
 	(gimp-bucket-fill base BG-BUCKET-FILL NORMAL (/ dark 1.5) 255 FALSE 0 0)
 	(gimp-selection-none img)

; Focus blur -------------------------------------------------------------------
 	(set! mblur-layer (car (gimp-layer-copy base TRUE)))
 	(gimp-image-add-layer img mblur-layer -1)
 	(gimp-selection-load channel-1)
 	(gimp-edit-clear mblur-layer)
 	(gimp-selection-none img)
 	(plug-in-mblur 1 img mblur-layer 1 0 1 mX mY)
 	(gimp-layer-set-opacity mblur-layer (+ 50 (* focus 10)))
 	(set! base (car (gimp-image-merge-down img mblur-layer 1)))

 	(set! focus-layer (car (gimp-layer-copy base TRUE)))
 	(set! edge-layer (car (gimp-layer-copy base TRUE)))

 	(gimp-image-add-layer img focus-layer -1)
 	(plug-in-blur 1 img focus-layer)
 	(gimp-rect-select img 0 0 W 1 REPLACE FALSE 0)
 	(gimp-edit-clear focus-layer)
 	(gimp-selection-none img)
 	(set! opacity (/ (+ W H) 20))
 	(if (> opacity 100)
 	     (gimp-layer-set-opacity focus-layer 100)
 	     (gimp-layer-set-opacity focus-layer (/ (+ W H) 20)) )
 	(set! base (car (gimp-image-merge-down img focus-layer 1)))

 	(gimp-image-add-layer img edge-layer -1)
 	(set! mask (car (gimp-layer-create-mask edge-layer 5)))
 	(gimp-image-add-layer-mask img edge-layer mask)
 	(plug-in-blur 1 img mask)
 	(plug-in-edge 1 img mask 5.0 1 0)
 	(gimp-layer-remove-mask edge-layer 0)
 	(gimp-selection-load channel-1)
 	(gimp-selection-invert img)
 	(gimp-edit-clear edge-layer)
 	(gimp-selection-none img)
 	(gimp-layer-set-opacity edge-layer (- 100 (* focus 10)))
 	(set! base (car (gimp-image-merge-down img edge-layer 1)))

; Soft focus -------------------------------------------------------------------
 	(set! blur-layer (car (gimp-layer-copy base TRUE)))
 	(gimp-image-add-layer img blur-layer -1)
 	(plug-in-gauss-iir2 1 img blur-layer (+ 1 (/ (+ W H) 500)) (+ 1 (/ (+ W H) 500)))
 	(set! blur-layer1 (car (gimp-layer-copy blur-layer TRUE)))
 	(set! blur-layer2 (car (gimp-layer-copy blur-layer TRUE)))
 	(set! blur-layer3 (car (gimp-layer-copy blur-layer TRUE)))

 	(gimp-selection-load channel-1)
 	(gimp-edit-clear blur-layer)
 	(gimp-selection-none img)
 	(gimp-layer-set-opacity blur-layer (/ dark 2))

 	(gimp-image-add-layer img blur-layer1 -1)
 	(if (> focus 1) 
 	    (plug-in-vpropagate 1 image blur-layer1 0 TRUE 1.0 15 0 255))
 	(if (= focus 0)
 	    (gimp-layer-set-opacity blur-layer1 5)
 	    (gimp-layer-set-opacity blur-layer1 (* focus 20)) )

 	(set! base (car (gimp-image-flatten img)))
 	(set! contrast-layer (car (gimp-layer-copy base TRUE)))

; Contrast ---------------------------------------------------------------------
 	(gimp-image-add-layer img blur-layer2 -1)
 	(if (< type 2)
 	    (plug-in-colortoalpha 1 img blur-layer2 '(0 0 0))
 	    (begin
 	      (gimp-convert-rgb img)
 	      (plug-in-colortoalpha 1 img blur-layer2 '(0 0 0))
 	      (gimp-convert-grayscale img) ))
 	(gimp-image-add-layer img blur-layer3 -1)
 	(if (< type 2)(gimp-hue-saturation blur-layer3 0 0 0 -80))
 	(gimp-selection-load channel-1)
 	(gimp-edit-clear blur-layer3)
 	(gimp-selection-none img)
	(gimp-levels blur-layer3 4 0 255 1.00 127 255)
 	(set! merge-layer (car (gimp-image-merge-down img blur-layer3 1)))
 	(gimp-layer-set-mode merge-layer OVERLAY)

 	(gimp-image-add-layer img contrast-layer -1)
 	(if (< type 2)(gimp-hue-saturation contrast-layer 0 0 0 (/ (- 0 contrast) 2)))
 	(gimp-layer-set-mode contrast-layer 18)
 	(gimp-layer-set-opacity contrast-layer contrast)
 	(set! base (car (gimp-image-flatten img)))

 	(if (< type 2)(gimp-levels base 3 0 250 1.00 0 255))
 	(plug-in-sharpen 1 image base (+ 10 (/ (+ W H) 200)))
 	(plug-in-rgb-noise 1 img base FALSE FALSE 0.01 0.01 0.01 0.00)

; Fringe -----------------------------------------------------------------------
 	(if (equal? fringe TRUE)
 	     (begin 
           (gimp-selection-all img)
           (gimp-selection-shrink img (/ (+ W H) 73))
           (gimp-selection-invert img)
           (gimp-selection-feather img (+ (/ (+ W H) 800) 1))
           (gimp-edit-fill base 0)
           (gimp-selection-none img) ))

; Clean up ---------------------------------------------------------------------
 	(if (equal? new-image TRUE)
 	     (begin 
 	       (gimp-image-remove-channel img channel-1)
 	       (gimp-image-remove-channel img channel-2)
 	       (gimp-image-undo-enable img)
 	       (gimp-display-new img))
 	     (begin 
 	       (gimp-edit-copy base)
 	       (gimp-floating-sel-anchor (car (gimp-edit-paste drawable FALSE)))
  	       (gimp-image-delete img)) )

 	(gimp-context-set-foreground old-fg)
 	(gimp-context-set-background old-bg)
 	(gimp-image-undo-group-end image)
 	(gimp-displays-flush)
 )
)

; register-------------------------------------------------------------

(script-fu-register "script-fu-toycamera"
 	"Toy Camera..."
"                                                               "
 	"         "
 	"Tamagoro <tamagoro_1@excite.co.jp>"
 	"2005/01"
 	"RGB* GRAY*"
 	SF-IMAGE      "Image"     0
 	SF-DRAWABLE   "Drawable"  0
 	SF-ADJUSTMENT "                  "  '(50 0 100 1 10 0 0)
 	SF-ADJUSTMENT "            "      '(30 0 100 1 10 0 0)
 	SF-ADJUSTMENT "               "    '(1 0 5 1 1 0 1)
 	SF-TOGGLE     "                  "   FALSE
 	SF-TOGGLE     "            "       FALSE
 )

(script-fu-menu-register "script-fu-toycamera"
 	"<Image>/Script-Fu/Photo")
