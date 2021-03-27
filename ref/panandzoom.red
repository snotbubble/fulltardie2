Red [ needs 'view ]

tra: 0x0
coo: 400x400
mco: 0x0

view/tight [
	t: panel 400x400 [
		below
		p: panel 400x400 30.30.80 draw [ ] [
			gg1: panel 400x400 30.30.30 draw [ ] on-wheel [
				fx: coo/x
				fy: coo/y
				either event/picked > 0 [
				    fx: min (coo/x + 10) 2000
					fy: min (coo/y + 10) 2000
				] [
					fx: max (coo/x - 10) 100 
					fy: max (coo/y - 10) 100 
				]
				
			    coo: to-pair reduce [ fx fy ]
				sfacx: (coo/x / 400.0)
				sfacy: (coo/y / 400.0)
				probe coo
				ofs: to-pair reduce [ (to-integer (tra/x * (fx / mco/x))) (to-integer (tra/y * (fy / mco/y))) ]

				clear face/draw
				gspc: 25.0 * (coo/x / 400.0)
				gnum: (to-integer (coo/x / gspc))
				print [ "gridlines: " gnum ]
				probe coo/x
				gf: make font! [size: 8 name: "Consolas" color: 180.180.180 ]
			    append face/draw compose [ font (gf) ]
				repeat i (gnum - 1) [
					either (i % 2) = 0 [
						gtx: to-pair reduce [ (to-integer (i * gspc)) 5 ]
						gty: to-pair reduce [ 5 (to-integer (i * gspc)) ]
						append face/draw compose [ 
							pen 50.50.50 
							line (to-pair reduce [ (to-integer (i * gspc)) 0 ]) (to-pair reduce [ (to-integer (i * gspc)) coo/y ]) 
							line (to-pair reduce [ 0 (to-integer (i * gspc)) ]) (to-pair reduce [ coo/x (to-integer (i * gspc)) ])
							text (gtx) (rejoin reduce [ (to-integer (25 * i)) ])
							text (gty) (rejoin reduce [ (to-integer (25 * i)) ])
						]
					] [
						append face/draw compose/deep [ 
							pen 40.40.40 
							line (to-pair reduce [ (to-integer (i * gspc)) 0 ]) (to-pair reduce [ (to-integer (i * gspc)) coo/y ]) 
							line (to-pair reduce [ 0 (to-integer (i * gspc)) ]) (to-pair reduce [ coo/x (to-integer (i * gspc)) ])
						]
					]
				]

				tfx: 5
				if ((fx - tra/x) < 150) [ tfx: -155 ]
				tc: to-pair reduce [ (tfx) 5 ]
				tf: make font! [size: 10 name: "Consolas" style: 'bold]
				append face/draw compose [ font (tf) ]
				append face/draw compose [ 
					pen 80.80.255  
					line (to-pair reduce [ tra/x 0 ]) (to-pair reduce [ tra/x coo/y]) line (to-pair reduce [ 0 tra/y ]) (to-pair reduce [ coo/x tra/y]) 
					text (tra + tc) (rejoin reduce [ "on-down : " (tra/x) "x" (tra/y) ])
				]

				if ((fx - tra/x) < 150) [ tfx: -155 ]
				tc: to-pair reduce [ (tfx) 5 ]
				append face/draw compose [ font (tf) ]
				append face/draw compose [ 
					pen 0.255.0 
					line (to-pair reduce [ ofs/x ofs/y ]) (to-pair reduce [ tra/x tra/y ])
					text (ofs + tc - 0x30) (rejoin reduce [ "ofs : " (ofs/x) "x" (ofs/y) ])
				]

				if ((fx - ofs/x) < 150) [ tfx: -155 ]
				tc: to-pair reduce [ (tfx) 5 ]
				append face/draw compose [ font (tf) ]
				append face/draw compose [ 
					pen 255.0.255 
					line (to-pair reduce [ ofs/x 0 ]) (to-pair reduce [ ofs/x face/size/y ])
					line (to-pair reduce [ 0 ofs/y ]) (to-pair reduce [ face/size/x ofs/y ])
					text (ofs + tc) (rejoin reduce [ "locked : " (to-integer (ofs/x * sfacx)) "x" (to-integer (ofs/y * sfacy)) ])
				]
			] on-down [
				sfacx: (coo/x / 400.0)
				sfacy: (coo/y / 400.0)
				print [ "current coord scale factor : " sfacx ]
				print [ "complemented scale factor : " (1.0 / sfacx) ]
				tra: to-pair reduce [ (to-integer (1.0 * event/offset/x)) (to-integer (1.0 * event/offset/y)) ]
				print [ "marked coords: " tra ]
				mco: coo
				append face/draw compose [ pen 0.0.255 line (to-pair reduce [ tra/x 0 ]) (to-pair reduce [ tra/x coo/y]) line (to-pair reduce [ 0 tra/y ]) (to-pair reduce [ coo/x tra/y]) ]
			]
		] 
	]
	do [ t/offset: 0x0 p/offset: 0x0 gg1/offset: 0x0 ]
]
