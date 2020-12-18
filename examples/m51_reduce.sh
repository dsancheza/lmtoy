#! /bin/bash
#
#  Example OTF sequoia data reduction path for M51 with 2 bad pixels (0,5)
#
#  CPU: 301.25user 23.80system 5:38.07elapsed 96%CPU 
#
#

#/usr/bin/time process_otf_map.py -c M51_process.txt
#/usr/bin/time grid_data.py       -c M51_grid.txt
#exit 0


# input parameters
src=M51
obsnum=91112
makespec=1
viewspec=0
viewcube=0
pix_list=1,2,3,4,6,7,8,9,10,11,12,13,14,15


#             simple keyword=value command line parser for bash - don't make any changing below
for arg in $*; do\
  export $arg
done


# derived parameters
p_dir=${src}_data
s_nc=${src}_${obsnum}.nc
s_fits=${src}_${obsnum}.fits

# pixel 0 is bad, 5 is bad part of the time, but we can't select by time yet
# so we're removing them both

#  convert RAW to SpecFile
if [ $makespec = 1 ]; then
process_otf_map2.py -p $p_dir \
		    -o $s_nc \
		    -O $obsnum \
		    --pix_list $pix_list \
		    --bank 0 \
		    --stype 2 \
		    --use_cal \
		    --x_axis VLSR \
		    --b_order 0 \
		    --b_regions [[200,380],[580,800]] \
		    --l_region [400,600] \
		    --slice [200,800] \
		    --eliminate_list 0
fi

#  bug?    --eliminate_list 0 didn't remove it if 0 was in pix_list
# desetecting pixel 0:   364314 specrtra  12.8G memory

if [ $viewspec = 1 ]; then
view_spec_file.py -i $s_nc \
		  --pix_list $pix_list \		  
		  --rms_cut 10.0 \
		  --plot_range=-1,3
fi
# --show_all_pixels \
# --show_pixel 10 \


#  convert SpecFile to FITS
grid_data.py --program_path spec_driver_fits \
	     -i $s_nc \
	     -o $s_fits \
	     --resolution 11.0 \
	     --cell 5.5 \
	     --pix_list $pix_list \
	     --rms_cut 10 \
	     --x_extent 400 \
	     --y_extent 400 \
	     --otf_select 1 \
	     --rmax 3 \
	     --otf_a 1.1 \
	     --otf_b 4.75 \
	     --otf_c 2 \
	     --n_samples 256 \
	     --noise_sigma 1


if [ $viewcube = 1 ]; then
view_cube.py -i $s_fits \
	     --v_range=400,600 \
	     --v_scale=1000 \
	     --location=-6,-6 \
	     --scale=0.000278 \
	     --limits=-400,400,-400,400 \
	     --tmax_range=0.0,1.4 \
	     --tint_range=-1,50 \
	     --plot_type TINT \
	     --interpolation bilinear
fi

# rms = 0.134

if [ ! -z $NEMO ]; then
    fitsccd $s_fits $s_fits.ccd
    ccdstat $s_fits.ccd bad=0 robust=t planes=0 > $s_fits.cubestat
    ccdstat $s_fits.ccd bad=0 robust=t
    ccdsub  $s_fits.ccd - 30:110 30:130 | ccdstat - robust=t bad=0
    ccdstat $s_fits.ccd bad=0 qac=t
    rm $s_fits.ccd        
fi

if [ ! -z $ADMIT ]; then
    runa1 $s_fits
fi

echo Done with $s_fits

#
# fitsccd M51_91112.fits - | ccdsub - - 20:90 20:90 | ccdstat - robust=t bad=0 
