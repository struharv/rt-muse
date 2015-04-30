function experim_json = task_statistical(experiment_name,experim_json,task_id)

    %% If already executed, do not run
    tasks_names = fieldnames(experim_json.tasks);
    cur_task = experim_json.tasks.(tasks_names{task_id});
    if (ismember('results',fieldnames(cur_task)))
        if (ismember('statistical',fieldnames(cur_task.results)))
            return
        end
    end

    %% Checking dependecies
    experim_json = task_marks(experiment_name,experim_json,task_id);
    cur_task = experim_json.tasks.(tasks_names{task_id});
    
    %% Loading marks
    infile = cur_task.results.marks;
    timestamps = csvread(infile);
    
    %% Computing average/variance/covariances of each thread
    num_intervals = length(timestamps)-1;
    intervals = diff(timestamps);
    intervals_tmp = zeros(num_intervals+1,1);

    % initializations
    mean_vec = zeros(num_intervals,1);
    var_vec  = zeros(num_intervals,1);

    % look on number of consecutive marks
    for i = 1:num_intervals,
        intervals_tmp = intervals_tmp(1:end-1) + intervals(i:end);
        mean_vec(i) = mean(intervals_tmp);
        var_vec(i) = var(intervals_tmp);
    end
    
    %% Write statistical to task dependent file
    cd(tasks_names{task_id});
    output_file = strcat('statistical.csv');
    fid = fopen(output_file,'w+');
    fprintf(fid,'%13.9f, %13.9f\n', [mean_vec, var_vec]');
    fclose(fid);
    cd ..;
    cur_task.results.statistical = output_file;

    %% Update json file
    experim_json.tasks.(tasks_names{task_id}) = cur_task;
    savejson('',experim_json,strcat(experiment_name,'.output.json'));    
end