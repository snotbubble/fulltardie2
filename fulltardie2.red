Red [needs: 'view]

;; work-in-progress
;; unless there's a compiled binary, assume this is all kinds of broken
;;
;; 32-bit only! don't use if polluting your system with 32-bit libraries isn't an option.
;; I'm investigating other languages for 64-bit. R3 is promising, but the UI looks like ass and Draw isn't suitable for UI widgets... not without adding a massive amount of complexity in any case.
;;
;; there's a good chance I'll abandon this if the IOS version is relatively painless to use... ui vs screen-space is the only hurdle atm.



;; ! : doing it
;; ? : having problems with it
;; - : dropped it
;;
;; TODO: [!] fix issues cause by the new data structure
;; TODO: [!] handle simple day-counting in findnextdate
;; TODO: [ ] start plain-english translator




lymd: function [ cy tabi tabf ] [
;; this gets pounded by the forecast, disabled print until its optimized
	;print [ tabi "lymd function triggered by " tabf "..." ]
	ly: to-logic attempt [make date! [cy 2 29]]
	t: make vector! [31 28 31 30 31 30 31 31 30 31 30 31]
	if ly [poke t 2 29]
	;print [ tabi "lmyd function is done." ]
	t
]

savetd: function [ d tabi tabf ] [
	print [ tabi "savetd function triggered by " tabf "..." ]
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
	print [ tabi "savetd function is done." ]
]

renderraw: function  [d tabi tabf ] [
	print[ tabi "renderraw function triggered by " tabf "..." ]
	o: copy []
	foreach r d [
		append o (mold r)
	]
	print [ tabi "renderraw function is done." ]
	o
]

;; weekdays data = 0: nothing, 1~7: weekdays starting monday, 8: no weekend, 9: weekday-before weekend, 10: weekday after weekend
;; Its tempting to store it as a block and "do" it when loading, but the data needs to be compatible with a swift project (IOS) and org.

;; structure is:
;; 1 every nth
;; 2 nth day
;; 3 weekday
;; 4 nth month
;; 5 from month
;; 6 from year
;; 7 amount
;; 8 category
;; 9 group (not used at the moment)
;; 10 description

;; example:
;; | 1 | 1 | 7 | 1 | 7 | 0 |
;; | every 1 | 1 day | sunday | every 1 month | september | year 0 (this year) |
;; = every single, each day of, sunday, of every month, starting from september, this year
;; = every sunday of the month starting next september.

;; example:
;; | 14 | 14 | 10 | 1 | 0 | 0 |
;; |every 14 | 14 days | weekday after | every 1 month | month 0 (this month) | year 0 (this year) |
;; = every 14th, 14th weekday or next after, of every month, starting from this month, starting from this year 
;; = the weekday on or after the 14th and 28th of every month from now.

sampledata: {|eac|ntd|wkd|ntm|mth|yea|amt|cat|grp|description|
|1|1|7|1|7|0|-5.00|cat1|grp1|every sunday of every month starting from this september|
|2|2|1|1|0|0|-10.0|cat2|grp1|every 2nd and 4th monday of every month starting this month|
|1|6|4|3|2|0|-150.0|cat3|grp1|every last thursday of every 3rd month starting february|
|1|26|8|1|0|0|50.0|cat4|grp2|every weekday closest to the 26th of the month starting this month|
|1|33|0|12|2|0|-60.0|cat1|grp2|every last day of february|
|0|8|0|0|8|0|-300.0|cat2|grp3|next august 8th|
|0|9|9|1|11|0|15.0|cat3|grp3|every weekday before the 9th of every month starting november|
|14|14|10|1|0|0|45.0|cat4|grp3|every 14th and 28th day of every month or the following weekday if on a weekend|}

sd: split sampledata "^/"

notsaved: error? try [sd: read/lines %saved.org]

td: []

repeat s (length? sd) [
	if s > 1 [
		dd: split sd/:s "|"
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
]

findnextdate: function [ dt tabi tabf ] [
	print[ tabi "findnextdate function triggered by " tabf "..." ]
	;probe dt
	allgood: true

	n: now/date
	o: copy []

	ofs: (to-integer dt/1)
	nth: (to-integer dt/2)
	ofm: (to-integer dt/4)
	fmo: (to-integer dt/5)
	fye: (to-integer dt/6)

	wkd: (to-integer dt/3)

	if fmo = 0 [fmo: n/month]
	if fye = 0 [fye: n/year]
	fdy: now/day

	t: lymd fye rejoin [ tabi "^-" ] "findnextdate"
	md: pick t fmo
	if md < fdy [ fdy: md ]
	
	;probe fye
	;probe fmo
	;probe fdy
	
	a: make date! [fye fmo fdy]
	j: make date! [fye fmo fdy]
	dif: ( to-integer ((((now/date - a) / 7.0) / 52.0) * 12.0) ) + 12
	;;print [ tabi "^-dif = " dif ]
	if allgood [
		loop dif [
			dmo: (a/month = fmo)
			if ofm > 0 [ dmo: ((a/month - fmo) % ofm = 0) ]
			if dmo [
				c: 0
				t: lymd a/year rejoin [ tabi "^-" ] "findnextdate"
				wdc: 0
				cdc: 0
				md: pick t a/month

				if (wkd = 0) or (wkd > 7) [ 
					mth: min nth md	
					if mth = 0 [ 
						;print[ tabi "found zero nth in " dt ]
						mth: now/day 
						;print[ tabi "setting mth to " mth ]
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
							;print[ tabi "^-found next date " a ]
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
	print [ tabi "findnextdate function is done." ]
	o
]

getforecast: function [ d tabi tabf ] [
	print[ tabi "getforecast triggered by " tabf "..." ]
	f: copy []
	foreach t d [
		;print[ tabi "^-checking row of data: " t ]
		nd: findnextdate t rejoin [ tabi "^-"] "getforecast"
		append f nd
	]
	sort/compare f func [a b] [
;; the GTK text list reverses its data, so the sort is reversed to compensate!
		case [
			a/1 > b/1 [-1] 
			a/1 < b/1 [1]
			a/1 = b/1 [0]
		]
	]
	rb: 0.0
	foreach r f [
		af: (to-float r/2)
		rb: rb + af
		append r rb
	]
	print[ tabi "getforecast function is done. " ]
	f
]

renderforecast: function [ f tabi tabf ] [
	print[ tabi "renderforecast triggered by " tabf "..." ]
	o: copy []
	t: copy []
	hh: copy/deep ["date" "amount" "category" "description" "balance"]
	insert/only f hh
	pads: copy/deep [ 0 0 0 0 0 ]
	rc: 1
	foreach r f [
		;print[ tabi "^-checking row : " r ]
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
		;print[ tabi "^-rendered row : " g ]
		append o g
	]
	print [ tabi "renderforecast function is done." ] 
	o
]

getcats: function [ d tabi tabf ] [
	print [ tabi "getcats function triggered by " tabf "..." ]
	c: copy []
	foreach r d [
		tr: trim/head (trim/tail r/8)
		if (find c tr) = none [ append c tr ]
	]
	print [ tabi "getcats function is done." ] 
	c
]

rendersrc: function [d tabi tabf ] [
	print[ tabi "rendersrc triggered by " tabf "..." ]
	o: copy []
	hh: copy/deep ["offset" "nth day" "weekday" "nth month" "from month" "from year" "amount" "description" "category"]
	insert/only d hh
	pads: copy/deep [ 0 0 0 0 0 0 0 0 0 0 ]
	foreach r d [
		;print[ "		checking row : " r ]
		p: 1
		foreach c r [
			ml: (length? c) + 3
			;print[ tabi "^-checking field length : " ml ]
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
		;print[ tabi "^-padded record: " g ]
		append o g
	]
	h: copy/deep o/1
	remove o
	out: reduce [o h]
	print [ tabi "rendersrc function is done." ]
	out
]

updateui: function [ x tabi tabf ] [
	print [ tabi "updateui function triggered by " tabf "..." ]
	rs: rendersrc copy/deep td
	srclist/data: rs/1
	srchead/data: rs/2
	srclist/selected: :x
	if tp/selected = 2 [
		print[ tabi "^-forecast tab is selected: " tp/selected ]
		gf: getforecast copy/deep td rejoin [ tabi "^-" ] "updateui"
		forecastdata: renderforecast copy/deep gf
		forecasttab/data: forecastdata
	]
	if tp/selected = 3 [ 
		print[ tabi "^-graph tab is selected: " tp/selected ]
		gf: getforecast copy/deep td rejoin [ tabi "^-" ] "updateui"
		graphit gf
	]
	print [ tabi "updateui function is done." ]
]

catdata: getcats copy/deep td "^-" "initial_forecast"
gf: getforecast copy/deep td "^-" "initial_forecast"
forecastdata: renderforecast copy/deep gf "^-" "initial_forecast"
rs: rendersrc copy/deep td "^-" "initial_forecast"
srcdata: rs/1
heddata: rs/2
rawdata: renderraw copy/deep td "^-" "initial_forecast"
;foreach p srcdata[ probe p ]
amsetting: true

graphit: function [ d tabi tabf ] [
	print [ tabi "graphit function triggered by " tabf "..." ]
	clear canvas/draw
	t: 1
	cx: canvas/size/x
	cy: canvas/size/y
	seg: cx  / 12
	mu: [1 "jan" 2 "feb" 3 "mar" 4 "apr" 5 "may" 6 "jun" 7 "jul" 8 "aug" 9 "sep" 10 "oct" 11 "nov" 12 "dec"]
	lyt: lymd now/year rejoin [ tabi "^-" ] "graphit"
	mmd: (to-float (pick lyt now/month))
	nd: (to-float now/day)
	;nuh: now/date
	;nuh/year: nuh/year + 1
	;rng: nuh/date - now/date
	mfac: (nd / mmd)
	oseg: (to-integer (seg * mfac))
	dayw: to-integer (cx / 365.0)
	append canvas/draw compose [pen 200.200.200]
	marks: make font! [size: 8 name: "Consolas" style: 'bold]
	append canvas/draw compose [font (marks)]
	loop 13 [
		ft: t - 1
		topleft: 1x0
		bottomright: 1x100
		topleft/x: to-integer ((ft * seg) - oseg)
		bottomright/x: to-integer ((ft * seg) - oseg)
		bottomright/y: cy
		append canvas/draw compose [line (topleft) (bottomright)]
		ttp: 1x0
		xo: to-integer (((ft * seg) - oseg) + 5)
		ttp/x: xo
		ttp/y: (cy - 12)
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
	print[ tabi "^-graphit: max magnitude = " mxv ]
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
	print [ tabi "graphit function is done." ]
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
				trname/text: srow/10
				catenter/selected: index? find catenter/data srow/8
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
			gf: getforecast copy/deep td "^-" "tab-panel_change_event"
			forecastdata: renderforecast copy/deep gf "^-" "tab-panel_change_event"
			forecasttab/data: forecastdata "^-" "tab-panel_change_event"
		]
		if event/picked = 3 [
			graphit gf "^-" "tab-panel_change_event"
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
				updateui x "^-" "trname_change_event"
			]
		]
		text "amount" right
		amtenter: field
		on-change [
			if amsetting [
				print[ "amtenter: on-enter triggered..." ]
				x: srclist/selected
				td/:x/7: amtenter/text
				updateui x "^-" "amtenter_change_event"
			]
		]
		text "category" right
		catenter: drop-down 100x20 data catdata
		on-change [
			if amsetting [
				print[ "catenter: on-change triggered..." ]
				x: srclist/selected
				td/:x/8: catenter/text
				updateui x "^-" "catenter_change_event"
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
				updateui x "^-" "offsetenter_change_event"
			]
		]
		nthlabel: text "nth day" right
		nthenter: field
		on-change [
			if amsetting [
				print[ "nthenter: on-enter triggered..." ]
				x: srclist/selected
				td/:x/2: nthenter/text
				updateui x  "^-" "nthenter_change_event"
			]
		]
		text "weekday" right		
		wkdenter: drop-list 100x20 data [ "0" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday" "nowke" "nowke_b" "nowke_a" ]
		on-change [
			if amsetting [
				print[ "wkdenter: on-change triggered..." ]
				x: srclist/selected
				selfname: pick face/data face/selected
				print[ "^-wkdenter is changing " td/:x/3 " to " face/selected ]
				td/:x/3: face/selected
				updateui x  "^-" "wkdenter_change_event"
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
				updateui x   "^-" "nthmonthenter_change_event"
			]
		]
		text "from month" right
		frommonthenter: field
		on-change [
			if amsetting [
				print[ "frommonthenter: on-enter triggered..." ]
				x: srclist/selected
				td/:x/5: face/text
				updateui x  "^-" "frommonthenter_change_event"
			]
		]
		text "from year" right
		fromyearenter: field
		on-change [
			if amsetting [
				print[ "fromyearenter: on-enter triggered..." ]
				x: srclist/selected
				td/:x/6: face/text
				updateui x  "^-" "fromyearenter_change_event"
			]
		]
		;space 100x0
		;saveit: button "save all transactions" [savetd td "-^" "saveit_event"]
	]
]
