#! /usr/bin/env python
#
#

import sys

if len(sys.argv) == 1:
    print("0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15")
    sys.exit(0)
    
pl=sys.argv[1]

bl = list(range(1,17))

if pl[0] == '-':
    # assume they're all < 0
    beams = pl.split(',')
    for b in beams:
        bl[abs(int(b))] = 0
    msg = ''
    for i in range(len(bl)):
        b = bl[i]
        if b > 0:
            if len(msg) > 0:
                msg = msg + ",%d" % i
            else:
                msg = "%d" % i
    print(msg)
else:
    print("need - as first character to negate the beams")
