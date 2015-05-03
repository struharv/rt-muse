function analysis(experiment_name)

  %% ----------------------------------------------------------------------
  % Analysis: parameters definition
  % this section contains the parameters of the analysis that can be
  % eventually modified by the user, for example the window method
  % -----------------------------------------------------------------------
  % window_method: window cut method, currently the alternatives are
  %   1. 'all-running'
  %   2. 'fixed' (uses the parameters 'window_start' and 'window_end')
  window_method = 'all-running';
  window_start = 0;
  window_end = 0;
  % reconstruct lost markers: default is true
  reconstruct = true;
  % refjob_method: reference job, currently the alternatives are
  %   1. 'minimum'
  %   2. 'explicit' (uses the parameter 'refjob_value')
  %   3. 'ref-to-exp' (uses the parameter 'refjob_path')
  refjob_method = 'minimum';
  refjob_value = 0;
  refjob_path = '';
  % -----------------------------------------------------------------------
  
  %% Importing JSON file with experiment description
  json_file = strcat(experiment_name, '.json');
  experim_json = loadjson(json_file);
  % loading analysis options from json file
  tasks_names = fieldnames(experim_json.tasks);
  tasks_num = size(tasks_names, 1);
  % computing analysis window
  experim_json = window(experiment_name, experim_json);

  %% ----------------------------------------------------------------------
  % creating output directories
  for i = 1:tasks_num 
    % creating output directory with task name - needed before for refjob
    name = tasks_names{i};
    mkdir(name);
  end
  mkdir('global');
  
  %% ----------------------------------------------------------------------
  % Analysis: task analysis
  % This part of the analysis checkes if something is defined in the
  % analysis part of the json for each task. If so, it creates a directory
  % for the results of the specific task and runs the per task analysis
  % invoking functions called 'task_' followed by the name of the analysis
  % specified in the json file.
  % -----------------------------------------------------------------------
  
  for i = 1:tasks_num
    % checking whether the task needs to be analyzed
    name = tasks_names{i};
    task_data = experim_json.tasks.(name);
    
    if ismember('analysis', fieldnames(task_data)),
      
      % checking the type of analysis to be performed
      all_analysis = fieldnames(task_data.analysis);
      
      % invoking per task analysis
      for j = 1:length(all_analysis)
        function_name = strcat('task_', all_analysis{j});
        function_handler = str2func(function_name);
        experim_json = function_handler(experiment_name, experim_json, i);
      end
      
    end
  end

  %% ----------------------------------------------------------------------
  % Analysis: global analysis
  % This part of the analysis checkes if something is defined in the
  % analysis part of the json for the global experiment. If so, it creates
  % a directory 'global' for the results and execute the analysis invoking
  % functions called with the name specified in the json file.
  % -----------------------------------------------------------------------
  % checking whether the global experiment needs to be analyzed
    global_data = experim_json.global;
  
  if ismember('analysis', fieldnames(global_data))
    
    % checking the type of analysis to be performed
    all_analysis = fieldnames(global_data.analysis);
    
    % invoking global analysis
    for j=1:length(all_analysis)
      function_name = all_analysis{j};
      function_handler = str2func(function_name);
      experim_json = function_handler(experiment_name, experim_json);
    end
    
  end
  
end


