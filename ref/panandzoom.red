Red [ needs 'view ]

;; mouse zooming experiment
;; panels always scale from 0x0 regardless of where you put them, so doing it the hard way...

scrpos: 0x0
grdpos: 0x0
coo: 400x400
corg: 0x0
mco: 0x0
scl: [ 1.0 1.0 ]

offsetlock: function [ p o s ] [
    p/x: to-integer (p/x * s/1)
    p/y: to-integer (p/y * s/2)
    p/x: p/x - (to-integer (o/x))
    p/y: p/y - (to-integer (o/y))
	p
]

view/tight [
	t: panel 400x400 [
		below
		p: panel 400x400 30.30.80 draw [ ] [
			gg1: panel 400x400 30.30.30 draw [ ] on-wheel [
				either event/picked > 0 [
				    scl/1: min (scl/1 + 0.1) 10.0
					scl/2: min (scl/2 + 0.1) 10.0
				] [
					scl/1: max (scl/1 - 0.1) 1.0 
					scl/2: max (scl/2 - 0.1) 1.0 
				]
				
			    coo/x: to-integer ( 400.0 * scl/1)
				coo/y: to-integer (400.0 * scl/2)
				print [ "scaled grid size: " coo ]

				scrofs: 0x0
				scrofs/x: to-integer (scrpos/x * scl/1)
				scrofs/y: to-integer (scrpos/y * scl/2)
				print [ "screen pos offset: " scrofs ]

				grdofs: 0x0
				grdofs/x: to-integer (grdpos/x * scl/1)
				grdofs/y: to-integer (grdpos/y * scl/2)
				print [ "grid pos offset: " grdofs ]

				lokofs: to-pair reduce [ (grdofs/x - scrpos/x) (grdofs/y - scrpos/y) ]

				trkpos: offsetlock 100x100 lokofs scl

				clear face/draw

				append face/draw compose [ pen 255.50.50 circle (trkpos) (10 * scl/1) (10 * scl/2) ]

				gwdth: 25
				gspcx: gwdth * scl/1
				gnumx: (to-integer (coo/x / gspcx))
				print [ "x gridlines: " gnumx ]
				gspcy: 25.0 * scl/2
				gnumy: (to-integer (coo/y / gspcy))
				print [ "y gridlines: " gnumy ]
				gf: make font! [size: 8 name: "Consolas" color: 180.180.180 ]
			    append face/draw compose [ font (gf) ]
				print [ "50x50 in grid space is: " (to-pair reduce [ (to-integer (2 * gspcx)) (to-integer (2 * gspcy)) ]) ]
				print [ "offset of 50x50 is: " (offsetlock to-pair reduce [ (to-integer (2 * gspcx)) (to-integer (2 * gspcy)) ] lokofs scl) ]
				repeat i (max gnumx gnumy) [
					ix: offsetlock to-pair reduce [ (to-integer (i * gwdth)) (to-integer (i * gwdth)) ] lokofs scl
					;ix: to-pair reduce [ (to-integer (i * gspcx)) (to-integer (i * gspcy)) ]
					gtx: to-pair reduce [ ix/x 5 ]
					gty: to-pair reduce [ 5 ix/y ]
					glxa: to-pair reduce [ ix/x 0 ]
					glxb: to-pair reduce [ ix/x coo/y ]
					glya: to-pair reduce [ 0 ix/y ]
					glyb: to-pair reduce [ coo/x ix/y ]
					either (i % 2) = 0 [
						append face/draw compose [ 
							pen 50.50.50 
							line (glxa) (glxb) 
							line (glya) (glyb)
							text (gtx) (rejoin reduce [ (to-integer (gwdth * i)) ])
							text (gty) (rejoin reduce [ (to-integer (gwdth * i)) ])
						]
					] [
						append face/draw compose/deep [ 
							pen 40.40.40 
							line (glxa) (glxb) 
							line (glya) (glyb)
						]
					]
				]

				tfx: 5
				if ((coo/x - scrpos/x) < 150) [ tfx: -155 ]
				tc: to-pair reduce [ (tfx) 5 ]
				tf: make font! [size: 10 name: "Consolas" style: 'bold]
				append face/draw compose [ font (tf) ]
				append face/draw compose [ 
					pen 80.80.255  
					line (to-pair reduce [ scrpos/x 0 ]) (to-pair reduce [ scrpos/x coo/y]) line (to-pair reduce [ 0 scrpos/y ]) (to-pair reduce [ coo/x scrpos/y]) 
					text (scrpos + tc) (rejoin reduce [ "screen mark : " (scrpos/x) "x" (scrpos/y) ])
				]

				tf: make font! [size: 10 name: "Consolas" style: 'bold color: 80.255.80 anti-alias? true]
				append face/draw compose [ font (tf) ]
				append face/draw compose [ 
					pen 0.255.0 
					text (scrpos + tc + 0x15) (rejoin reduce [ "screen offset before trans: " (grdofs/x - scrpos/x) "," (grdofs/y - scrpos/y) ])
				]

				tf: make font! [size: 10 name: "Consolas" style: 'bold color: 255.80.255 anti-alias? true]
				append face/draw compose [ font (tf) ]
				append face/draw compose [ 
					text (scrpos + tc + 0x30) (rejoin reduce [ "scaled mark : " (grdofs/x) "x" (grdofs/y) ])
				]

				ofgl: offsetlock scrpos lokofs scl
				if ((coo/x - ofgl/x) < 150) [ tfx: -155 ]
				tc: to-pair reduce [ (tfx) 5 ]
				tf: make font! [size: 10 name: "Consolas" style: 'bold color: 255.255.80 anti-alias? true]
				append face/draw compose [ font (tf) ]
				append face/draw compose [ 
					pen 255.255.0 
					line (to-pair reduce [ ofgl/x 0 ]) (to-pair reduce [ ofgl/x coo/y ])
					line (to-pair reduce [ 0 ofgl/y ]) (to-pair reduce [ coo/x ofgl/y ])
					text (ofgl + tc + 0x45) (rejoin reduce [ "grid lock : " (grdpos/x) "x" (grdpos/y) ])
				]
				tf: make font! [size: 16 name: "Consolas" style: 'bold color: 80.80.80 anti-alias? true]
				append face/draw compose [ font (tf) ]
				append face/draw compose [
					text (to-pair reduce [ (face/size/x - 220) (face/size/y - 40)  ]) (rejoin reduce [ "zoom: " (round/to scl/1 0.1) " x " (round/to scl/2 0.1) ])
				]

			] on-down [
				scrpos: to-pair reduce [ (to-integer (1.0 * event/offset/x)) (to-integer (1.0 * event/offset/y)) ]
				grdpos: to-pair reduce [ (to-integer (event/offset/x / scl/1)) (to-integer (event/offset/y / scl/2)) ]
				print [ "grid scale is.....: " scl ]
				print [ "screen position is: " scrpos ]
				print [ "grid position is..: " grdpos ]
				mco: coo
				append face/draw compose [ pen 0.0.255 line (to-pair reduce [ scrpos/x 0 ]) (to-pair reduce [ scrpos/x coo/y]) line (to-pair reduce [ 0 scrpos/y ]) (to-pair reduce [ coo/x scrpos/y]) ]
			]
		] 
	]
	do [ t/offset: 0x0 p/offset: 0x0 gg1/offset: 0x0 ]
]
