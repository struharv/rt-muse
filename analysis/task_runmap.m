function experim_json = task_runmap(experiment_name,experim_json,task_id)

    %% If already executed, do not run
    tasks_names = fieldnames(experim_json.tasks);
    cur_task = experim_json.tasks.(tasks_names{task_id});
    if (ismember('results',fieldnames(cur_task)))
        if (ismember('runmap',fieldnames(cur_task.results)))
            return
        end
    end

    %% TODO: write me

    %% Conclusion
    experim_json.tasks.(tasks_names{task_id}) = cur_task;
    savejson('',experim_json,strcat(experiment_name,'.output.json'));   
end