function experim_json = task_minmax(experiment_name,experim_json,task_id)

  %% If already executed, do not run
  tasks_names = fieldnames(experim_json.tasks);
  cur_task = experim_json.tasks.(tasks_names{task_id});
  if (ismember('results',fieldnames(cur_task)))
    if (ismember('minmax',fieldnames(cur_task.results)))
      return
    end
  end

  %% Checking dependecies
  experim_json = task_marks(experiment_name,experim_json,task_id);
  cur_task = experim_json.tasks.(tasks_names{task_id});

  %% Loading marks
  infile = cur_task.results.marks;
  timestamps = csvread(infile);

  %% Initializations
  num_marks = length(timestamps);
  intervals = diff(timestamps);
  temporary_intervals = zeros(num_marks,1);
  timestamps_min = zeros(num_marks,1);
  index_min = zeros(num_marks,1);
  timestamps_max = zeros(num_marks,1);
  index_max = zeros(num_marks,1);

  %% Computation of min/max
  for i = 1:num_marks-1,
    temporary_intervals = temporary_intervals(1:end-1) + intervals(i:end);
    [timestamps_min(i+1), index_min(i+1)] = min(temporary_intervals);
    [timestamps_max(i+1), index_max(i+1)] = max(temporary_intervals);
  end

  %% Write minmax to task dependent file
  output_file = [tasks_names{task_id}, '/minmax.csv'];
  fid = fopen(output_file,'w+');
  fprintf(fid,'%11.6f, %7u, %11.6f, %7u\n', ...
    [timestamps_min, index_min, timestamps_max, index_max]');
  fclose(fid);
  cur_task.results.minmax = output_file;

  %% Update json file
  experim_json.tasks.(tasks_names{task_id}) = cur_task;
  savejson('', experim_json, strcat(experiment_name, '.output.json'));

end
