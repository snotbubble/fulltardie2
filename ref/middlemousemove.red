Red [ needs 'view ]
mmid: false
view/tight [
	t: panel 400x400 [
	    c: panel 400x400 128.40.40 all-over draw [ ] on-mid-down [
			append face/draw compose [ pen off fill-pen 255.255.80 ]
			mmid: true
		] on-over [
			if mmid [ 
				append face/draw compose [ circle (event/offset) 5 5 ]
			]
		] on-mid-up [ mmid: false clear face/draw ]
	]
	do [ t/offset: 0x0 c/offset: 0x0 ]
]
