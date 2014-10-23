#!/bin/bash

# --------------------------------------------------------------------
# This script compiles the application code, if necessary and executes
# it with some test examples. The input test does not use
# SCHED_DEADLINE. Notice that if you want to use SCHED_DEADLINE, you
# may need to disable the admission controller, by running
# echo -1 > /proc/sys/kernel/sched_rt_runtime_us
# --------------------------------------------------------------------

# Variable declarations
APP_binary="./bin/application"
RESULT_dir="./results"
REFERENCE_run=$1
REFERENCE_trace="reference"
SIMULATION_run=$2
SIMULATION_trace="simulation"

if [ "$TRACE_CMD_COMMAND" = "" ]
then
  TRACE_CMD_COMMAND="trace-cmd"
fi

function launch_simulation {
  printf "[LAUNCH] Running for $1 ..."
  # -e 'sched_migrate*' # monitor migrations
  # -e 'sched_wakeup*' # monitor scheduling wakeups
  # -e sched_switch # monitoring switch 
	sudo $TRACE_CMD_COMMAND record -e 'sched_migrate*' \
	  $APP_binary $1 \
	  &> $RESULT_dir/output_$2.txt
	mv -f trace.dat $RESULT_dir/$2.dat 
	printf " done\n"

	printf "[LAUNCH] Extracting data for $1 ..."
	$TRACE_CMD_COMMAND report $RESULT_dir/$2.dat \
	  > $RESULT_dir/$2.txt
	grep "begins loop" $RESULT_dir/$2.txt | \
	  awk 'BEGIN {OFS = ",";} { gsub(":", "", $3); print $3}' \
	  > $RESULT_dir/$2.csv
	printf " done\n" 
}

# --------------------------------------------------------------------
NUM_args=$#
if [ "$#" -ne 2 ]; then
    echo "[LAUNCH] Two parameters needed: reference and simulation"
    exit
fi

if [ ! -f $APP_binary ]; then
    printf "[LAUNCH] Compiling the application ..."
    make &> /dev/null
    printf " done\n"
fi

mkdir -p $RESULT_dir
launch_simulation ${REFERENCE_run} ${REFERENCE_trace}
launch_simulation ${SIMULATION_run} ${SIMULATION_trace}
