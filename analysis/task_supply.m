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
    experim_json = task_minmax(experiment_name,experim_json,task_id);

    %% ADD SUPPLY FUNCTION COMPUTATION HERE
    
end