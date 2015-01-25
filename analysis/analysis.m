addpath('../../analysis/');

%% Load experiment dependent data
% check the file below, to see what is defined
experiment_data;

% Maximum instantaneous slope, typically equal to the number of cores
max_slope = min(length(cpu_set),length(thread_run));
% Maximum instantaneous slope of one core, typically equal to 1
seq_slope = 1;

%% Per-thread analysis
for i=1:length(thread_run),
    thread_id = thread_run(i);
    % if this thread has a different reference than 'ref_infile' change
    %   the line below
    thread_ref = ref_seq;

    % reading thread data
    %   the format of the k-th row (k starting from 1) is the following
    %
    %    min separation of k consecutive job starts,
    %    job index where min occurs,
    %    max separation of k consecutive job starts,
    %    job index where max occurs
    sim_infile = strcat(experiment_name,'.',num2str(thread_id),'.csv');
    sim_data = csvread(sim_infile);

    %% Computing the supply lower bound delivered to a thread
    % Original data
    lowb_x = sim_data(:,3); % max separations
    % Select points within 'time_horizon'
    lowb_x = lowb_x(lowb_x <= time_horizon);
    lowb_y = ref_seq(1:length(lowb_x));
    % Clean up redundant points. Tolerance used to trade accuracy
    %   (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
    %   (lowb_x_clean, lowb_y_clean) are too big
    tol_cut = 0;
    % Extending with time_horizon, if needed
    if (lowb_x(end) < time_horizon)
        lowb_y = [lowb_y; lowb_y(end)*(1+1e-10)];  % adding eps to avoid numerical problems
        lowb_x = [lowb_x; time_horizon];
    end
    % Invoking curve cleanup
    [lowb_x_clean, lowb_y_clean, lowb_sel_conv] = cleanlowb(lowb_x,lowb_y,seq_slope, tol_cut);
    % Computing the (alpha,Delta) pair maximizing the area below
    %   alpha*(t-Delta) over [Delta,time_horizon]
    [lowb_alpha, lowb_delta] = bestAlphaDelta_low(lowb_x_clean(lowb_sel_conv),lowb_y_clean(lowb_sel_conv));
    fprintf('[ANALYSIS] %s, %s, LOWBALPHADELTA, %f, %f\n', experiment_name, thread_names{thread_id}, lowb_alpha, lowb_delta);
    
    %% Computing the supply upper bound delivered to a thread
    % Original data
    uppb_x = sim_data(:,1); % min separations
    % Select points within 'time_horizon'
    uppb_x = uppb_x(uppb_x <= time_horizon);
    uppb_y = ref_seq(1:length(uppb_x));
    % Clean up redundant points. Tolerance used to trade accuracy
    %   (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
    %   (lowb_x_clean, lowb_y_clean) are too big
    tol_cut = 0;
    % Extending with time_horizon, if needed
    if (uppb_x(end) < time_horizon)
        uppb_y = [uppb_y; min(uppb_y+seq_slope*(1-tol_cut)*(1-1e-10)*(time_horizon-uppb_x))];  % adding eps to avoid numerical problems
        uppb_x = [uppb_x; time_horizon];
    end
    % Invoking curve cleanup
    [uppb_x_clean, uppb_y_clean, uppb_sel_conv] = cleanuppb(uppb_x,uppb_y,seq_slope, tol_cut);
    % Computing the (alpha,burst) pair minimizing the area below the linear
    %   upper bound defined as:
    %   
    %   min(seq_slope*t, alpha*t+burst)
    %
    %   with t spanning over [0,time_horizon]
    [uppb_alpha, uppb_burst] = bestAlphaBurst_upp(uppb_x_clean(uppb_sel_conv),uppb_y_clean(uppb_sel_conv),seq_slope);
    fprintf('[ANALYSIS] %s, %s, UPPBALPHABURST, %f, %f, %f\n', experiment_name, thread_names{thread_id}, uppb_alpha, uppb_burst, -uppb_burst/uppb_alpha);
    if (uppb_alpha < lowb_alpha)
        fprintf('[ANALYSIS] %s, %s, ALPHA_UPP<LOW\n', experiment_name, thread_names{thread_id});
        fprintf('[ANALYSIS]   Try increasing time_horizon and duration of experiment\n');
    end
    
    %% Plotting thread supply
    if (0)        % set it to 1 to print, can only be made with display
        %figure('visible','off');
        figure;
        % supply lower bound
        plot(lowb_x_clean, lowb_y_clean,'r');
        hold on;
        % vertices on the convex hull of the supply lower bound
        plot(lowb_x_clean(lowb_sel_conv), lowb_y_clean(lowb_sel_conv),'ro');
        % linear lower bound
        plot([0;lowb_delta;time_horizon],[0;0;lowb_alpha*(time_horizon-lowb_delta)],'k--');
        % supply upper bound
        plot(uppb_x_clean, uppb_y_clean,'b');
        % vertices on the convex hull of the supply upper bound
        plot(uppb_x_clean(uppb_sel_conv), uppb_y_clean(uppb_sel_conv),'bo');
        % linear upper bound
        plot([0; uppb_burst/(seq_slope-uppb_alpha); time_horizon],[0;uppb_burst/(seq_slope-uppb_alpha)*seq_slope;uppb_alpha*time_horizon+uppb_burst],'k--');
        set(gca,'xlim',[0 time_horizon]);
    
        %% Choose one of the following formats
        
        % printing EPS (both Matlab and Octave compatible)
        %figure_outfile = strcat(experiment_name,'.',num2str(thread_id),'.supply.eps');
        %print(figure_outfile,'-deps');
        %fprintf('[ANALYSIS] %s, %s, SUPPLYFIGURE, %s\n', experiment_name, thread_names{thread_id}, figure_outfile);
        
        % printing XFig (only Octave compatible)
        figure_outfile = strcat(experiment_name,'.',num2str(thread_id),'.supply.fig');
        print(figure_outfile,'-dfig');
        fprintf('[ANALYSIS] %s, %s, SUPPLYFIGURE, %s\n', experiment_name, thread_names{thread_id}, figure_outfile);
    end
end

%% Overall analysis
sim_infile = strcat(experiment_name,'.all.csv');
sim_data = csvread(sim_infile);

%% Computing the supply lower bound of the entire platform
% original data
lowb_x = sim_data(:,3); % max separations
% select points within 'time_horizon'
lowb_x = lowb_x(lowb_x <= time_horizon);
lowb_y = ref_seq(1:length(lowb_x));
% extending with time_horizon, if needed
if (lowb_x(end) < time_horizon)
    lowb_x = [lowb_x; time_horizon];
    lowb_y = [lowb_y; lowb_y(end)*(1+1e-10)];  % adding eps to avoid numerical problems
end
% clean up redundant points. Tolerance used to trade accuracy
%   (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
%   (lowb_x_clean, lowb_y_clean) are too big
tol_cut = 0;
[lowb_x_clean, lowb_y_clean, lowb_sel_conv] = cleanlowb(lowb_x,lowb_y,max_slope, tol_cut);
% computing the (alpha,Delta) pair maximizing the area below
%   alpha*(t-Delta) over [Delta,time_horizon]
[lowb_alpha, lowb_delta] = bestAlphaDelta_low(lowb_x_clean(lowb_sel_conv),lowb_y_clean(lowb_sel_conv));
fprintf('[ANALYSIS] %s, all, LOWBALPHADELTA, %f, %f\n', experiment_name, lowb_alpha, lowb_delta);

%% Computing the supply upper bound  of the entire platform
% Original data
uppb_x = sim_data(:,1); % min separations
% Select points within 'time_horizon'
uppb_x = uppb_x(uppb_x <= time_horizon);
uppb_y = ref_seq(1:length(uppb_x));
% Clean up redundant points. Tolerance used to trade accuracy
%   (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
%   (lowb_x_clean, lowb_y_clean) are too big
tol_cut = 0;
% Extending with time_horizon, if needed
if (uppb_x(end) < time_horizon)
    uppb_y = [uppb_y; min(uppb_y+max_slope*(1-tol_cut)*(1-1e-10)*(time_horizon-uppb_x))];  % adding eps to avoid numerical problems
    uppb_x = [uppb_x; time_horizon];
end
% Invoking curve cleanup
[uppb_x_clean, uppb_y_clean, uppb_sel_conv] = cleanuppb(uppb_x,uppb_y,max_slope, tol_cut);
% Computing the (alpha,burst) pair minimizing the area below the linear
%   upper bound defined as:
%
%   min(max_slope*t, alpha*t+burst)
%
%   with t spanning over [0,time_horizon]
[uppb_alpha, uppb_burst] = bestAlphaBurst_upp(uppb_x_clean(uppb_sel_conv),uppb_y_clean(uppb_sel_conv),max_slope);
fprintf('[ANALYSIS] %s, all, UPPBALPHABURST, %f, %f, %f\n', experiment_name, uppb_alpha, uppb_burst, -uppb_burst/uppb_alpha);
if (uppb_alpha < lowb_alpha)
    fprintf('[ANALYSIS] %s, all, ALPHA_UPP<LOW\n', experiment_name);
    fprintf('[ANALYSIS]   Try increasing time_horizon and duration of experiment\n');
end
    
%% Plotting platform supply
if (0)        % set it to 1 to print, can only be made with display
    %figure('visible','off');
    figure;
    % supply lower bound
    plot(lowb_x_clean, lowb_y_clean,'r');
    hold on;
    % vertices on the convex hull of the supply lower bound
    plot(lowb_x_clean(lowb_sel_conv), lowb_y_clean(lowb_sel_conv),'ro');
    % linear lower bound
    plot([0;lowb_delta;time_horizon],[0;0;lowb_alpha*(time_horizon-lowb_delta)],'k--');
    % supply upper bound
    plot(uppb_x_clean, uppb_y_clean,'b');
    % vertices on the convex hull of the supply upper bound
    plot(uppb_x_clean(uppb_sel_conv), uppb_y_clean(uppb_sel_conv),'bo');
    % linear upper bound
    plot([0; uppb_burst/(max_slope-uppb_alpha); time_horizon],[0;uppb_burst/(max_slope-uppb_alpha)*max_slope;uppb_alpha*time_horizon+uppb_burst],'k--');
    set(gca,'xlim',[0 time_horizon]);
    
    %% Choose one of the following formats
    
    % printing EPS (both Matlab and Octave compatible)
    %figure_outfile = strcat(experiment_name,'.all.supply.eps');
    %print(figure_outfile,'-deps');
    %fprintf('[ANALYSIS] %s, all, SUPPLYFIGURE, %s\n', experiment_name, figure_outfile);
    
    % printing XFig (only Octave compatible)
    figure_outfile = strcat(experiment_name,'.all.supply.fig');
    print(figure_outfile,'-dfig');
    fprintf('[ANALYSIS] %s, all, SUPPLYFIGURE, %s\n', experiment_name, figure_outfile);
end
