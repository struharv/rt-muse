addpath('../../analysis/');

%% Load experiment dependent data
% check the file below, to see what is defined
experiment_data;

% Maximum instantaneous slope, typically equal to the number of cores
max_slope = min(length(cpu_set),length(thread_run));
% Maximum instantaneous slope of one core, typically equal to 1
seq_slope = 1;

% File in which all analysis data is written
out_file = strcat(experiment_name,'.output.txt');
fid = fopen(out_file,'a');   % append if existing
fprintf(fid,'%s,WIN_LENGTH,%f\n', experiment_name, analysis_window(2)-analysis_window(1));
fprintf(fid,'%s,CPU_SET,%s\n', experiment_name, mat2str(cpu_set));

%% Per-thread analysis
for i=1:length(thread_run),
    thread_id = thread_run(i);
    % if this thread has a different reference than 'ref_infile' change
    %   the line below

    fprintf(fid,'%s,%s,JOBS_IN_WIN,%d\n', experiment_name, thread_names{thread_id}, thread_nJobs(thread_id));
    fprintf(fid,'%s,%s,MIGR_IN_WIN,%d\n', experiment_name, thread_names{thread_id}, migr_nJobs(thread_id));
    fprintf(fid,'%s,%s,CPU_SHARE,%s\n', experiment_name, thread_names{thread_id}, mat2str(run_map(thread_id,:)));
    
%    thread_ref = ref_seq;
    % reading thread data
    %   the format of the k-th row (k starting from 1) is the following
    %
    %    min separation of k consecutive job starts,
    %    job index where min occurs,
    %    max separation of k consecutive job starts,
    %    job index where max occurs
    sim_infile = strcat(experiment_name,'.',num2str(thread_id),'.minmax.csv');
    sim_data = csvread(sim_infile);

    %% Computing the supply lower bound delivered to a thread
    % Original data
    lowb_x = sim_data(:,3); % max separations
%    lowb_y = ref_seq(1:length(lowb_x));
    lowb_y = ref_job*(0:length(lowb_x)-1)';
    
    % Clean up redundant points. Tolerance used to trade accuracy
    %   (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
    %   (lowb_x_clean, lowb_y_clean) are too big
    tol_cut = 0;
    % Invoking curve cleanup
    [lowb_x_clean, lowb_y_clean, lowb_sel_conv] = cleanlowb(lowb_x,lowb_y,seq_slope, tol_cut);
    slbf_file = strcat(experiment_name,'.',num2str(thread_id),'.slbf.csv');
    csvwrite(slbf_file, [lowb_x_clean lowb_y_clean]);
    fprintf(fid,'%s,%s,SLBF_FILE,%s\n', experiment_name, thread_names{thread_id}, slbf_file);
    fprintf(fid,'%s,%s,SLBF_CONV_IDX,%s\n', experiment_name, thread_names{thread_id}, mat2str(lowb_sel_conv));

    % Longest blocking is the sup{t:slbf(t)=0}
    fprintf(fid,'%s,%s,MAXBLOCK,%f\n', experiment_name, thread_names{thread_id}, lowb_x_clean(2));

    % Computing the (alpha,Delta) pair maximizing the area below
    %   alpha*(t-Delta) over [Delta,time_horizon]
    [lowb_alpha, lowb_delta] = bestAlphaDelta_low(lowb_x_clean(lowb_sel_conv),lowb_y_clean(lowb_sel_conv),time_horizon);
    fprintf(fid,'%s,%s,SLBF_ALPHADELTA,%f,%f\n', experiment_name, thread_names{thread_id}, lowb_alpha, lowb_delta);
    
    %% Computing the supply upper bound delivered to a thread
    % Original data
    uppb_x = sim_data(:,1); % min separations
 %   uppb_y = ref_seq(1:length(uppb_x));
    uppb_y = ref_job*(0:length(uppb_x)-1)';

    % Clean up redundant points. Tolerance used to trade accuracy
    %   (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
    %   (lowb_x_clean, lowb_y_clean) are too big
    tol_cut = 0;
    % Invoking curve cleanup
    [uppb_x_clean, uppb_y_clean, uppb_sel_conv] = cleanuppb(uppb_x,uppb_y,seq_slope, tol_cut);
    subf_file = strcat(experiment_name,'.',num2str(thread_id),'.subf.csv');
    csvwrite(subf_file, [uppb_x_clean uppb_y_clean]);
    fprintf(fid,'%s,%s,SUBF_FILE,%s\n', experiment_name, thread_names{thread_id}, subf_file);
    fprintf(fid,'%s,%s,SUBF_CONV_IDX,%s\n', experiment_name, thread_names{thread_id}, mat2str(uppb_sel_conv));

    % Computing the (alpha,burst) pair minimizing the area below the linear
    %   upper bound defined as:
    %   
    %   min(seq_slope*t, alpha*t+burst)
    %
    %   with t spanning over [0,time_horizon]
    [uppb_alpha, uppb_burst] = bestAlphaBurst_upp(uppb_x_clean(uppb_sel_conv),uppb_y_clean(uppb_sel_conv),time_horizon,seq_slope);
    fprintf(fid,'%s,%s,SUBF_ALPHADELTA,%f,%f\n', experiment_name, thread_names{thread_id}, uppb_alpha, -uppb_burst/uppb_alpha);

    %% Computing linear bounds with minimum distance
    [best_alpha, best_delta_low, best_delta_upp] = bestAlphaDelta(lowb_x_clean(lowb_sel_conv),lowb_y_clean(lowb_sel_conv),uppb_x_clean(uppb_sel_conv),uppb_y_clean(uppb_sel_conv));
    fprintf(fid,'%s,%s,ALPHADELTAS,%f,%f,%f\n', experiment_name, thread_names{thread_id}, best_alpha, best_delta_low, best_delta_upp);

    %% Computing a good and quick approximation of alpha_i'
    fprintf(fid,'%s,%s,JUSTALPHA,%f\n', experiment_name, thread_names{thread_id}, lowb_y(end)/lowb_x(end));
    
    fprintf('[ANALYSIS] Analysis of thread ''%s'' ... Done\n',thread_names{thread_id});
end

%% Overall analysis
sim_infile = strcat(experiment_name,'.all.minmax.csv');
sim_data = csvread(sim_infile);

%% Computing the supply lower bound of the entire platform
% Original data
lowb_x = sim_data(:,3); % max separations
%lowb_y = ref_seq(1:length(lowb_x));
lowb_y = ref_job*(0:length(lowb_x)-1)';

% Clean up redundant points. Tolerance used to trade accuracy
%   (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
%   (lowb_x_clean, lowb_y_clean) are too big
tol_cut = 0;
% Invoking curve cleanup
[lowb_x_clean, lowb_y_clean, lowb_sel_conv] = cleanlowb(lowb_x,lowb_y,max_slope, tol_cut);
slbf_file = strcat(experiment_name,'.all.slbf.csv');
csvwrite(slbf_file, [lowb_x_clean lowb_y_clean]);
fprintf(fid,'%s,all,SLBF_FILE,%s\n', experiment_name, slbf_file);
fprintf(fid,'%s,all,SLBF_CONV_IDX,%s\n', experiment_name, mat2str(lowb_sel_conv));

% Computing the (alpha,Delta) pair maximizing the area below
%   alpha*(t-Delta) over [Delta,time_horizon]
[lowb_alpha, lowb_delta] = bestAlphaDelta_low(lowb_x_clean(lowb_sel_conv),lowb_y_clean(lowb_sel_conv),time_horizon);
fprintf(fid,'%s,all,SLBF_ALPHADELTA,%f,%f\n', experiment_name, lowb_alpha, lowb_delta);

%% Computing the supply upper bound  of the entire platform
% Original data
uppb_x = sim_data(:,1); % min separations
%uppb_y = ref_seq(1:length(uppb_x));
uppb_y = ref_job*(0:length(uppb_x)-1)';

% Clean up redundant points. Tolerance used to trade accuracy
%   (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
%   (lowb_x_clean, lowb_y_clean) are too big
tol_cut = 0;
% Invoking curve cleanup
[uppb_x_clean, uppb_y_clean, uppb_sel_conv] = cleanuppb(uppb_x,uppb_y,max_slope, tol_cut);
subf_file = strcat(experiment_name,'.all.subf.csv');
csvwrite(subf_file, [uppb_x_clean uppb_y_clean]);
fprintf(fid,'%s,all,SUBF_FILE,%s\n', experiment_name, subf_file);
fprintf(fid,'%s,all,SUBF_CONV_IDX,%s\n', experiment_name, mat2str(uppb_sel_conv));

% Computing the (alpha,burst) pair minimizing the area below the linear
%   upper bound defined as:
%
%   min(seq_slope*t, alpha*t+burst)
%
%   with t spanning over [0,time_horizon]
[uppb_alpha, uppb_burst] = bestAlphaBurst_upp(uppb_x_clean(uppb_sel_conv),uppb_y_clean(uppb_sel_conv),time_horizon,max_slope);
fprintf(fid,'%s,all,SUBF_ALPHADELTA,%f,%f\n', experiment_name, uppb_alpha, -uppb_burst/uppb_alpha);

%% Computing linear bounds with minimum distance
[best_alpha, best_delta_low, best_delta_upp] = bestAlphaDelta(lowb_x_clean(lowb_sel_conv),lowb_y_clean(lowb_sel_conv),uppb_x_clean(uppb_sel_conv),uppb_y_clean(uppb_sel_conv));
fprintf(fid,'%s,all,ALPHADELTAS,%f,%f,%f\n', experiment_name, best_alpha, best_delta_low, best_delta_upp);

%% Computing a good and quick approximation of alpha_i'
fprintf(fid,'%s,all,JUSTALPHA,%f\n', experiment_name, lowb_y(end)/lowb_x(end));

fprintf('[ANALYSIS] Analysis of all threads ... Done\n');
fprintf('[ANALYSIS] All output data written to %s\n',out_file);

fclose(fid);
