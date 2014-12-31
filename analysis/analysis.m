addpath('../../analysis/');

% loading experiment dependent data from file
experiment_data;

% maximum instantaneous slope, typically equal to the number of cores
max_slope = length(cpu_set);
% maximum instantaneous slope of one core, typically equal to 1
seq_slope = 1;

% per-thread analysis
for i = 1:length(thread_run),

  thread_id = thread_run(i);
  % if this thread has a different reference than 'ref_infile' change
  % the line below
  thread_ref = ref_seq;

  % reading thread data
  % the format of the k-th row (k starting from 1) is the following
  %   min separation of k consecutive job starts,
  %   job index where min occurs,
  %   max separation of k consecutive job starts,
  %   job index where max occurs
  sim_infile = strcat(experiment_name,'.',num2str(thread_id),'.csv');
  sim_data = csvread(sim_infile);

  % computing the supply lower bound
  lowb_x = sim_data(:,3); %  original data, max separations
  
  % select points within 'time_horizon'
  lowb_x = lowb_x(lowb_x <= time_horizon);
  lowb_y = ref_seq(1:length(lowb_x));
  
  % extending with time_horizon, if needed
  if (lowb_x(end) < time_horizon)
    lowb_x = [lowb_x; time_horizon];
    % adding eps to avoid numerical problems
    lowb_y = [lowb_y; lowb_y(end)*(1+1e-10)];
  end
  
  % clean up redundant points. Tolerance used to trade accuracy
  % (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
  % (lowb_x_clean, lowb_y_clean) are too big
  tol_cut = 0;
  [lowb_x_clean, lowb_y_clean, sel_conv] = ...
    cleanlowb(lowb_x,lowb_y,seq_slope, tol_cut);
    
  % computing the (alpha, Delta) pair maximizing the area below
  %   alpha*(t-Delta) over [Delta, time_horizon]
  [alpha, delta] = bestAlphaDelta(lowb_x_clean(sel_conv), lowb_y_clean(sel_conv));
  fprintf('[ANALYSIS] %s, %s, LOWBALPHADELTA, %f, %f\n',...
    experiment_name, thread_names{thread_id}, alpha, delta);

  % computing the supply upper bound
  uppb_x = sim_data(:,1); % original data, min separations
  uppb_x = uppb_x(uppb_x <= time_horizon);
  uppb_y = ref_seq(1:length(uppb_x));

  % plotting
  % figure(thread_id);
  % hold on;
  % plot(lowb_x,lowb_y,'r');
  % plot(lowb_x_clean,lowb_y_clean,'b');
  % plot(uppb_x,uppb_y,'b');
  
end

