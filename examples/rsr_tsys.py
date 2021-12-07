#! /usr/bin/env python


import sys
import numpy as np
import matplotlib.pyplot as plt


from dreampy3.redshift.utils.fileutils import make_generic_filename
from dreampy3.redshift.netcdf import RedshiftNetCDFFile
from dreampy3.redshift.plots import RedshiftPlot

Qshow = True
Qspec = False
ext   = 'png'
n     = 0

for f in sys.argv[1:]:
    if f == '-s':
        Qshow = False
        continue
    if f == '-z':
        ext = 'svg'
        continue
    if f == '-t':
        Qspec = True
        continue
    n = n + 1
    obsnum = int(f)

if n==0:
    sys.exit(0)

if Qspec:
    base  = 'rsr.spectrum'
else:
    base  = 'rsr.tsys'
    
    
plt.figure()
colors = plt.rcParams['axes.prop_cycle'].by_key()['color']

for chassis in range(4):
    nc = RedshiftNetCDFFile(make_generic_filename(obsnum,chassis))
    if Qspec:
        nc.hdu.process_scan()
    else:
        nc.hdu.get_cal()
    for board in range(6):
        freqs = nc.hdu.frequencies[board, :]
        if Qspec:
            y = 1000*np.mean(nc.hdu.spectrum[:,board,:], axis=0)
        else:
            y = nc.hdu.cal.Tsys[board, :]
        ch = nc.hdu.header.ChassisNumber
        if board == 0:
            plt.step(freqs,y,c=colors[chassis], where='mid', label="chassis %d" % chassis)
        else:
            plt.step(freqs,y,c=colors[chassis], where='mid')
    nc.close()

plt.xlim([72,112])
plt.title("obsnum=%d" % obsnum)
plt.xlabel("Frequency (GHz)")
if Qspec:
    plt.ylabel("Spectrum (mK)")
    plt.ylim([-10,100])
else:
    plt.ylabel("Tsys (K)")
    plt.ylim([40,310])
plt.legend()
if Qshow:
    plt.show()
else:
    pout = "%s.%s" % (base,ext)
    plt.savefig(pout)
    print("%s writtten" % pout)
