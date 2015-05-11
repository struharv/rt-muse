function experim_json = task_runmap(experiment_name, experim_json, task_id)

  %% If already executed, do not run
  tasks_names = fieldnames(experim_json.threads);
  cur_task = experim_json.threads.(tasks_names{task_id});
  if (ismember('results', fieldnames(cur_task)))
    if (ismember('runmap', fieldnames(cur_task.results)))
      return
    end
  end

  %% Checking dependecies
  experim_json = window(experiment_name, experim_json);
  
  %% Computing task runmap
  cpu_set = sort(experim_json.threads.(tasks_names{task_id}).cpus);
  cpu_num = length(cpu_set);

  input_file = strcat(experiment_name, '.csv');
  full_data = csvread(input_file);
  task_data = full_data((full_data(:,2) == task_id),[1 4]);

  % selecting only data in time window
  task_data = ...
    task_data((task_data(:,1) >= experim_json.global.results.window(1)) & ...
    (task_data(:,1) <= experim_json.global.results.window(2)),:);
  num_rows = size(task_data,1);
  
  % computing runmap
  run_map = zeros(1, cpu_num);
  for i=1:cpu_num,
    num_jobs_cpu = sum(task_data(:,2) == cpu_set(i));
    run_map(i) = num_jobs_cpu/num_rows;
  end

  % writing map on json
  cur_task.results.runmap = run_map;
  
  %% Conclusion
  experim_json.threads.(tasks_names{task_id}) = cur_task;
  savejson('', experim_json, strcat(experiment_name,'.output.json'));

end