%function [mean_vec,var_vec,cov_mat] = varCov(sequence)
function [mean_vec,var_vec] = mean_var(sequence)
% MEAN_VAR  Computes average, variance of separations
%   INPUT
%     - sequence, is a column vector of timestamps
%   OUTPUT
%     - mean_vec, is a column vector of length length(sequence)-1.
%       mean_vec(i) is the average of the sum of i consecutive intervals
%     - var_vec,  is a column vector of length length(sequence)-1.
%       var_vec(i) is the variance of the sum of i consecutive intervals.
%       It can be use to determine the quality of the data. When the
%       variance decreases with i it means that the uncertainty on amont of
%       allocated resource decreases over the length of the interval. This
%       is a quite clear indication of a too short simulation window.
%       Unless the scheduler is built to provide such a guarantee (such as
%       SCHED_RR)

num_intervals = length(sequence)-1;
intervals = diff(sequence);
%exit
intervals_tmp = zeros(num_intervals+1,1);

% initializations
mean_vec = zeros(num_intervals,1);
var_vec  = zeros(num_intervals,1);
cov_mat  = zeros(num_intervals,num_intervals);

% computation of average and variance
for i = 1:num_intervals,
    intervals_tmp = intervals_tmp(1:end-1) + intervals(i:end);
    mean_vec(i) = mean(intervals_tmp);
    var_vec(i) = var(intervals_tmp);
%    cov_mat(i,i) = var_vec(i);
end

% computation of covariances
%for i = 1:num_intervals,
%    for j=i+1:num_intervals-i,
%        cov_mat(i,j) = (var_vec(i+j)-var_vec(i)-var_vec(j))/2;
%        cov_mat(j,i) = cov_mat(i,j);
%    end
%end

end
