Red [ needs 'view ]
;; broken in red-gtk as of Feb 2021, check it again around May
view [ 
	d: drop-list 180x30 select 2 data["two" "four" "eight"] [f/text: pick face/data face/selected ]
	f: field 180x30 on-enter [
		append d/data face/text
		d/selected: (length? d/data)
		probe d/data
	]
]
