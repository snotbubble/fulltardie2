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
	print [ "old pos = " p ]
	print [ "marker == " m ]
   	print [ "scale === " s ]
	o/x: to-integer (((p/x - m/x) * s/1) + m/x)
	o/y: to-integer (((p/y - m/y) * s/2) + m/y)
	o
]

scaleup: function [ p m s ] [
	o: 0x0
	o/x: to-integer ((p/x * s/1) - m/x)
	o/y: to-integer ((p/y * s/2) - m/y)
	o
]

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

drawdbg: func [ p sp pp zp pzp dp dz dpz ] [
	tf: make font! [size: 10 name: "Consolas" style: 'bold]
	append p/draw compose [ font (tf) ]
	append p/draw compose [ 
		pen 80.80.255  
		line (to-pair reduce [ sp/x 0 ]) (to-pair reduce [ sp/x gridsize/y]) line (to-pair reduce [ 0 sp/y ]) (to-pair reduce [ gridsize/x sp/y]) 
		text (sp) (rejoin reduce [ "screen mark in screenspace : " (sp/x) "x" (sp/y) ])
	]
	if dp [
		tf: make font! [size: 10 name: "Consolas" style: 'bold color: 80.255.80 anti-alias? true]
		append p/draw compose [
			pen 0.255.0
			line-width 1
			line (to-pair reduce [ pp/x 0 ]) (to-pair reduce [ pp/x gridsize/y ])
			line (to-pair reduce [ 0 pp/y ]) (to-pair reduce [ gridsize/x pp/y ])
		]
		append p/draw compose [ font (tf) ]
		append p/draw compose [ 
			pen 0.255.0 
			text (pp) (rejoin reduce [ "screen mark after pan: " (pp/x) "," (pp/y) ])
		]
	]

	if dz [
		tf: make font! [size: 10 name: "Consolas" style: 'bold color: 80.255.80 anti-alias? true]
		append p/draw compose [
			pen 255.255.0
			line-width 1
			line (to-pair reduce [ zp/x 0 ]) (to-pair reduce [ zp/x gridsize/y ])
			line (to-pair reduce [ 0 zp/y ]) (to-pair reduce [ gridsize/x zp/y ])
		]
		append p/draw compose [ font (tf) ]
		append p/draw compose [ 
			pen 255.255.0 
			text (zp) (rejoin reduce [ "screen mark after zoom: " (zp/x) "," (zp/y) ])
		]
	]

	if dpz [
		tf: make font! [size: 10 name: "Consolas" style: 'bold color: 255.80.80 anti-alias? true]
		append p/draw compose [ font (tf) ]
		append p/draw compose [
			pen 255.255.255
			line-width 3
			line (to-pair reduce [ pzp/x 0 ]) (to-pair reduce [ pzp/x gridsize/y ])
			line (to-pair reduce [ 0 pzp/y ]) (to-pair reduce [ gridsize/x pzp/y ])
			text (sp) (rejoin reduce [ "screen mark after pan and zoom : " (pzp/x) "x" (pzp/y) ])
		]
	]
]

drawzoom: function [ p ] [
	tf: make font! [size: 16 name: "Consolas" style: 'bold color: 80.80.80 anti-alias? true]
	append p/draw compose [ font (tf) ]
	append p/draw compose [
		text (to-pair reduce [ (p/size/x - 220) (p/size/y - 40)  ]) (rejoin reduce [ "zoom: " (round/to scl/1 0.1) " x " (round/to scl/2 0.1) ])
	]
]

drawvars: function [ p ] [
	tf: make font! [size: 10 name: "Consolas" style: 'bold color: 80.80.80 anti-alias? true]
	append p/draw compose [ font (tf) ]
	append p/draw compose [
		text (to-pair reduce [ (30) (p/size/y - 70)  ]) (rejoin reduce [ "sp:" (sp) " msp: " (msp) " so: " (so) ])
	]
]

view/tight [
	t: panel 400x400 [
		below
		p: panel 400x400 30.30.80 draw [ ] [
			gg1: panel 400x400 30.30.30 all-over draw [ ] on-wheel [
				sp: event/offset
				scldw: false
				scl/1: 1.0
				scl/2: 1.0
				either event/picked > 0 [
				    scl/1: min (scl/1 + 0.1) 10.0
					scl/2: min (scl/2 + 0.1) 10.0
				] [
					scl/1: max (scl/1 - 0.1) 0.1 
					scl/2: max (scl/2 - 0.1) 0.1
					scldw: true
				]
				gscl/1: gscl/1 + scl/1
				gscl/2: gscl/2 + scl/2

			    ;zo/x: to-integer ((sp/x - msp/x) * 0.5)
			    ;zo/y: to-integer ((sp/y - msp/y) * 0.5)

			    ;zo/x: to-integer ((sp/x - msp/x) * 0.5) + mso/x
			    ;zo/y: to-integer ((sp/y - msp/y) * 0.5) + mso/y

				;zo: mso

				;so/x: to-integer ((msp/x - zo/x) * scl/1) - msp/x
				;so/y: to-integer ((msp/y - zo/y) * scl/2) - msp/y

				;rsp: to-pair reduce [ (msp/x * (1.0 / scl/1)) (msp/y * (1.0 / scl/2)) ] 

				;so/x: to-integer (msp/x * scl/1) - msp/x
				;so/y: to-integer (msp/y * scl/2) - msp/y


			    ;repeat t (length? trackstart) [
				;    tracklok/:t/1: (trackstart/:t/1 * scl/1 ) - so/x
				;    tracklok/:t/2: (trackstart/:t/2 * scl/2 ) - so/y
				;]

				bi: zoomit oldbi msp scl 
			    bx: zoomit oldbx msp scl 
				clear face/draw
				ff: make font! [size: 8 name: "Consolas" style: 'bold color: 220.50.50 anti-alias? true]
				bf: make font! [size: 8 name: "Consolas" style: 'bold color: 150.20.20 anti-alias? true]
				append face/draw compose [
				    pen 255.50.50 box (bi) (bx)
					pen 150.20.20 box (oldbi) (oldbx)
					line (to-pair reduce [ oldbi/x oldbi/y ]) (to-pair reduce [ bi/x bi/y ])
					line (to-pair reduce [ oldbi/x oldbx/y ]) (to-pair reduce [ bi/x bx/y ])
					line (to-pair reduce [ oldbx/x oldbi/y ]) (to-pair reduce [ bx/x bi/y ])
					line (to-pair reduce [ oldbx/x oldbx/y ]) (to-pair reduce [ bx/x bx/y ])
				]
				append face/draw compose [
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
				append face/draw compose [
					pen 0.0.255
					line-width 1
					line (to-pair reduce [ msp/x 0 ]) (to-pair reduce [ msp/x 400 ])
					line (to-pair reduce [ 0 msp/y ]) (to-pair reduce [ 400 msp/y ])
				]
				;foreach t tracklok [
				;	append face/draw compose [ pen 255.50.50 fill-pen 180.50.50 box (t/1) (t/2) ]
				;]

				drawzoom face
			    oldbi: bi
				oldbx: bx

			] on-down [
				;msp: event/offset
				msp: to-pair reduce [ (round/to event/offset/x 10) (round/to event/offset/y 10) ]
				append face/draw compose [
					pen 0.0.255
					line-width 1
					line (to-pair reduce [ msp/x 0 ]) (to-pair reduce [ msp/x 400 ])
					line (to-pair reduce [ 0 msp/y ]) (to-pair reduce [ 400 msp/y ])
				]
			] on-mid-down [ 
				mmid: true
				mmdown: event/offset
			] on-over [
				if mmid [
				    dso: (event/offset - mmdown)
					;dso/x: msp/x - (to-integer dso/x)
					;dso/y: msp/y - (to-integer dso/y)
					;bi: zoomit oldbi dso [ 1 1 ]
					;bx: zoomit oldbx dso [ 1 1 ]
					bi: oldbi + dso
					bx: oldbx + dso
					clear face/draw
					ff: make font! [size: 8 name: "Consolas" style: 'bold color: 220.50.50 anti-alias? true]
					bf: make font! [size: 8 name: "Consolas" style: 'bold color: 150.20.20 anti-alias? true]
					append face/draw compose [
						pen 255.50.50 box (bi) (bx)
						pen 150.20.20 box (oldbi) (oldbx)
						line (to-pair reduce [ oldbi/x oldbi/y ]) (to-pair reduce [ bi/x bi/y ])
						line (to-pair reduce [ oldbi/x oldbx/y ]) (to-pair reduce [ bi/x bx/y ])
						line (to-pair reduce [ oldbx/x oldbi/y ]) (to-pair reduce [ bx/x bi/y ])
						line (to-pair reduce [ oldbx/x oldbx/y ]) (to-pair reduce [ bx/x bx/y ])
					]
					append face/draw compose [
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
					append face/draw compose [
						pen 0.0.255
						line-width 1
						line (to-pair reduce [ msp/x 0 ]) (to-pair reduce [ msp/x 400 ])
						line (to-pair reduce [ 0 msp/y ]) (to-pair reduce [ 400 msp/y ])
					]
					drawzoom face
				]
			] on-mid-up [
				mmid: false
				mso: dso
			    oldbi: bi
				oldbx: bx
			]
		] 
	]
	do [ t/offset: 0x0 p/offset: 0x0 gg1/offset: 0x0 ]
]
