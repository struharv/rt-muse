function [sequence_min, index_min, sequence_max, index_max] = minmaxseq(sequence)
% MINMAXSEQ  Analyze the sequence of points given as input.
%   [SEQUENCE_MIN, INDEX_MIN, SEQUENCE_MAX, INDEX_MAX] 
%     = minmaxseq(SEQUENCE)
%   SEQUENCE is a column vector with increasing values. 
%   The values are supposed to be times at which events have 
%   happened.

  num_marks = length(sequence);
  intervals = diff(sequence);
  temporary_intervals = zeros(num_marks,1);

  % initializations
  sequence_min = zeros(num_marks,1);
  index_min = zeros(num_marks,1); 
  sequence_max = zeros(num_marks,1); 
  index_max = zeros(num_marks,1); 

  % computation
  for i = 1:num_marks-1,
    temporary_intervals = temporary_intervals(1:end-1) + intervals(i:end);
    [sequence_min(i+1), index_min(i+1)] = min(temporary_intervals);
    [sequence_max(i+1), index_max(i+1)] = max(temporary_intervals);
  end

end
