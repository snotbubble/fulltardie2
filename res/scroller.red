Red [ needs 'view ] 
view [
    size 600x400
     p: panel [
        below
        text "A"
        text "B"
        text "C"
        text "D"
    ]
    scroll: base 16x200 loose react [
        face/offset/y: (max (min 195 face/offset/y) 5)
        face/offset/x: scrollx
        p/offset/y: to integer! negate face/offset/y
    ]
    do [scrollx: scroll/offset/x]
]
