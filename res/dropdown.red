Red [ needs 'view ]
;; broken in red-gtk as of Feb 2021, check it again around May
view [ 
	drop-down 180x30 "" select 2 data["two" "four" "eight"] on-enter [
		append face/data face/text
		probe face/data
	]
]
