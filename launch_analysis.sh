# ------------------------------------------------------------
NUM_args=$#
if [ "$#" -ne 1 ]; then
    echo "[LAUNCH_ANALYSIS] One parameter needed: experiment name"
    exit
fi
# ------------------------------------------------------------

ANALYSIS_DIR="./analysis"
GENERATED_OCTAVE_SCRIPT="script_analysis.m"

echo "% ----------------------------------------" > $GENERATED_OCTAVE_SCRIPT
echo "clc; clear;" >> $GENERATED_OCTAVE_SCRIPT
echo "name_test = '$1';" >> $GENERATED_OCTAVE_SCRIPT
echo "% ----------------------------------------" >> $GENERATED_OCTAVE_SCRIPT
echo "addpath('$ANALYSIS_DIR')" >> $GENERATED_OCTAVE_SCRIPT
echo "process(name_test)" >> $GENERATED_OCTAVE_SCRIPT
echo "uplowbound(name_test)" >> $GENERATED_OCTAVE_SCRIPT
echo "pause" >> $GENERATED_OCTAVE_SCRIPT

octave $GENERATED_OCTAVE_SCRIPT
rm -f $GENERATED_OCTAVE_SCRIPT
