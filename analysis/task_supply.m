function experim_json = task_supply(experiment_name,experim_json,task_id)

    %% If already executed, do not run
    tasks_names = fieldnames(experim_json.tasks);
    cur_task = experim_json.tasks.(tasks_names{task_id});
    if (ismember('results',fieldnames(cur_task)))
        if (ismember('supply',fieldnames(cur_task.results)))
            return
        end
    end
    %% Checking dependecies
    experim_json = refjob(experiment_name,experim_json);
    ref_job = experim_json.global.results.refjob;
    experim_json = task_minmax(experiment_name,experim_json,task_id);
    cur_task = experim_json.tasks.(tasks_names{task_id});

    %% Getting minmax separations
    cd(tasks_names{task_id});
    sim_infile = 'minmax.csv';
    sim_data = csvread(sim_infile);
    cd ..;

    %% Computing the supply lower bound delivered to a thread
    % Original data
    lowb_x = sim_data(:,3); % max separations
    lowb_y = ref_job*(0:length(lowb_x)-1)';
    
    %% Clean up redundant points. Tolerance used to trade accuracy
    %   (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
    %   (lowb_x_clean, lowb_y_clean) are too big
    tol_cut = 0;     % in future, this may become an option in analysis.supply
    % Invoking curve cleanup, seq_slope set to 1 for single task
    [lowb_x_clean, lowb_y_clean, lowb_sel_conv] = cleanlowb(lowb_x,lowb_y,1, tol_cut);
%    [lowb_x_clean, lowb_y_clean, lowb_sel_conv] = cleanlowb(lowb_x,lowb_y,seq_slope, tol_cut);
    slbf_file = 'supply.slbf.csv';
    cd(tasks_names{task_id});
    csvwrite(slbf_file, [lowb_x_clean lowb_y_clean]);
    cd ..;
    cur_task.results.supply.slbf.data = slbf_file;
    cur_task.results.supply.slbf.conv = lowb_sel_conv;
    % Longest blocking is the sup{t:slbf(t)=0}
    cur_task.results.supply.slbf.maxblock = lowb_x_clean(2);

    %% Computing the (alpha,Delta) pair maximizing the area below
    horizon = experim_json.global.duration/10;  % FIXME: now it is a magic number, better an option
    %   alpha*(t-Delta) over [Delta,horizon]
    [lowb_alpha, lowb_delta] = bestAlphaDelta_low(lowb_x_clean(lowb_sel_conv),lowb_y_clean(lowb_sel_conv),horizon);
    cur_task.results.supply.slbf.horizon = horizon;
    cur_task.results.supply.slbf.alpha = lowb_alpha;
    cur_task.results.supply.slbf.delta = lowb_delta;
    
    %% Computing the supply upper bound delivered to a thread
    % Original data
    uppb_x = sim_data(:,1); % min separations
    uppb_y = ref_job*(0:length(uppb_x)-1)';

    %% Clean up redundant points. Tolerance used to trade accuracy
    %   (tol_cut=0) vs. efficiency (larger tol_cut). Set it to zero, unless
    %   (lowb_x_clean, lowb_y_clean) are too big
    tol_cut = 0;     % in future, this may become an option in analysis.supply
    % Invoking curve cleanup, seq_slope set to 1 for single task
    [uppb_x_clean, uppb_y_clean, uppb_sel_conv] = cleanuppb(uppb_x,uppb_y,1, tol_cut);
%    [uppb_x_clean, uppb_y_clean, uppb_sel_conv] = cleanuppb(uppb_x,uppb_y,seq_slope, tol_cut);
    subf_file = 'supply.subf.csv';
    cd(tasks_names{task_id});
    csvwrite(subf_file, [uppb_x_clean uppb_y_clean]);
    cd ..;
    cur_task.results.supply.subf.data = subf_file;
    cur_task.results.supply.subf.conv = uppb_sel_conv;

    %% Computing the (alpha,burst) pair minimizing the area below the linear
    %   upper bound defined as:
    %   
    %   min(seq_slope*t, alpha*t+burst)
    %
    %   with t spanning over [0,horizon], seq_slope set to 1 for single
    %     task
    [uppb_alpha, uppb_burst] = bestAlphaBurst_upp(uppb_x_clean(uppb_sel_conv),uppb_y_clean(uppb_sel_conv),horizon,1);
    cur_task.results.supply.subf.horizon = horizon;
    cur_task.results.supply.subf.alpha = uppb_alpha;
    cur_task.results.supply.subf.delta = -uppb_burst/uppb_alpha;

    %% Computing linear bounds with minimum distance
    [best_alpha, best_delta_low, best_delta_upp] = bestAlphaDelta(lowb_x_clean(lowb_sel_conv),lowb_y_clean(lowb_sel_conv),uppb_x_clean(uppb_sel_conv),uppb_y_clean(uppb_sel_conv));
    cur_task.results.supply.linbounds.alpha = best_alpha;
    cur_task.results.supply.linbounds.deltalowb = best_delta_low;
    cur_task.results.supply.linbounds.deltauppb = best_delta_upp;
    
    %% Conclusion
    experim_json.tasks.(tasks_names{task_id}) = cur_task;
    savejson('',experim_json,strcat(experiment_name,'.output.json'));    
end