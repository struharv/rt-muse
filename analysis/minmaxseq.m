function [sequence_min, index_min, sequence_max, index_max] = minmaxseq(sequence, max_samples)
% MINMAXSEQ  Analyze the sequence of points given as input.
%   [SEQUENCE_MIN, INDEX_MIN, SEQUENCE_MAX, INDEX_MAX] 
%     = minmaxseq(SEQUENCE, MAX_SAMPLES)
%   SEQUENCE is a row vector with at least MAX_SAMPLES+1 strictly
%   increasing values. The values are supposed to be times at which
%   events have happened. MAX_SAMPLES determines the span of the
%   analysis, i.e. the max number of consecutive elements of the
%   sequence to be considered.

  % ---------------------------------------------------------------------------- 
  % check lenght of the sequence of samples against the 
  intervals = diff(sequence);
  if (max_samples > length(intervals))
    disp('[MINMAXSEQ] the sequence must contain at least MAX_SAMPLES+1 elements');
    return;
  end
  % ----------------------------------------------------------------------------

  % ----------------------------------------------------------------------------
  % the traces have been generated with ftrace, and ftrace sometimes has bugs,
  % in particular, it sometimes fails at writing the timestamp in the correct
  % format; the formatting error is easy to detect and can be fixed
  while 1
    intervals = diff(sequence); % finding time intervals
    [value, index] = min(intervals);
    if (value >= 0) % all the times are strictly increasing --> correct vector
      break;
    end
    if abs(sequence(index + 1) - floor(sequence(index + 1)) - 0.1) < 0.0000001
      sequence(index+1) = floor(sequence(index+1)) + 1;
      disp('[MINMAXSEQ] Fixed known problem with ftrace tracer.');
    else
      disp('[MINMAXSEQ] Some jobs have negative execution times.');
      disp('[MINMAXSEQ] No further analysis is possible.')
      return;
    end
  end
  % ----------------------------------------------------------------------------

  temporary_intervals = zeros(size(sequence));

  % initializations
  sequence_min = zeros(1, max_samples + 1); 
  index_min = zeros(1, max_samples + 1); 
  sequence_max = zeros(1, max_samples + 1); 
  index_max = zeros(1, max_samples + 1); 

  % computation
  for i = 1:max_samples,
    temporary_intervals = temporary_intervals(1:end-1) + intervals(i:end);
    [sequence_min(i+1), index_min(i+1)] = min(temporary_intervals);
    [sequence_max(i+1), index_max(i+1)] = max(temporary_intervals);
  end

end
