function process(resultdir, name_reference, name_test)

% ----------------------------------------------------------------------
% resultdir      = '/home/martina/Desktop/results/';
% name_reference = 'lock0';
% name_test      = 'lock';
% ----------------------------------------------------------------------

log_reference  = strcat(resultdir, name_reference, '/', name_reference, '.csv');
log_test       = strcat(resultdir, name_test, '/', name_test, '.csv');
max_samples = 1000;
content_reference = csvread(log_reference);
content_test      = csvread(log_test);
time_reference = content_reference(:,1)'; % reference time
time_test  = content_test(:,1)'; % test time

% Analyzing the reference sequence
[reference_min, reference_idx_min, ...
  reference_max, reference_idx_max] = ...
  minmaxseq(time_reference, max_samples);
spaced_reference = linspace(reference_min(1), reference_min(end), length(reference_min));

% Analyzing the test sequence
[test_min, test_idx_min, ...
  test_max, test_idx_max] = ...
  minmaxseq(time_test, max_samples);

% Computation of alpha and Delta
alpha = spaced_reference(max_samples) / test_max(max_samples);
[Delta, indexDelta] = max(test_max - spaced_reference * (1/alpha));
fprintf('[PROCESS.M] The test sequence has alpha %.4f and Delta %.4f.\n', alpha, Delta);

% Displaying figure
figure(1);
hold on;
plot(test_max, spaced_reference, 'bx-'); % lower bound
plot(test_min, spaced_reference, 'rx-'); % upper bound

end
