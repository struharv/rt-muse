function experim_json = minmax(experiment_name,experim_json)
% MINMAX  Compute minimum/maximum separations of the task set

%% If already executed, do not run
if (ismember('results',fieldnames(experim_json.global)))
  if (ismember('minmax',fieldnames(experim_json.global.results)))
    return
  end
end

%% Loading timestamps of all tasks with 'analysis' section
tasks_names = fieldnames(experim_json.threads);
tasks_num = size(tasks_names, 1);

all_timestamps = [];
for task_id=1:tasks_num,
  % only tasks with 'analysis' section are considered in the set
  if ismember('analysis',fieldnames(experim_json.threads.(tasks_names{task_id})))
    % Get the marks of a single task
    experim_json = task_marks(experiment_name,experim_json,task_id);
    infile = [experim_json.threads.(tasks_names{task_id}).results.marks];
    timestamps = csvread(infile);
    % append the read timestamps to all_timestamps
    all_timestamps = [all_timestamps; timestamps];
  end
end
all_timestamps = sort(all_timestamps);

%% Initializations
num_marks = length(all_timestamps);
intervals = diff(all_timestamps);
temporary_intervals = zeros(num_marks,1);
all_timestamps_min = zeros(num_marks,1);
index_min = zeros(num_marks,1);
all_timestamps_max = zeros(num_marks,1);
index_max = zeros(num_marks,1);

%% Computation of min/max
for i = 1:num_marks-1,
  temporary_intervals = temporary_intervals(1:end-1) + intervals(i:end);
  [all_timestamps_min(i+1), index_min(i+1)] = min(temporary_intervals);
  [all_timestamps_max(i+1), index_max(i+1)] = max(temporary_intervals);
end

%% Write minmax of all tasks
outfile = 'global/minmax.csv';
fid = fopen(outfile,'w+');
fprintf(fid,'%11.6f, %7u, %11.6f, %7u\n', ...
  [all_timestamps_min, index_min, all_timestamps_max, index_max]');
fclose(fid);
experim_json.global.results.minmax = outfile;

%% Update json file
savejson('',experim_json,strcat(experiment_name,'.output.json'));
end
