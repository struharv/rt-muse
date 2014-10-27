RESULTS_DIR=$1
REFERENCE_EXP=$2
TEST_EXP=$3

ANALYSIS_DIR="./analysis"
GENERATED_OCTAVE_SCRIPT="script_analysis.m"

echo "% ----------------------------------------" > $GENERATED_OCTAVE_SCRIPT
echo "clc; clear;" >> $GENERATED_OCTAVE_SCRIPT
echo "resultdir      = '$RESULTS_DIR/';" >> $GENERATED_OCTAVE_SCRIPT
echo "name_reference = '$2';" >> $GENERATED_OCTAVE_SCRIPT
echo "name_test      = '$3';" >> $GENERATED_OCTAVE_SCRIPT
echo "% ----------------------------------------" >> $GENERATED_OCTAVE_SCRIPT
echo "addpath('$ANALYSIS_DIR')" >> $GENERATED_OCTAVE_SCRIPT
echo "process(resultdir, name_reference, name_test)" >> $GENERATED_OCTAVE_SCRIPT
echo "pause" >> $GENERATED_OCTAVE_SCRIPT

octave $GENERATED_OCTAVE_SCRIPT
rm -f $GENERATED_OCTAVE_SCRIPT
