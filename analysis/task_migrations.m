function experim_json = task_migrations(experiment_name, experim_json, task_id)

  %% If already executed, do not run
  tasks_names = fieldnames(experim_json.tasks);
  cur_task = experim_json.tasks.(tasks_names{task_id});
  if (ismember('results', fieldnames(cur_task)))
    if (ismember('migrations', fieldnames(cur_task.results)))
      return
    end
  end

  %% Checking dependecies
  experim_json = window(experiment_name, experim_json);
  
  %% Computing task migrations
  cpu_set = sort(experim_json.tasks.(tasks_names{task_id}).cpus);
  cpu_num = length(cpu_set);

  input_file = strcat(experiment_name, '.csv');
  full_data = csvread(input_file);
  task_data = full_data((full_data(:,2) == task_id),[1 4]);

  % selecting only data in time window
  task_data = ...
    task_data((task_data(:,1) >= experim_json.global.results.window(1)) & ...
    (task_data(:,1) <= experim_json.global.results.window(2)),:);
  
  % computing migrations
  migrations = sum(thread_data(1:end-1, 2) ~= thread_data(2:end, 2));

  % writing migrations on json
  cur_task.results.migrations = migrations;
  
  %% Conclusion
  experim_json.tasks.(tasks_names{task_id}) = cur_task;
  savejson('', experim_json, strcat(experiment_name,'.output.json'));

end