Red [ needs 'view ]

fittopane: function [ii ps] [
	g: ii/image
	either (ps/x / ps/y) > (g/size/x / g/size/y) [
		ii/size/y: to-integer (ps/y - 20)
		ii/size/x: to-integer ((ps/y - 20) * (g/size/x / g/size/y))
	] [
		ii/size/x: to-integer (ps/x - 20)
		ii/size/y: to-integer ((ps/x - 20) * (g/size/y / g/size/x))
	]
]

v: layout [
	p: panel 100x100 papaya [
		i: image 500x500 on-up [
			i/image: load request-file/filter ["pics" "*.png; *jpg"]
			fittopane i p/size
		]
	]
]

view/flags/options v [resize] [
    actors: object [
        on-resizing: function [face event] [
            p/size: face/size - 20x20
            fittopane i p/size
        ]
    ]
]
