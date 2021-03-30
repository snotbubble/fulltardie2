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

dragoffset: 0x0
memdragoffset: 0x0

gridsize: 400x400

trackstart: [ [0x0 10x50] [10x0 20x80] [20x0 30x75] [30x0 40x10] [40x0 50x118] [50x0 60x93] ]
tracklok: [ [0x0 0x0] [0x0 0x0] [0x0 0x0] [0x0 0x0] [0x0 0x0] [0x0 0x0] ]

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

screenscaleandoffset: function [ p o s ] [
	print [ "screenscaleandoffset [ p o s ] : " p o s ]
	t: 0x0
    fx: to-integer (p/x * s/1)
    fy: to-integer (p/y * s/2)
	print [ "fx fy : " fx fy ]
    t/x: fx - p/x
    t/y: fy - p/y
	print [ "fx - t : " t ]
	t/x: t/x - o/x
	t/y: t/y - o/y
	print [ "t - o : " t ]
	t
]

scaleandoffset: function [ p o s ] [
    p/x: to-integer (p/x * s/1)
    p/y: to-integer (p/y * s/2)
    p/x: p/x - o/x
    p/y: p/y - o/y
	p
]

drawgrid: func [ p k ] [
	gwdth: 25
	gspcx: gwdth * scl/1
	gnumx: (to-integer (gridsize/x / gspcx))
	gspcy: 25.0 * scl/2
	gnumy: (to-integer (gridsize/y / gspcy))
	gf: make font! [size: 8 name: "Consolas" color: 180.180.180 ]
	append p/draw compose [ font (gf) ]
	repeat i (max gnumx gnumy) [
		ix: scaleandoffset to-pair reduce [ (to-integer (i * gwdth)) (to-integer (i * gwdth)) ] k scl
		gtx: to-pair reduce [ ix/x 5 ]
		gty: to-pair reduce [ 5 ix/y ]
		glxa: to-pair reduce [ ix/x 0 ]
		glxb: to-pair reduce [ ix/x gridsize/y ]
		glya: to-pair reduce [ 0 ix/y ]
		glyb: to-pair reduce [ gridsize/x ix/y ]
		either (i % 2) = 0 [
			append p/draw compose [ 
				pen 50.50.50 
				line (glxa) (glxb) 
				line (glya) (glyb)
				text (gtx) (rejoin reduce [ (to-integer (gwdth * i)) ])
				text (gty) (rejoin reduce [ (to-integer (gwdth * i)) ])
			]
		] [
			append p/draw compose/deep [ 
				pen 40.40.40 
				line (glxa) (glxb) 
				line (glya) (glyb)
			]
		]
	]	
]

drawdbg: func [ p xf gp ] [
	tfx: 5
	if ((coo/x - xf/x) < 150) [ tfx: -155 ]
	tc: to-pair reduce [ (tfx) 5 ]
	tf: make font! [size: 10 name: "Consolas" style: 'bold]
	append p/draw compose [ font (tf) ]
	append p/draw compose [ 
		pen 80.80.255  
		line (to-pair reduce [ xf/x 0 ]) (to-pair reduce [ xf/x gridsize/y]) line (to-pair reduce [ 0 xf/y ]) (to-pair reduce [ gridsize/x xf/y]) 
		text (xf + tc) (rejoin reduce [ "screen mark : " (xf/x) "x" (xf/y) ])
	]

	tf: make font! [size: 10 name: "Consolas" style: 'bold color: 80.255.80 anti-alias? true]
	append p/draw compose [ font (tf) ]
	append p/draw compose [ 
		pen 0.255.0 
		text (xf + tc + 0x15) (rejoin reduce [ "screen offset: " (memscreenoffset/x - xf/x) "," (memscreenoffset/y - xf/y) ])
	]

	if ((gridsize/x - gp/x) < 150) [ tfx: -155 ]
	tc: to-pair reduce [ (tfx) 5 ]
	tf: make font! [size: 10 name: "Consolas" style: 'bold color: 255.80.80 anti-alias? true]
	append p/draw compose [ font (tf) ]
	append p/draw compose [ 
		pen 255.0.0 
		line-width 3
		line (to-pair reduce [ gp/x 0 ]) (to-pair reduce [ gp/x gridsize/y ])
		line (to-pair reduce [ 0 gp/y ]) (to-pair reduce [ gridsize/x gp/y ])
		text (gp + tc) (rejoin reduce [ "grid lock : " (xf/x) "x" (xf/y) ])
	]
]

drawzoom: function [ p ] [
	tf: make font! [size: 16 name: "Consolas" style: 'bold color: 80.80.80 anti-alias? true]
	append p/draw compose [ font (tf) ]
	append p/draw compose [
		text (to-pair reduce [ (p/size/x - 220) (p/size/y - 40)  ]) (rejoin reduce [ "zoom: " (round/to scl/1 0.1) " x " (round/to scl/2 0.1) ])
	]
]

view/tight [
	t: panel 400x400 [
		below
		p: panel 400x400 30.30.80 draw [ ] [
			gg1: panel 400x400 30.30.30 all-over draw [ ] on-wheel [

				print [ "screen offset before zoom: " memscreenoffset ]

;; scale

				either event/picked > 0 [
				    scl/1: min (scl/1 + 0.1) 10.0
					scl/2: min (scl/2 + 0.1) 10.0
				] [
					scl/1: max (scl/1 - 0.1) 1.0 
					scl/2: max (scl/2 - 0.1) 1.0 
				]

;; scale the drag offset

				;dragoffset: memdragoffset * to-pair reduce [ (scl/1) (scl/2) ]

			    screenoffset: screenscaleandoffset memscreenpos memdragoffset scl

				memgridpos: scaleandoffset memscreenpos screenoffset scl

			    repeat t (length? trackstart) [
				    tracklok/:t/1: scaleandoffset trackstart/:t/1 screenoffset scl
				    tracklok/:t/2: scaleandoffset trackstart/:t/2 screenoffset scl
				]

				clear face/draw

				foreach t tracklok [
					append face/draw compose [ pen 255.50.50 fill-pen 180.50.50 box (t/1) (t/2) ]
				]
				append face/draw compose [ fill-pen off ]

			    drawgrid face screenoffset
				drawdbg face memscreenpos memgridpos
				drawzoom face

				memscreenoffset: screenoffset
				memscreenscaled: screenscaled
			    print [ "screen offset after zoom: " memscreenoffset ]

			] on-down [
				memscreenpos: to-pair reduce [ (round/to event/offset/x 25) (round/to event/offset/y 25 ) ]
				screenoffset: screenscaleandoffset memscreenpos memdragoffset scl
				repeat t (length? trackstart) [
					tracklok/:t/1: scaleandoffset trackstart/:t/1 screenoffset scl
					tracklok/:t/2: scaleandoffset trackstart/:t/2 screenoffset scl
				]
				gridpos: scaleandoffset memscreenpos screenoffset scl
				clear face/draw
				foreach t tracklok [
					append face/draw compose [ pen 255.50.50 fill-pen 180.50.50 box (t/1) (t/2) ]
				]
				append face/draw compose [ fill-pen off ]
				drawgrid face screenoffset
				drawdbg face memscreenpos gridpos
				print [ "on-down event happened at: " memscreenpos ]
				append face/draw compose [ pen 255.0.0 line-width 3 line (to-pair reduce [ memscreenpos/x 0 ]) (to-pair reduce [ memscreenpos/x gridsize/x]) line (to-pair reduce [ 0 memscreenpos/y ]) (to-pair reduce [ gridsize/x memscreenpos/y]) ]
				
			] on-mid-down [ 
				mmid: true
				mmdown: event/offset
				print [ "screen offset before drag..........: " memscreenoffset ]
			] on-over [
				if mmid [
					mmofs: event/offset - mmdown
					mmofs: memdragoffset + mmofs
				    screenoffset: screenscaleandoffset memscreenpos mmofs scl
			    	repeat t (length? trackstart) [
				    	tracklok/:t/1: scaleandoffset trackstart/:t/1 screenoffset scl
				    	tracklok/:t/2: scaleandoffset trackstart/:t/2 screenoffset scl
					]
					gridpos: scaleandoffset memscreenpos screenoffset scl
					clear face/draw
					foreach t tracklok [
						append face/draw compose [ pen 255.50.50 fill-pen 180.50.50 box (t/1) (t/2) ]
					]
					append face/draw compose [ fill-pen off ]
					append face/draw compose [ pen 0.255.0 line (event/offset) (mmdown) ]
			    	drawgrid face dragoffset
					drawdbg face memscreenpos gridpos
				]
			] on-mid-up [
				mmid: false
				memdragoffset: mmofs
				;memscreenoffset: 
				;memscreenscaleoffset: dragoffset
				print [ "screen offset after drag...........: " mmofs ]
			]
		] 
	]
	do [ t/offset: 0x0 p/offset: 0x0 gg1/offset: 0x0 ]
]
