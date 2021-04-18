Red [ needs 'view ]

;; mouse zooming experiment
;; panels always scale from 0x0 regardless of where you put them, so doing it the hard way...

screenpos: 0x0				; selection pos in screen space
screenscaled: 0x0			; scaled selection pos
screenoffset: 0x0			; translated selection pos
memscreenpos: 0x0			; memorized screen pos
memscreenscaled: 0x0		; memorized scaled screen pos
memscreenoffset: 0x0		; memorized screen offset
memscreenscaleoffset: 0x0 	; memorized screen scale offset
memgridpos: 0x0				; grid-locked selection screen pos

sp: 0x0
msp: 0x0
so: 0x0
dso: 0x0
mso: 0x0
zp: 0x0
pp: 0x0
pzp: 0x0
zo: 0x0

ogp: copy []

dragoffset: 0x0
memdragoffset: 0x0

gridsize: 400x400

trackstart: [ [0x0 10x50] [10x0 20x80] [20x0 30x75] [30x0 40x10] [40x0 50x118] [50x0 60x93] ]
tracklok: [ [0x0 0x0] [0x0 0x0] [0x0 0x0] [0x0 0x0] [0x0 0x0] [0x0 0x0] ]

bi: 0x0
bx: 0x0
oldbi: 100x100
oldbx: 200x200

gscl: [ 1.0 1.0 ]
boxmin: 100x100
boxmax: 200x200

grdofs: 0x0
coo: 400x400
corg: 0x0
mco: 0x0
scl: [ 1.0 1.0 ]
lokofs: 0x0
tlokofs: 0x0
mmid: false
mmdown: 0x0
mmofs: 0x0
circp: 100x100
tcircp: 100x100
sw: now/time/precise
ew: now/time/precise

zoomit: function [ p m s ] [
	o: 0x0
	;print [ "old pos = " p ]
	;print [ "marker == " m ]
   	;print [ "scale === " s ]
	o/x: to-integer (((p/x - m/x) * s/1) + m/x)
	o/y: to-integer (((p/y - m/y) * s/2) + m/y)
	o
]

initgrid: func [ spc ] [
	gx: 400 * (1.0 / gscl/1)
	gp: to-integer (gx / spc)
	gs: spc * gscl/1
	repeat i gp [
		gxa: (to-pair reduce [ (to-integer (spc * i)) 0 ])
		gxb: (to-pair reduce [ (to-integer (spc * i)) 400 ])
		gya: (to-pair reduce [ 0 (to-integer (spc * i)) ])
		gyb: (to-pair reduce [ 400 (to-integer (spc * i)) ])
		append/only ogp compose [ (gxa) (gxb) (gya) (gyb) ]
	]
]

zoomgrid: func [ p ] [
	ngp: copy []
    foreach g ogp [
		gxa: zoomit g/1 msp scl
		gxb: zoomit g/2 msp scl
		gya: zoomit g/3 msp scl
		gyb: zoomit g/4 msp scl
		append p/draw compose [
		    pen 80.80.80
	    	line (gxa) (gxb)
	    	line (gya) (gyb)
		]
		append/only ngp compose [ (gxa) (gxb) (gya) (gyb) ]
	]
	clear ogp
	foreach g ngp [ append/only ogp g ]	
]

pangrid: func [ p d ] [
    foreach g ogp [
		gxa: g/1 + d
		gxb: g/2 + d
		gya: g/3 + d
		gyb: g/4 + d
		append p/draw compose [
		    pen 80.80.80
	    	line (gxa) (gxb)
	    	line (gya) (gyb)
		]
	]
]

endpangrid: func [ ] [
	ngp: copy []
    foreach g ogp [
		append/only ngp compose [ (gxa) (gxb) (gya) (gyb) ]
	]
	clear ogp
	foreach g ngp [ append/only ogp g ]	
]

drawdemosquare: func [ p ] [
	ff: make font! [size: 8 name: "Consolas" style: 'bold color: 220.50.50 anti-alias? true]
	bf: make font! [size: 8 name: "Consolas" style: 'bold color: 150.20.20 anti-alias? true]
	append p/draw compose [
		pen 255.50.50 box (bi) (bx)
		pen 150.20.20 box (oldbi) (oldbx)
		line (to-pair reduce [ oldbi/x oldbi/y ]) (to-pair reduce [ bi/x bi/y ])
		line (to-pair reduce [ oldbi/x oldbx/y ]) (to-pair reduce [ bi/x bx/y ])
		line (to-pair reduce [ oldbx/x oldbi/y ]) (to-pair reduce [ bx/x bi/y ])
		line (to-pair reduce [ oldbx/x oldbx/y ]) (to-pair reduce [ bx/x bx/y ])
	]
	append p/draw compose [
		font (bf)
		text (to-pair reduce [ (oldbi/x) (oldbi/y) ]) (rejoin reduce [ (oldbi/x) "x" (oldbi/y) ])
		text (to-pair reduce [ (oldbi/x) (oldbx/y) ]) (rejoin reduce [ (oldbi/x) "x" (oldbx/y) ])
		text (to-pair reduce [ (oldbx/x) (oldbi/y) ]) (rejoin reduce [ (oldbx/x) "x" (oldbi/y) ])
		text (to-pair reduce [ (oldbx/x) (oldbx/y) ]) (rejoin reduce [ (oldbx/x) "x" (oldbx/y) ])
		font (ff)
		text (to-pair reduce [ (bi/x) (bi/y) ]) (rejoin reduce [ (bi/x) "x" (bi/y) ])
		text (to-pair reduce [ (bi/x) (bx/y) ]) (rejoin reduce [ (bi/x) "x" (bx/y) ])
		text (to-pair reduce [ (bx/x) (bi/y) ]) (rejoin reduce [ (bx/x) "x" (bi/y) ])
		text (to-pair reduce [ (bx/x) (bx/y) ]) (rejoin reduce [ (bx/x) "x" (bx/y) ])
	]
]

drawzoom: function [ p ] [
	tf: make font! [size: 16 name: "Consolas" style: 'bold color: 80.80.80 anti-alias? true]
	append p/draw compose [ font (tf) ]
	append p/draw compose [
		text (to-pair reduce [ (p/size/x - 220) (p/size/y - 40)  ]) (rejoin reduce [ "zoom: " (round/to gscl/1 0.1) " x " (round/to gscl/2 0.1) ])
	]
]

initgrid 25
probe ogp

view/tight [
	t: panel 400x400 [
		below
		p: panel 400x400 30.30.80 draw [ ] [
			gg1: panel 400x400 30.30.30 all-over draw [ ] on-wheel [

;; scale

				scl/1: 1.0
				scl/2: 1.0
				either event/picked > 0 [
				    scl/1: min (scl/1 + 0.1) 10.0
					scl/2: min (scl/2 + 0.1) 10.0
					gscl/1: gscl/1 + 0.1
					gscl/2: gscl/2 + 0.1
				] [
					scl/1: max (scl/1 - 0.1) 0.1 
					scl/2: max (scl/2 - 0.1) 0.1
					gscl/1: gscl/1 - 0.1
					gscl/2: gscl/2 - 0.1
				]

				clear face/draw

;; sample grid goes here

			    zoomgrid face

;; sample bar graph goes here
				

;;  demo square goes here

				bi: zoomit oldbi msp scl 
			    bx: zoomit oldbx msp scl 

				drawdemosquare face

;; mark pivot

				append face/draw compose [
					pen 0.0.255
					line-width 1
					line (to-pair reduce [ msp/x 0 ]) (to-pair reduce [ msp/x 400 ])
					line (to-pair reduce [ 0 msp/y ]) (to-pair reduce [ 400 msp/y ])
				]

;; other stats

				drawzoom face

;; remember positions

			    oldbi: bi
				oldbx: bx

			] on-down [

;; mark pivot, snap to 10's

				msp: to-pair reduce [ (round/to event/offset/x 10) (round/to event/offset/y 10) ]
				append face/draw compose [
					pen 0.0.255
					line-width 1
					line (to-pair reduce [ msp/x 0 ]) (to-pair reduce [ msp/x 400 ])
					line (to-pair reduce [ 0 msp/y ]) (to-pair reduce [ 400 msp/y ])
				]
			] on-mid-down [ 

;; mark middle-mouse drag

				mmid: true
				mmdown: event/offset
			] on-over [
				if mmid [

;; get drag offset

				    dso: (event/offset - mmdown)
					clear face/draw

;; draw grid

					pangrid face dso

;; add drag offset to positions

					bi: oldbi + dso
					bx: oldbx + dso

;; update demo square (move this to func)

				    drawdemosquare face

;; mark pivot

					append face/draw compose [
						pen 0.0.255
						line-width 1
						line (to-pair reduce [ msp/x 0 ]) (to-pair reduce [ msp/x 400 ])
						line (to-pair reduce [ 0 msp/y ]) (to-pair reduce [ 400 msp/y ])
					]

;; update other stats (move to func)

					drawzoom face
				]
			] on-mid-up [

;; stop dragging

				mmid: false

;; remember positions

			    dso: 0
			    oldbi: bi
				oldbx: bx
				endpangrid
			]
		] 
	]
	do [ t/offset: 0x0 p/offset: 0x0 gg1/offset: 0x0 ]
]
