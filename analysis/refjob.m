function experim_json = refjob(experiment_name,experim_json)
% REFJOB Computes the reference job

    %% If already executed, do not run
    if (ismember('results',fieldnames(experim_json.global)))
        if (ismember('refjob',fieldnames(experim_json.global.results)))
            return
        end
    end
    
    %% Checking dependecies
    tasks_names = fieldnames(experim_json.tasks);
    tasks_num = size(tasks_names, 1);
    % refjob depends:
    %   - on minmax for all tasks with an analysis section
    %     tasks without an analysis section are considered disturbance
    %   - window, if a task did never
    experim_json = window(experiment_name,experim_json);
    ref_job = +inf;       % init ref_job with big value
    for task_id=1:tasks_num,
        % only tasks with analysis section are considered to contribute to
        %    the refjob
        if ismember('analysis',fieldnames(experim_json.tasks.(tasks_names{task_id})))
            % only tasks which run at least once can be considered
            if experim_json.tasks.(tasks_names{task_id}).results.run
                experim_json = task_minmax(experiment_name,experim_json,task_id);
                % only tasks with at least two marks can be considered
                if (experim_json.tasks.(tasks_names{task_id}).results.num_marks >= 2)
                    % import minmax file of task task_id
                    infile = [tasks_names{task_id}, '/', experim_json.tasks.(tasks_names{task_id}).results.minmax];
                    task_data = csvread(infile);
                    % task_data(2,1) is the shortest task job
                    if (task_data(2,1) < ref_job)
                        % update shortest job
                        ref_job = task_data(2,1);
                    end
                end
            end
        end
    end
    
    experim_json.global.results.refjob = ref_job;
    savejson('',experim_json,strcat(experiment_name,'.output.json'));    % FIXME: better to extend the digits of floats
end
