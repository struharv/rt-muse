function [ref_seq, k] = uniformYvalues(input_seq, tol, num_sim_marks)
% UNIFORMYVALUES  computes a column vector of reference values for the
%   supply function. Ideally, if the nominal length of a job is E, then
%   it should produce
%
%     ref_seq = E*(0:num_sim_marks-1)'
%
%   Instead, ref_seq is produced from input_seq, as described below
  
  input_num = length(input_seq);
  input_inc = input_seq(2:end)-input_seq(1);
  input_slope = input_inc./(1:input_num-1)';
  min_slope = input_slope(1);
  max_slope = input_slope(1);
  k = 2;
  
  while (1)
    if (max_slope/min_slope >= 1+tol) || (k >= input_num)
        break;
    end
    if (input_slope(k) < min_slope)
        min_slope = input_slope(k);
    elseif (input_slope(k) > max_slope)
        max_slope = input_slope(k);
    end
    k = k+1;
  end
  
  k=k-1;
  ref_seq = linspace(0,input_inc(k)*(num_sim_marks-1)/k,num_sim_marks)';

end
