#! /usr/bin/env bash
#
#  find which source/obsnum combinations are in an LMT project
#

pid=$1

if [ -z "$pid" ]; then
    echo "Usage: $0 ProjectId"
    echo "   Makes a list of obsnums, sorted per source, for a given ProjectId"
    exit 0
fi

log=$WORK_LMT/tmp/$pid.obsnums.log
g=0

grep $pid $DATA_LMT/data_lmt.log | grep Science | tabcols - 6,2  > $log
for src in $(tabcols $log 1 | sort | uniq); do
    if [ $g == 0 ]; then 
	echo $src
	grep -w $src $log | tabcols - 2 | sort
    else
	echo "on[\"$src\"] = "
	for o in $(grep -w $src $log | tabcols - 2 | sort -n); do
	    printf "%d," $o
	done
    fi
done

