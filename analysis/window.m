function experim_json = window(experiment_name,experim_json)
% WINDOW Computed the experiment window

    %% If already executed, do not run
    if (ismember('results',fieldnames(experim_json.global)))
        if (ismember('window',fieldnames(experim_json.global.results)))
            return
        end
    end
    
    %% Importing data from 'experiment_name.csv'
    input_file = strcat(experiment_name,'.csv');
    full_data = csvread(input_file);

    %% Checking if task did ever run
    tasks_names = fieldnames(experim_json.tasks);
    tasks_num = size(tasks_names, 1);
    tasks_run = unique(full_data(:,2));
    for i=1:tasks_num,
        if ismember(i,tasks_run)
            experim_json.tasks.(tasks_names{i}).results.run = true;
        else
            experim_json.tasks.(tasks_names{i}).results.run = false;
        end
    end
    
    %% Loop on threads to compute the time windows only
    for k = 1:length(tasks_run),
        tasks_id = tasks_run(k);
        tasks_data = full_data((full_data(:,2) == tasks_id),[1 3]);
        tasks_window(tasks_id,1) = min(tasks_data(:,1));
        tasks_window(tasks_id,2) = max(tasks_data(:,1));
    end
    
    %% Check if task run too shortly (if so its timestamps are not used for the window)
    tasks_short_exec = (1:tasks_num)';     % init
    % 10 below is a MAGIC NUMBER
    tasks_short_exec = tasks_short_exec((tasks_window(:,2)-tasks_window(:,1)) <= experim_json.global.duration/10);
    for i=1:tasks_num,
        if ismember(i,tasks_short_exec)
            experim_json.tasks.(tasks_names{i}).results.short_run = true;
        else
            experim_json.tasks.(tasks_names{i}).results.short_run = false;
        end
    end
    tasks_run = setdiff(tasks_run,tasks_short_exec);
  
    % interval in which all threads, which started once, have at least one
    % pending job
    
    experim_json.global.results.window = [max(tasks_window(tasks_run,1)) min(tasks_window(tasks_run,2))];
    opt.FloatFormat = '%15g';
%    savejson('',experim_json,strcat(experiment_name,'.json'),'FloatFormat','%15g');
    savejson('',experim_json,strcat(experiment_name,'.output.json'));    % FIXME: better to extend the digits of floats
    
end
