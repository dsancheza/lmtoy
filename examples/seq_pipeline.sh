#! /bin/bash
#
#  A simple LMT OTF pipeline in bash.
#  Really should be written in python, but hey, here we go.
#
#  Note:   this will only reduce one OBSNUM.   If you place a file "lmtoy_$obsnum.rc"
#          in the current directory, parameters will be read from it.
#          If it does not exist, it will be created on the first run and you can edit it
#          for subsequent runs
#          If projectid is set, this is the subdirectory, within which obsnum is set
#
# There is no good mechanism here to make a new variable depend on re-running a certain task on which it depends
# that's perhaps for a more advanced pipeline
#
# @todo   close to running out of memory, process_otf_map2.py will kill itself. This script does not gracefully exit

version="seq_pipeline: 11-jan-2022"

if [ -z $1 ]; then
    echo "LMTOY>> Usage: path=DATA_LMT obsnum=OBSNUM ..."
    echo "LMTOY>> $version"    
    echo ""
    echo "See lmtoy_reduce.md for examples on usage"
    exit 0
else
    echo "LMTOY>> $version"
fi

source lmtoy_functions.sh

# debug
# set -x
debug=0
#set -e


# input parameters
#            - start or restart
path=${DATA_LMT:-data_lmt}
obsnum=79448
obsid=""
newrc=0
pdir=""
#            - procedural
makespec=1
makecube=1
makewf=1
viewspec=1
viewcube=0
viewnemo=1
admit=1
clean=1
#            - meta parameters that will compute other parameters for SLR scripts
extent=0
dv=100
dw=250
#            - parameters that directly match the SLR scripts
pix_list=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
rms_cut=-4
location=0,0
resolution=12.5   # will be computed from skyfreq
cell=6.25         # will be computed from resolution/2
rmax=3
otf_select=1
otf_a=1.1
otf_b=4.75
otf_c=2
noise_sigma=1
b_order=0
stype=2
sample=-1
otf_cal=0
edge=0
bank=-1

# unset a view things, since setting them will give a new meaning
unset vlsr

#             simple keyword=value command line parser for bash - don't make any changing below
for arg in $*; do
    export $arg
done

#             put in bash debug mode
if [ $debug = 1 ]; then
    set -x
fi

#             see if pdir working directory needs to be used
if [ ! -z $pdir ]; then
    echo Working directory $pdir
    mkdir -p $pdir
    cd $pdir
else
    echo No PDIR directory used, all work from the current directory
fi


#             process the parameter file (or force new one with newrc=1)
rc=lmtoy_${obsnum}.rc
if [ -e $rc ] && [ $newrc = 0 ]; then
    echo "LMTOY>> reading $rc"
    echo "# DATE: `date +%Y-%m-%dT%H:%M:%S.%N`" >> $rc
    for arg in $*; do
        echo "$arg" >> $rc
    done
    source ./$rc
    newrc=0
else
    newrc=1
fi


if [ $newrc = 1 ]; then
    echo "LMTOY>> Hang on, creating a bootstrap $rc from path=$path"
    echo "# $version"                            > $rc
    echo "# DATE: `date +%Y-%m-%dT%H:%M:%S.%N`" >> $rc
    echo "# obsnum=$obsnum" >> $rc

    if [ ! -d ${path}/ifproc ]; then
	echo There is no ifproc directory in ${path}
	rm $rc
	exit 1
    fi
    if [ ! -d ${path}/spectrometer ]; then
	echo There is no spectrometer directory in ${path}
	rm $rc	
	exit 1
    fi
    if [ ! -d ${path}/spectrometer/roach0 ]; then
	echo There is no spectrometer/roach0 directory in ${path}
	rm $rc	
	exit 1
    fi
    
    ifproc=$(ls ${path}/ifproc/*${obsnum}*.nc)
    if [ -z $ifproc ]; then
	rm -f $rc
	echo No matching obsnum=$obsnum and path=$path
	echo The following rc files are present here:
	ls lmtoy_*.rc | sed s/lmtoy_// | sed s/.rc//
	exit 0
    fi
    echo "# Using ifproc=$ifproc" >> $rc
    echo "# path=$path"           >> $rc

    # lmtinfo grabs some useful parameters from the ifproc file
    lmtinfo.py $path $obsnum | tee -a $rc
    source ./$rc
    
    #   w0   v0   v1     w1
    v0=$(echo $vlsr - $dv | bc -l)
    v1=$(echo $vlsr + $dv | bc -l)
    w0=$(echo $v0 - $dw | bc -l)
    w1=$(echo $v1 + $dw | bc -l)

    b_order=$b_order
    b_regions=[[$w0,$v0],[$v1,$w1]]
    l_regions=[[$v0,$v1]]
    slice=[$w0,$w1]
    v_range=$v0,$v1

    echo "# based on vlsr=$vlsr, dv=$dv,  dw=$dw" >> $rc
    echo b_order=$b_order           >> $rc
    echo b_regions=$b_regions       >> $rc
    echo l_regions=$l_regions       >> $rc
    echo slice=$slice               >> $rc
    echo v_range=$v_range           >> $rc
    if [ $extent != 0 ]; then
	echo x_extent=$extent       >> $rc
	echo y_extent=$extent       >> $rc
    fi
    
    echo pix_list=$pix_list         >> $rc
    
    echo rmax=$rmax                 >> $rc
    echo otf_a=$otf_a               >> $rc
    echo otf_b=$otf_b               >> $rc
    echo otf_c=$otf_c               >> $rc
    echo sample=$sample             >> $rc
    echo otf_cal=$otf_cal           >> $rc
    echo edge=$edge                 >> $rc

    # source again to ensure the changed variables are in
    source $rc
    

    echo "LMTOY>> this is your startup $rc file:"
    cat $rc
    echo "LMTOY>> Sleeping for 5 seconds, you can  abort, edit $rc, then continuing"
    sleep 5
else
    echo "LMTOY>> updating"
fi

#             sanity checks
if [ ! -d $p_dir ]; then
    echo "LMTOY>> directory $p_dir does not exist"
    exit 1
fi

#             derived parameters (you should not have to edit these)
p_dir=${path}

#             pick one bank, or loop over all allowed banks
if [ $bank != -1 ]; then
    s_on=${src}_${obsnum}_${bank}
    s_nc=${s_on}_${bank}.nc
    s_fits=${s_on}_${bank}.fits
    w_fits=${s_on}_${bank}.wt.fits
    lmtoy_seq1
elif [ $numbands == 1 ]; then
    s_on=${src}_${obsnum}
    s_nc=${s_on}.nc
    s_fits=${s_on}.fits
    w_fits=${s_on}.wt.fits
    bank=0
    lmtoy_seq1
else
    for b in $(seq 1 $numbanks); do
	bank=$(expr $b - 1)
	echo "Preparing for bank = $bank"
    done
    exit 0
fi
