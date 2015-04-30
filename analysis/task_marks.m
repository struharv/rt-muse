function experim_json = task_marks(experiment_name,experim_json,task_id)
% TASK_MARKS  Write absolute timestamps to file and reconstruct if needed

    %% If already executed, do not run
    tasks_names = fieldnames(experim_json.tasks);
    cur_task = experim_json.tasks.(tasks_names{task_id});
    if (ismember('results',fieldnames(cur_task)))
        if (ismember('marks',fieldnames(cur_task.results)))
            return
        end
    end
        
    %% Checking dependecies
    experim_json = window(experiment_name,experim_json);

    %% Importing data from 'experiment_name.csv'
    input_file = strcat(experiment_name,'.csv');
    full_data = csvread(input_file);

    % select #Time, #Job-number
    task_data = full_data((full_data(:,2) == task_id),[1 3]);

    % only data in time window
    task_data = ...
        task_data((task_data(:,1) >= experim_json.global.results.window(1)) & (task_data(:,1) <= experim_json.global.results.window(2)),:);
    num_rows = size(task_data,1);

    %% Checking whether the mark at the begin of some job was lost
    num_jobs = task_data(num_rows,2) - task_data(1,2) + 1;
    timestamps = -ones(num_jobs,1); % init
    timestamps(1) = task_data(1,1);
    num_lost = 0;
    lost_jobs = [];
    for i=2:num_rows,
        sep_job = task_data(i,2) - task_data(i-1,2);
        if (sep_job==1)
            timestamps(i+num_lost) = task_data(i,1);
        else
            interpolated = 1;
            aux = linspace(task_data(i-1,1),task_data(i,1),sep_job+1)';
            timestamps(i+num_lost:i+num_lost+sep_job-1) = aux(2:end);
            for j=1:sep_job-1,
                %                 fprintf('[PROCESS] Lost mark of job %d of thread %d, interpolated\n', ...
                %                     task_data(i-1,2)+j, task_id);
                lost_jobs = [lost_jobs task_data(i-1,2)+j];
            end
            num_lost= num_lost+sep_job-1;
        end
    end
    cur_task.results.lost_jobs = lost_jobs;
    
    %% Write marks to task dependent file
    cd(tasks_names{task_id});
    output_file = strcat('marks.csv');
    fid = fopen(output_file,'w+');
    fprintf(fid,'%11.6f\n', timestamps');
    fclose(fid);
    cd ..;
    cur_task.results.marks = output_file;
    cur_task.results.num_marks = length(timestamps);

    %% Update json file
    experim_json.tasks.(tasks_names{task_id}) = cur_task;
    savejson('',experim_json,strcat(experiment_name,'.output.json'));
end
