function analysis(experiment_name)

    % -----------------------------------------------------------------------
    % this section contains the parameters of the analysis that can be
    % eventually modified by the user, for example the window method
    % -----------------------------------------------------------------------
    % window_method: window cut method, currently the alternatives are
    %   1. 'all-running'
    %   2. 'fixed' (uses the parameters 'window_start' and 'window_end')
    window_method = 'all-running'; %
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
    json_file = strcat(experiment_name,'.json');
    experim_json = loadjson(json_file);
    % loading analysis options from json file
    tasks_names = fieldnames(experim_json.tasks);
    tasks_num = size(tasks_names, 1);

    %% Computing analysis window
    experim_json = window(experiment_name,experim_json);
    
    % init analysis vectors
%    torun_analysis = boolean(zeros(tasks_num,1));
%    torun_runmap = boolean(zeros(tasks_num,1));
%    torun_supply = boolean(zeros(tasks_num,1));
%    torun_statistical = boolean(zeros(tasks_num,1));

    %% Creating directory for task results
    for i = 1:tasks_num,
        mkdir(tasks_names{i});
    end
    
    %% Analysis for the single task
    for i = 1:tasks_num
        
        %% Checking whether the task needs to be analyzed
        if ismember('analysis',fieldnames(experim_json.tasks.(tasks_names{i})))

            %% Invoking all analysis per task
            all_analysis = fieldnames(experim_json.tasks.(tasks_names{i}).analysis);
            for j=1:length(all_analysis)
                task_analysis_fun = str2func(strcat('task_',all_analysis{j}));
                experim_json = task_analysis_fun(experiment_name,experim_json,i);
            end
        end
    end

    %% Global analysis
    % TODO
end


