Red [needs: 'view]

;; work-in-progress
;; unless there's a compiled binary, assume this is all kinds of broken
;;
;; 32-bit only! don't use if polluting your system with 32-bit libraries isn't an option.


;; ! : doing it
;; ? : having problems with it
;; - : dropped it
;;
;; TODO: [!] handle simple day-counting in findnextdate
;; TODO: [!] start plain-english translator
;; TODO: [!] panel switchers
;; TODO: [ ] fix every-nth every-day logic
;; TODO: [ ] fix from-day
;; TODO: [ ] re-arrange params to fit panel
;; TODO: [ ] rule list header ui
;; TODO: [ ] add blank line to bottom of rule list & hadle it
;; TODO: [ ] test forecast ui
;; TODO: [ ] rewrite graph ui


;; rule selection index, used everywhere:
rsidx: 1

;; stop ui events from looping
noupdate: true

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

sampledata: {|eac|ntd|wkd|fdy|ntm|mth|yea|amt|cat|grp|description|
|1|1|7|0|1|7|0|-5.00|cat1|grp1|every sunday of every month starting from this september|
|2|2|1|0|1|0|0|-10.0|cat2|grp1|every 2nd and 4th monday of every month starting this month|
|1|6|4|0|3|2|0|-150.0|cat3|grp1|every last thursday of every 3rd month starting february|
|1|26|8|0|1|0|0|50.0|cat4|grp2|every weekday closest to the 26th of the month starting this month|
|1|32|0|0|12|2|0|-60.0|cat1|grp2|every last day of february|
|0|8|0|0|0|8|0|-300.0|cat2|grp3|next august 8th|
|0|9|9|0|1|11|0|15.0|cat3|grp3|every weekday before the 9th of every month starting november|
|14|14|10|0|1|0|0|45.0|cat4|grp3|every 14th and 28th day of every month or the following weekday if on a weekend|}

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
	print [ tabi "findnextdate function triggered by " tabf "..." ]
    ;print [ tabi "findnexdate source data: " dt ]
	allgood: true

	n: now/date
	o: copy []

	ofs: (to-integer dt/1)
	nth: (to-integer dt/2)
	ofm: (to-integer dt/5)
	fmo: (to-integer dt/6)
	fye: (to-integer dt/7)
	wkd: (to-integer dt/3)
	ffd: (to-integer dt/4)

	if fmo = 0 [fmo: n/month]
	if fye = 0 [fye: n/year]
	fdy: now/day

;; get last day of the month

	t: lymd fye rejoin [ tabi "^-^-" ] "findnextdate"
	md: pick t fmo

;; clamp search-start-day to last day of the month if greater

	if md < fdy [ fdy: md ]
	
	;probe fye
	;probe fmo
	;probe fdy
	
	a: make date! [fye fmo fdy]
	j: make date! [fye fmo fdy]
	
	;print [ tabi "^-findnextdate search-start-date is: " a ]

	dif: ( to-integer ((((now/date - a) / 7.0) / 52.0) * 12.0) ) + 13
	;print [ tabi "^-findnextdate differnce in months between now and search-start-date is : " dif ]
	if allgood [
		loop dif [
			dmo: (a/month = fmo)
			;print [ tabi "^-findnextdate checking if its reached the last month: " a/month "-" fmo "%" ofm "=" (a/month - fmo) % ofm ]
			if ofm > 0 [ dmo: ((a/month - fmo) % ofm = 0) ]
			if dmo [
				c: 0
				t: lymd a/year rejoin [ tabi "^-^-" ] "findnextdate"
				wdc: 0
				cdc: 0
				md: pick t a/month

				if (wkd = 0) or (wkd > 7) [ 
					mth: max (min nth md) ffd	
					if mth = 0 [ 
						;print[ tabi "^-findnextdate found zero nth in " dt ]
						mth: now/day 
						;print[ tabi "^-findnextdate setting mth to " mth ]
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
							append/only o reduce [a (round/to (to-float dt/8) 0.01) dt/9 dt/11]
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
		;print[ tabi "^-getforecast is checking row of data: " t ]
		nd: findnextdate t rejoin [ tabi "^-^-"] "getforecast"
		append f nd
	]
	sort/compare f func [a b] [
		case [
			a/1 > b/1 [-1] 
			a/1 < b/1 [1]
			a/1 = b/1 [0]
		]
	]
	rb: 0.0
	foreach r f [
		af: round/to (to-float r/2) 0.01
		rb: rb + af
		append r round/to rb 0.01
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
		tr: trim/head (trim/tail r/9)
		if (find c tr) = none [ append c tr ]
	]
	print [ tabi "getcats function is done." ] 
	c
]
getgroups: function [ d tabi tabf ] [
	print [ tabi "getgroups function triggered by " tabf "..." ]
	c: copy []
	foreach r d [
		tr: trim/head (trim/tail r/10)
		if (find c tr) = none [ append c tr ]
	]
	print [ tabi "getgroups function is done." ] 
	c
]

rendersrc: function [d tabi tabf ] [
	print[ tabi "rendersrc triggered by " tabf "..." ]
	o: copy []
	hh: copy/deep ["eah" "ntd" "wkd" "fdy" "ntm" "mth" "yea" "amount" "cat" "grp" "description"]
	insert/only d hh
	pads: copy/deep [ 0 0 0 0 0 0 0 0 0 0 0 ]
	foreach r d [
		;print[ tabi "^-checking row : " r ]
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

getyearbracket: function [] [
	o: copy []
	e: copy []
	sy: now/year - 5
	ey: now/year + 5
	repeat n (ey - sy) [
		either ((sy - 1) + n) = now/year [
			append o "from this year"
			append e 0
		] [
			append o rejoin [ "from " to-string ((sy - 1) + n) ]
			append e ((sy - 1) + n)
		]
	]
	out: reduce [o e]
	probe out
    out
]

catdata: getcats copy/deep td "^-" "initial_forecast"
groupdata: getgroups copy/deep td "^-" "initial_forecast"
gf: getforecast copy/deep td "^-" "initial_forecast"
rendforecast: renderforecast copy/deep gf "^-" "initial_forecast"
rendrules: rendersrc copy/deep td "^-" "initial_forecast"
rendraw: renderraw copy/deep td "^-" "initial_forecast"
;foreach p rendrules [ probe p ]
yearbracket: getyearbracket
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


changeparam: func [ i s ] [
	td/:rsidx/:i: s
	rendrules:  rendersrc copy/deep td "^-" "recurrence_rule_parameter_change_event"
	rlist/data: rendrules/1
	rlist/selected: rsidx
	nxt: findnextdate td/:rsidx "^-" "rlist_change_event"
	tqq/text: to-string nxt/1/1
]



;; parameter pane
pparm: compose/deep [
	ppane: panel loose with [ offset 0x0 ] [
		across
		text 140x30 "Transaction Rule"
		fname: field 520x30 [ unless noupdate [ changeparam 11 face/text ] ]
		return
		text 140x30 "Group"
		lgrp: drop-down 100x30 data groupdata [ unless noupdate [ changeparam 10 (quote face/data/(face/selected)) ]]
		pad 10x0 text 80x30 "Category"
		lcat: drop-down 100x30 data catdata [ unless noupdate [ changeparam 9 (quote face/data/(face/selected)) ]]
		pad 10x0 text 80x30 "Amount"
		famt: field 100x30 [ unless noupdate [ changeparam 8 face/text ] ]
		return
		pad 0x10 text 140x30 "Recurrance"
		button "test layout" [ layoutparams ppane/size/x 10 10 ]
		return
		squishme: panel [
		    leach: drop-list data [ "the" "every" "every 2" "every 3" "every 4" "every 5" "every 6" "every 7" "every 8" "every 9" "every 10" "every 11" "every 12" "every 13" "every 14" "every 15" "every 16" "every 17" "every 18" "every 19" "every 20" "every 21" "every 22" "every 23" "every 24" "every 25" "every 26" "every 27" "every 28" "every 29" "every 30" "every 31" ] select 1	[ 
			    unless noupdate [ changeparam 1 (quote (to-string (face/selected - 1))) ]
			]
		    lday: drop-list data [ "" "2nd" "3rd" "4th" "5th" "6th" "7th" "8th" "9th" "10th" "11th" "12th" "13th" "14th" "15th" "16th" "17th" "18th" "19th" "20th" "21st" "22nd" "23rd" "24th" "25th" "26th" "27th" "28th" "29th" "30th" "31st" "last" ] [
			    unless noupdate [ changeparam 2 (quote (to-string face/selected)) ]
			]
			lweekday: drop-list data [ "day" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday" "weekday closest to the" "weekday on or before the" "weekday on or after the"] [ 
				if face/selected > 8 [
					if lday/offset/x < face/offset/x [ 
						ldidx: lday/selected
						face/offset/x: lday/offset/x lday/offset/x: face/offset/x + face/size/x  + 10
						lday/data/1: "1st"
						lday/selected: ldidx
					]
				]
				if face/selected < 9 [ 
					if lday/offset/x > face/offset/x [ 
						ldidx: lday/selected
						lday/offset/x: face/offset/x face/offset/x: lday/offset/x + lday/size/x  + 10
						lday/data/1: ""
						lday/selected: ldidx
					]
				]
				unless noupdate [ changeparam 3 (quote (to-string (face/selected - 1))) ]
			]
			lfromday: drop-list data [ "" "from the 1st" "from the 2nd" "from the 3rd" "from the 4th" "from the 5th" "from the 6th" "from the 7th" "from the 8th" "from the 9th" "from the 10th" "from the 11th" "from the 12th" "from the 13th" "from the 14th" "from the 15th" "from the 16th" "from the 17th" "from the 18th" "from the 19th" "from the 20th" "from the 21st" "from the 22nd" "from the 23rd" "from the 24th" "from the 25th" "from the 26th" "from the 27th" "from the 28th" "from the 29th" "from the 30th" "from the 31st" ] [
				unless noupdate [ changeparam 4 (quote (to-string face/selected)) ]
			]
		    lnthmonth: drop-list data [ "of" "of every month from" "of every 2nd month from" "of every 3rd month from" "of every 4th month from" "of every 5th month from" "of every 6th month from" "of every 7th month from" "of every 8th month from" "of every 9th month from" "of every 10th month from" "of every 11th month from" "of" "of"] [
				unless noupdate [ changeparam 5 (quote (to-string (face/selected - 1))) ]
			]
			lfrommonth: drop-list data [ "this month" "January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December" ] [
				unless noupdate [ changeparam 6 (quote (to-string (face/selected - 1))) ]
			]
			lfromyear: drop-list data yearbracket/1 [
				unless noupdate [ changeparam 7 (quote (to-string yearbracket/2/(face/selected))) ]
			]
		]
		return
		tql: text 140x30 "next transaction is:"
		tqq: text 700x30
	] react [ 
		(to-set-path [face offset x ]) 0
	    (to-set-path [face offset y ]) min max -100 (to-path [face offset y]) 100 
	]
]
probe pparm

;; transaction rule pane
prule: compose/deep [
	below
   	rlist: text-list 760x310 data rendrules/1 select 1 font-name "consolas" font-size 8 font-color 80.180.255 with [ offset: 0x0 ] [
		noupdate: true
		squish: false
		attempt [ none? ppane squish: true ]
		if squish [ layoutparams ppane/size/x 10 10 ]
		rsidx: face/selected
		probe rsidx
		probe td/:rsidx/1
		eidx: rsidx + 1
	   	leach/selected: (quote (to-integer td/:rsidx/1)) + 1
		lday/selected: min (quote (to-integer td/:rsidx/2)) 32
		lweekday/selected: (quote (to-integer td/:rsidx/3)) + 1
		if lweekday/selected > 1 [
			if lweekday/selected < 9 [
				if lday/selected > 5 [
					lday/selected: 32
				]
			]
		]
		lfromday/selected: (quote (to-integer td/:rsidx/4)) + 1
		lnthmonth/selected: (quote (to-integer td/:rsidx/5)) + 1
		lfrommonth/selected: (quote (to-integer td/:rsidx/6)) + 1
		yy: "this year"
		parse td/:rsidx/7 [to "2" copy yy to end ]
	    yy: rejoin [ "from " yy ]
		probe yy
		lfromyear/selected: index? find lfromyear/data yy
	    probe td/:rsidx/8
		famt/text: td/:rsidx/8
		lcat/selected: index? find lcat/data td/:rsidx/9
		lgrp/selected: index? find lgrp/data td/:rsidx/10
		fname/text: td/:rsidx/11
		probe td/:rsidx
		nxt: findnextdate td/:rsidx "^-" "rlist_change_event"
		probe nxt/1
		tqq/text: to-string nxt/1/1
		noupdate: false
	]
]

squishparms: func [ sx ] [
	currentsx: squishme/size/x
	blockn: [ lfromyear lfrommonth lnthmonth lfromday lweekday lday leach ]
    n: 1
	while [currentsx > sx] [
		if n > 7 [ break ]
		p: reduce blockn/:n
		if p/offset/x > 0 [
			;print [ "moving parameter widget (" n "): " blockn/:n ]
			currentsx: p/offset/x
			squishme/size/x: currentsx + 10
	    	p/offset/x: 0
			p/offset/y: p/offset/y + 30
		]
		n: n + 1
	]
]

layoutparams: function [cx ox oy] [
	m: to-integer (cx / 300.0)
	blockn: [ leach lday lweekday lfromday lnthmonth lfrommonth lfromyear ]
	blockw: [ leach/size/x lday/size/x lweekday/size/x lfromday/size/x lnthmonth/size/x lfrommonth/size/x lfromyear/size/x ]
	;blockm: copy []
	su: 0
	n: 1
    row: copy []
	rows: copy/deep reduce [ row row row row row row row ]
	r: 1
	foreach s blockw [
		p: reduce blockn/:n
		su: su + reduce s
		either su >= (cx - 30) [ 
		    r: r + 1 append rows/:r reduce p su: reduce s
		] [
			append rows/:r reduce p
		]
		n: n + 1
	]

	rk: 0
	foreach rw rows [
		if (length? rw) > 0 [
			mk: 0
			foreach co rw [
				p: reduce co
				p/offset/x: mk
				mk: mk + p/size/x
				p/offset/y: rk
			]
			rk: rk + 35
		]
	]
	;clear rows
	;clear blockn
	;clear blockw
	squishme/size/y: rk
	tql/offset/y: squishme/offset/y + squishme/size/y + 20
	tqq/offset/y: tql/offset/y
	ppane/size/y: tqq/offset/y + 40
]

view [
	Title "fulltardie"
	below
	aa: panel 800x380 [
		below
		aah: panel 50.50.50 790x55 with [ offset: 0x0 ] [
			aaddl: drop-list 200x20 data [ "transaction rules" "parameters" "forecast list" "forecast graph" "raw transaction rules" "category/group chart" ] on-change [
				switch face/selected [
					1 [ noupdate: true aap/pane: layout/only prule rlist/offset: 0x0 rlist/size/x: aa/size/x rlist/size/y: aa/size/y - 55]
					2 [ noupdate: true aap/pane: layout/only pparm ]
				]
			]
		]
		aap: panel 790x500 [ ]
	]
	hh: panel 800x10 40.40.40 loose draw [ ] react [
		face/offset/x: 0
		face/offset/y: min (max 200 face/offset/y) 600
		aa/offset/y: 0
		bb/offset/y: face/offset/y + 10
		cc/offset/y: 0
		aa/size/y: face/offset/y
		bb/size/y: vv/size/y - face/offset/y - 10
		cc/size/y: vv/size/y
		aah/offset/y: 0
		bbh/offset/y: 0
		cch/offset/y: 0
		aap/offset/y: 55
		bbp/offset/y: 55
		ccp/offset/y: 55
		aap/size/y: aa/size/y - 55
		bbp/size/y: bb/size/y - 55 - 10
		ccp/size/y: cc/size/y - 55
		attempt [ rlist/size/y: rlist/parent/size/y ]
		face/draw: compose/deep [
			pen off
		   	fill-pen 100.100.100
			circle (to-pair compose/deep [(to-integer (face/size/x * 0.5) - 10) 5]) 3 3 
			circle (to-pair compose/deep [(to-integer (face/size/x * 0.5)) 5]) 3 3
			circle (to-pair compose/deep [(to-integer (face/size/x * 0.5) + 10) 5]) 3 3 
		] 
	]
	bb: panel green 800x380 [
		below
		bbh: panel 50.50.50 790x55 with [ offset: 0x0 ] [
			bbddl: drop-list 200x20 data [ "transaction rules" "parameters" "forecast list" "forecast graph" "raw transaction rules" "category/group chart" ] on-change [
				switch face/selected [
					1 [ noupdate: true bbp/pane: layout/only prule rlist/offset: 0x0 rlist/size/x: bb/size/x rlist/size/y: bb/size/y - 55]
					2 [ noupdate: true bbp/pane: layout/only pparm ]
				]
			]
		]
		bbp: panel red 790x500 [ ]
	]
	return
	vv: panel 10x800 40.40.40 loose draw [ ] react [ 
		face/offset/y: 0
		face/offset/x: min (max 500 face/offset/x) 900
		aa/offset/x: 0
		bb/offset/x: 0
		cc/offset/x: face/offset/x + 10 
		aa/size/x: face/offset/x
		bb/size/x: face/offset/x
		cc/size/x: cc/parent/size/x - cc/offset/x 
		hh/size/x: face/offset/x
		aah/offset/x: 0
		bbh/offset/x: 0
		cch/offset/x: 0
		aah/size/x: aa/size/x
		bbh/size/x: bb/size/x
		cch/size/x: cc/size/x
		aap/offset/x: 0
		bbp/offset/x: 0
		ccp/offset/x: 0
		aap/size/x: aa/size/x
		bbp/size/x: bb/size/x
		ccp/size/x: cc/size/x
		attempt [ rlist/size/x: rlist/parent/size/x ]
		attempt [ ppane/size/x: ppane/parent/size/x - 10 ]
		face/draw: compose/deep [ 
			pen off 
		   	fill-pen 100.100.100
			circle (to-pair compose/deep [5 (to-integer (face/size/y * 0.5) - 10)]) 3 3 
			circle (to-pair compose/deep [5 (to-integer (face/size/y * 0.5))]) 3 3
			circle (to-pair compose/deep [5 (to-integer (face/size/y * 0.5) + 10)]) 3 3 
		]
		squish: false
		attempt [ none? ppane squish: true ]
		if squish [ layoutparams ppane/size/x 10 10 ]
		
	]
	return
	cc: panel 280x800 [
		below
		cch: panel 50.50.50 790x55 with [ offset: 0x0 ] [
			ccddl: drop-list 200x20 data [ "transaction rules" "parameters" "forecast list" "forecast graph" "raw transaction rules" "category/group chart" ] on-change [
				switch face/selected [
					1 [ noupdate: true ccp/pane: layout/only prule rlist/offset: 0x0 rlist/size/x: cc/size/x rlist/size/y: cc/size/y - 55]
					2 [ noupdate: true ccp/pane: layout/only pparm ]
				]
			]
		]
		ccp: panel blue 790x500 [ ]
	]
]
