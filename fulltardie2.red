Red [needs: 'view]

;; work-in-progress

;; ! = doing it. 
;; - = plan to do it next
;; ? = having problems, requested support.

;; TODO: [X] make save data orgmode-compatible instead of csv (for now)
;; TODO: [-] fix off-by one for entries starting on the 1st when today is the 2nd
;; TODO: [!] fix rounding on balance display in forcast
;; TODO: [!] investigate memory issues and random crashing
;; TODO: [ ] rename offset to period ? its not very clear what it does.
;; TODO: [-] replace headers with sort-buttons
;; TODO: [!] restore UI from FT1 & adapt to new data
;; TODO: [?] interactive graph: pan, zoom & fit
;; TODO: [?] nicer graph: color coding, stack overlapping, optional tooltip info
;; TODO: [ ] new params for forecast: start/end, filters, grouping, export
;; TODO: [ ] new params for graph: start/end, filters, color-coding.
;; TODO: [ ] csv export of rules
;; TODO: [ ] option to show next date in rule table
;; TODO: [ ] portable executable test - Linux
;; TODO: [ ] option to hold a forecasted transaction in a watch list (serves as a reminder/warning for overdue).
;; TODO: [ ] option to always hold transactions from setup (serves a reminder for non-automatic transactions).
;; TODO: [?] calendar tab
;; TODO: [ ] optimize
;; TODO: [ ] redify
;; TODO: [ ] audit

;; grab work-in-progress red from here : http://static.red-lang.org/dl/branch/GTK/linux/red-latest
;; Red-gtk is still all-kinds of busted as of writing, plus there's no sign of x64 Red... so this project is ultra low-priority.


lymd: function [cy] [
	;print["            lymd [cy]:" cy]
	ly: to-logic attempt [make date! [cy 2 29]]
	t: make vector! [31 28 31 30 31 30 31 31 30 31 30 31]
	if ly [poke t 2 29]
	t
]

savetd: function [d] [
	o: copy ""
	foreach r d [
		cs: copy ""
		foreach c r [
			append cs rejoin [c ";"]
		]
		append o rejoin [cs "^/"]
	]
	;probe o
	write/lines %saved.csv o
]

renderraw: function [d] [
	;print["    showrawdata: ... "]
	o: copy []
	foreach r d [
		append o (mold r)
	]
	o
]

sampledata: {|1|1|sunday|1|7|0|-5.00|every sunday of every month starting from this september|cat1|
|2|2|monday|1|0|0|-10.0|every 2nd and 4th monday of every month starting this month|cat2|
|1|6|thursday|3|2|0|-150.0|every last thursday of every 3rd month starting february|cat1|
|1|26|nowke|1|0|0|50.0|every weekday closest to the 26th of the month starting this month|cat1|
|1|33|0|12|2|0|-60.0|every last day of february|cat3|
|0|8|0|0|8|0|-300.0|next august 8th|cat4|
|0|9|nowke_b|1|11|0|15.0|every weekday before the 9th of every month starting november|cat3|
|14|14|nowke_a|1|0|0|45.0|every 14th and 28th day of every month or the following weekday if on a weekend|cat1|}

sd: split sampledata "^/"

notsaved: error? try [sd: read/lines %saved.org]

td: []
wkddat: ["0" "monday" "tuesday" "wednesday" "thursday" "friday" "saturday" "sunday" "nowke" "nowke_b" "nowke_a" ]

foreach s sd [
	dd: split s "|"
	if (length? dd) > 7 [
		dc: 1
		foreach ddd dd [
			replace dd dd/dc trim/head (trim/tail ddd)
			dc: dc + 1
		]
		remove-each itm dd [ itm = "" ]
		append/only td dd
	]
]

findnextdate: function [dt] [
	;print[ "		findnextdate triggered..." ]
	;probe dt
	allgood: true

	n: now/date
	o: copy []

	ofs: (to-integer dt/1)
	nth: (to-integer dt/2)
	ofm: (to-integer dt/4)
	fmo: (to-integer dt/5)
	fye: (to-integer dt/6)

	wkds: ["0" 0 "monday" 1 "tuesday" 2 "wednesday" 3 "thursday" 4 "friday" 5 "saturday" 6 "sunday" 7 "nowke" 8 "nowke_b" 9 "nowke_a" 10 ]
	wkd: select wkds dt/3

	if fmo = 0 [fmo: n/month]
	if fye = 0 [fye: n/year]
	fdy: now/day

	t: lymd fye
	md: pick t fmo
	if md < fdy [ fdy: md ]
	
	;probe fye
	;probe fmo
	;probe fdy
	
	a: make date! [fye fmo fdy]
	j: make date! [fye fmo fdy]
	dif: ( to-integer ((((now/date - a) / 7.0) / 52.0) * 12.0) ) + 12

	if allgood [
		loop dif [
			dmo: (a/month = fmo)
			if ofm > 0 [ dmo: ((a/month - fmo) % ofm = 0) ]
			if dmo [
				c: 0
				t: lymd a/year
				wdc: 0
				cdc: 0
				md: pick t a/month

				if (wkd = 0) or (wkd > 7) [ 
					mth: min nth md	
					if mth = 0 [ 
						;print[ "			found zero nth in " dt ]
						mth: now/day 
						;print[ "			setting mth to " mth ]
					]
				]

				repeat e md [
					j/day: e
					if j/weekday = wkd [ wdc: wdc + 1 ]
					if e = mth [ cdc: cdc + 1 ]
				]
				repeat d md [
					a/day: d
					chk: -1
					cwi: -2
					if (wkd > 0) and (wkd < 8) [
						if (a/weekday = wkd) [
							c: c + 1
							rem: (md - d)
							if (c >= ofs) or (rem < 8) [
								chk: (c % (min nth wdc))
								cwi: 0
							]
						]
					]
					if (wkd = 0) or (wkd > 7) [
						chk: 0
						cwi: (d % mth)
					]
					if chk = cwi [
						avd: d
						if a/weekday > 5 [
							case [
								wkd = 8 [ avd: to-integer (d + (((((a/weekday - 5) - 1) / 1.0) * 2.0) - 1.0)) ]
								wkd = 9 [ avd: d - (a/weekday - 5) ]
								wkd = 10 [ avd: d + (3 - (a/weekday - 5)) ]
							]
						]
						a/day: avd
						if a >= n [ 
							;print[ "				found next date " a ]
							append/only o reduce [a (to-float dt/7) dt/9 dt/8]
						]
						if ofs = 0 [ break ]
					]
				]
				a/day: 1
				j/day: 1
			]
			j/month: j/month + 1
			a/month: a/month + 1
		]
	]
	o
]

getforecast: function [d] [
	print[ "	getforecast triggered..." ]
	f: copy []
	foreach t d [
		;print[ "		checking row of data: " t ]
		nd: findnextdate t
		append f nd
	]
	sort/compare f func [a b] [
		case [
			a/1 < b/1 [-1] 
			a/1 > b/1 [1]
			a/1 = b/1 [0]
		]
	]
	rb: 0.0
	foreach r f [
		af: (to-float r/2)
		rb: rb + af
		append r rb
	]
	f
]

renderforecast: function [f] [
	print[ "	renderforecast triggered..." ]
	o: copy []
	t: copy []
	hh: copy/deep ["date" "amount" "category" "description" "balance"]
	insert/only f hh
	pads: copy/deep [ 0 0 0 0 0 ]
	rc: 1
	foreach r f [
		;print[ "		checking row : " r ]
		r/1: (to-string r/1)
		r/2: (to-string r/2)
		r/5: (to-string r/5)
		if rc > 1 [
			if (length? r/1) < 11 [ r/1: rejoin [ "0" r/1 ] ]
		]
		p: 1
		foreach c r [
			ml: (length? c) + 3
			if ml > (pick pads p) [
				poke pads p ml
			]
			p: p + 1
		]
		rc: rc + 1
	]
	;probe pads
	foreach r f [
		p: 1
		foreach c r [
		    pad c (pick pads p) 
			p: p + 1
		]
		g: rejoin r
		;print[ "			rendered row : " g ]
		append o g
	]
	o
]

getcats: function [d] [
	c: copy []
	foreach r d [
		tr: trim/head (trim/tail r/9)
		if (find c tr) = none [ append c tr ]
	]
	c
]

rendersrc: function [d] [
	print[ "	rendersrc triggered..." ]
	;print[ "		source data = " ]
	;probe d
	o: copy []
	hh: copy/deep ["offset" "nth day" "weekday" "nth month" "from month" "from year" "amount" "description" "category"]
	insert/only d hh
	pads: copy/deep [ 0 0 0 0 0 0 0 0 0 0 ]
	foreach r d [
		;print[ "		checking row : " r ]
		p: 1
		foreach c r [
			ml: (length? c) + 3
			;print[ "	        checking field length : " ml ]
			if ml > (pick pads p) [
				poke pads p ml
			]
			p: p + 1
		]
	]
	foreach r d [
		p: 1
		foreach c r [
			pad c (pick pads p)
			p: p + 1
		]
		g: rejoin r
		;print[ "		padded record: " g ]
		append o g
	]
	h: copy/deep o/1
	remove o
	out: reduce [o h]
	out
]

updateui: function [x] [
	rs: rendersrc copy/deep td
	srclist/data: rs/1
	srchead/data: rs/2
	srclist/selected: :x
	if tp/selected = 2 [
		print[ "forecast tab is selected: " tp/selected ]
		gf: getforecast copy/deep td
		forecastdata: renderforecast copy/deep gf
		forecasttab/data: forecastdata
	]
	if tp/selected = 3 [ 
		print[ "graph tab is selected: " tp/selected ]
		gf: getforecast copy/deep td
		graphit gf
	]
]

catdata: getcats copy/deep td
gf: getforecast copy/deep td
forecastdata: renderforecast copy/deep gf
rs: rendersrc copy/deep td
srcdata: rs/1
heddata: rs/2
rawdata: renderraw copy/deep td
;foreach p srcdata[ probe p ]
amsetting: true

graphit: function [d] [
	print["	graphit ... "]
	clear canvas/draw
	t: 1
	cx: canvas/size/x
	cy: canvas/size/y
	seg: cx  / 12
	mu: [1 "jan" 2 "feb" 3 "mar" 4 "apr" 5 "may" 6 "jun" 7 "jul" 8 "aug" 9 "sep" 10 "oct" 11 "nov" 12 "dec"]
	lyt: lymd now/year
	mmd: (to-float (pick lyt now/month))
	nd: (to-float now/day)
	;nuh: now/date
	;nuh/year: nuh/year + 1
	;rng: nuh/date - now/date
	mfac: (nd / mmd)
	oseg: (to-integer (seg * mfac))
	dayw: to-integer (cx / 365.0)
	;probe dayw
	append canvas/draw compose [pen 200.200.200]
	marks: make font! [size: 8 name: "Consolas" style: 'bold]
	append canvas/draw compose [font (marks)]
	loop 13 [
		ft: t - 1
		topleft: 1x0
		bottomright: 1x100
		topleft/x: reduce (ft * seg) - oseg
		bottomright/x: reduce (ft * seg) - oseg
		bottomright/y: reduce cy
		append canvas/draw compose [line (topleft) (bottomright)]
		ttp: 1x0
		xo: ((ft * seg) - oseg) + 5
		ttp/x: reduce xo
		ttp/y: reduce (cy - 12)
		n: now/month
		n: (((n + (t - 1)) - 1) % 12) + 1
		mo: select mu n
		append canvas/draw compose [text (ttp) (mo)]
		t: t + 1
	]
	append canvas/draw compose [pen 80.80.80]
    bct: 1
	mxv: 0.0
	foreach k d [
		kf: absolute to-float k/5
		if kf > mxv [ mxv: kf ] 
	]
	print[ "		graphit: max magnitude = " mxv ]
	foreach i d [
		cw: canvas/size/x
		ch: ch: canvas/size/y
		tval: i/5
		tdat: i/1
		trv: tdat - now/date
		;probe trv
		trv: trv / 365.0
		;probe trv
		trv: to-integer (trv * cw)
		;probe trv
		tdv: tval / mxv
		ch: ch * 0.5
		tdv: tdv * ch
		tdv: 0 - tdv
		tdv: tdv + ch
		ch: to-integer ch
		tdv: to-integer tdv
		topleft: 1x10
		bottomright: 1x200
		topleft/x: reduce trv
		topleft/y: reduce ch
		bottomright/x: reduce (trv + dayw)
		bottomright/y: reduce tdv
		append canvas/draw compose [box (topleft) (bottomright)]
		bct: bct + 1
	]
]

view [
	Title "test"
	below
	tp: tab-panel 1000x300 [
		"setup" [
			below
			srchead: field font-name "courier new" font-size 9 980x20 data heddata
			srclist: text-list font-name "courier new" font-size 9 980x220 data srcdata
			on-change [
				print["srclist: on-change triggered..."]
				amsetting: false
				x: srclist/selected
				;print[ "	srclist/selected = " x ]
				srow: copy/deep (pick td x)
				ofsetenter/text: srow/1
				nthenter/text: srow/2
				wkdenter/selected: index? find wkdenter/data srow/3
				nthmonthenter/text: srow/4
				frommonthenter/text: srow/5
				fromyearenter/text: srow/6
				amtenter/text: srow/7
				trname/text: srow/8
				catenter/selected: index? find catenter/data srow/9
				amsetting: true
			]
		]
		"forecast" [
			below
			forecasttab: text-list font-name "courier new" font-size 10 980x250 data forecastdata
		]
		"graph" [
  			below   
			canvas: base 980x220 white
			do [
				canvas/draw: copy []
			]
		]
		"raw data" [
			below
			rawlist: text-list font-name "courier new" font-size 9 980x250 data rawdata
		]
		"calendar" [
			across
			text "year"
		    calyear: field 100x20 
			text "month"
			calprev: button 40x20 "<" 
			caltoday: button 65x20 "this month" 
			calnext: button 40x20 ">" 
		]
	]
	on-change [
		if event/picked = 2 [
			print[ "forecasttab is selected: " tp/selected ]
			gf: getforecast copy/deep td
			forecastdata: renderforecast copy/deep gf
			forecasttab/data: forecastdata
		]
		if event/picked = 3 [
			graphit gf
		]
	]
	sp: panel 1000x200 [
		across
		text "description" right
		trname: field 400x20
		on-change [
			if amsetting [
				print[ "trname: on-enter triggered..." ]
				x: srclist/selected
				print[ "renaming " td/:x/8 " to " trname/text ]
				td/:x/8: trname/text
				updateui x
			]
		]
		text "amount" right
		amtenter: field
		on-change [
			if amsetting [
				print[ "amtenter: on-enter triggered..." ]
				x: srclist/selected
				td/:x/7: amtenter/text
				updateui x
			]
		]
		text "category" right
		catenter: drop-down 100x20 data catdata
		on-change [
			if amsetting [
				print[ "catenter: on-change triggered..." ]
				x: srclist/selected
				td/:x/9: catenter/text
				updateui x
			]
		]
		return
		text "offset" right
		ofsetenter: field
		on-change [
			if amsetting [
				print[ "ofsetenter: on-enter triggered..." ]
				x: srclist/selected
				print[ "changing " td/:x/1 " to " face/text ]
				td/:x/1: face/text
				updateui x
			]
		]
		nthlabel: text "nth day" right
		nthenter: field
		on-change [
			if amsetting [
				print[ "nthenter: on-enter triggered..." ]
				x: srclist/selected
				td/:x/2: nthenter/text
				updateui x
			]
		]
		text "weekday" right		
		wkdenter: drop-list 100x20 data wkddat
		on-change [
			if amsetting [
				print[ "wkdenter: on-change triggered..." ]
				x: srclist/selected
				selfname: pick face/data face/selected
				print[ "	changing " td/:x/3 " to " selfname ]
				td/:x/3: selfname
				updateui x
			]
		]
		return
		text "nth month" right
		nthmonthenter: field
		on-change [
			if amsetting [
				print[ "nthmonthenter: on-enter triggered..." ]
				x: srclist/selected
				td/:x/4: face/text
				updateui x
			]
		]
		text "from month" right
		frommonthenter: field
		on-change [
			if amsetting [
				print[ "frommonthenter: on-enter triggered..." ]
				x: srclist/selected
				td/:x/5: face/text
				updateui x
			]
		]
		text "from year" right
		fromyearenter: field
		on-change [
			if amsetting [
				print[ "fromyearenter: on-enter triggered..." ]
				x: srclist/selected
				td/:x/6: face/text
				updateui x
			]
		]
		;space 100x0
		;saveit: button "save all transactions" [savetd td]
	]
]
