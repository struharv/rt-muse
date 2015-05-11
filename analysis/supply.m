function experim_json = supply(experiment_name, experim_json)

  %% If already executed, do not run
  if (ismember('results',fieldnames(experim_json.global)))
    if (ismember('supply',fieldnames(experim_json.global.results)))
      return
    end
  end

  %% Checking dependecies
  experim_json = refjob(experiment_name,experim_json);
  ref_job = experim_json.global.results.refjob;
  experim_json = minmax(experiment_name,experim_json);

  %% Computing number of CPUs on which tasks are running
  thread_names = fieldnames(experim_json.threads);
  thread_num = size(thread_names, 1);
  cpu_set = []; % init with empty set, then add other CPUs
  affinities = cell(thread_num, 1);
  for i=1:thread_num,
    cpu_cur = sort(experim_json.threads.(thread_names{i}).cpus);
    affinities{i,1} = cpu_cur;
    cpu_set = union(cpu_set, cpu_cur);
  end
  cpu_num = length(cpu_set);

  %% Counting tasks in the set
  tasks_names = fieldnames(experim_json.threads);
  tasks_num = size(tasks_names, 1);
  tasks_in_set = 0;
  for task_id=1:tasks_num,
    % only tasks with 'analysis' section are considered in the set
    if ismember('analysis',fieldnames(experim_json.threads.(tasks_names{task_id})))
      tasks_in_set = tasks_in_set +1;
    end
  end
  max_slope = min(cpu_num,tasks_in_set);

  %% Getting minmax separations
  sim_infile = 'global/minmax.csv';
  sim_data = csvread(sim_infile);

  %% Computing the supply lower bound delivered
  % Original data
  lowb_x = sim_data(:,3); % max separations
  lowb_y = ref_job*(0:length(lowb_x)-1)';

  %% Clean up redundant points. Tolerance used to trade accuracy
  % (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
  % (lowb_x_clean, lowb_y_clean) are too big
  tol_cut = 0;     % in future, this may become an option in analysis.supply

  % Invoking curve cleanup
  [lowb_x_clean, lowb_y_clean, lowb_sel_conv] = cleanlowb(lowb_x,lowb_y,max_slope, tol_cut);
  slbf_file = 'global/supply.slbf.csv';
  csvwrite(slbf_file, [lowb_x_clean lowb_y_clean]);
  experim_json.global.results.supply.slbf.data = slbf_file;
  experim_json.global.results.supply.slbf.conv = lowb_sel_conv;

  %% Computing the (alpha,Delta) pair maximizing the area below
  horizon = experim_json.global.duration/10;  % FIXME: now it is a magic number, better an option
  % alpha*(t-Delta) over [Delta,horizon]
  [lowb_alpha, lowb_delta] = bestAlphaDelta_low(lowb_x_clean(lowb_sel_conv),lowb_y_clean(lowb_sel_conv),horizon);
  experim_json.global.results.supply.slbf.horizon = horizon;
  experim_json.global.results.supply.slbf.alpha = lowb_alpha;
  experim_json.global.results.supply.slbf.delta = lowb_delta;

  %% Computing the supply upper bound delivered to a thread
  % Original data
  uppb_x = sim_data(:,1); % min separations
  uppb_y = ref_job*(0:length(uppb_x)-1)';

  %% Clean up redundant points. Tolerance used to trade accuracy
  % (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
  % (lowb_x_clean, lowb_y_clean) are too big
  tol_cut = 0;     % in future, this may become an option in analysis.supply

  % Invoking curve cleanup
  [uppb_x_clean, uppb_y_clean, uppb_sel_conv] = cleanuppb(uppb_x,uppb_y,max_slope, tol_cut);
  subf_file = 'global/supply.subf.csv';
  csvwrite(subf_file, [uppb_x_clean uppb_y_clean]);
  experim_json.global.results.supply.subf.data = subf_file;
  experim_json.global.results.supply.subf.conv = uppb_sel_conv;

  %% Computing the (alpha,burst) pair minimizing the area below the linear
  % upper bound defined as min(seq_slope*t, alpha*t+burst) with t spanning 
  % over [0, horizon]
  [uppb_alpha, uppb_burst] = bestAlphaBurst_upp(uppb_x_clean(uppb_sel_conv),uppb_y_clean(uppb_sel_conv),horizon,max_slope);
  experim_json.global.results.supply.subf.horizon = horizon;
  experim_json.global.results.supply.subf.alpha = uppb_alpha;
  experim_json.global.results.supply.subf.delta = -uppb_burst/uppb_alpha;

  %% Computing linear bounds with minimum distance
  [best_alpha, best_delta_low, best_delta_upp] = bestAlphaDelta(lowb_x_clean(lowb_sel_conv),lowb_y_clean(lowb_sel_conv),uppb_x_clean(uppb_sel_conv),uppb_y_clean(uppb_sel_conv));
  experim_json.global.results.supply.linbounds.alpha = best_alpha;
  experim_json.global.results.supply.linbounds.deltalowb = best_delta_low;
  experim_json.global.results.supply.linbounds.deltauppb = best_delta_upp;

  %% Conclusion
  savejson('',experim_json,strcat(experiment_name,'.output.json'));

end