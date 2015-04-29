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

    % importing JSON file with experiment description
    json_file = strcat(experiment_name,'.json');
    experim_json = loadjson(json_file);
    % loading analysis options from json file
    tasks = fieldnames(experim_json.tasks);
    thread_num = size(tasks, 1);

    % analysis for the single thread
    for i = 1:thread_num

        % if analysis is not specified for the task, then you should run all
        % the analysis that we can do, if some are false we can skip them
        runall = false;
        if ~isfield(experim_json.tasks.(tasks{i}), 'analysis')
            runall = true;
        else
            options = experim_json.tasks.(tasks{i}).analysis;
        end

        % find out what analysis should be run
        torun_runmap = runall || ~isfield(options, 'runmap') ||  options.runmap == 1;
        torun_supply = runall || ~isfield(options, 'supply') ||  options.supply == 1;
        torun_statistical = runall || ~isfield(options, 'statistical') ||  options.statistical == 1;

        if (torun_runmap || torun_supply || torun_statistical)
            % if at least one of the analysis should be run, we should
            % process the data for the thread, which means selecting the
            % values of the events linked to the specific thread, cutting
            % them to the window and eventually reconstructing them if
            % some parkers are lost
            fprintf('[ANALYSIS] Processing data for thread %d\n', i);
            % TODO: call the process function
            % parameters used: window_method, window_start, window_end, reconstruct
        end

        % running the runmap analysis for the single thread
        if torun_runmap
            fprintf('[ANALYSIS] Running runmap for thread %d\n', i);
            % TODO: call the runmap function
        end

        % running the supply function analysis for the single thread
        if torun_supply
            fprintf('[ANALYSIS] Running supply for thread %d\n', i);
            % TODO: call the supply function
            % parameters used: refjob_method, refjob_value, refjob_path
        end

        % running the statistical analysis for single thread
        if torun_statistical
            fprintf('[ANALYSIS] Running statistical for thread %d\n', i);
            % TODO: call the statistical function
        end

    end

    % launching the global analysis parsing the global options
    runall = false;
    if ~isfield(experim_json.global, 'analysis')
        runall = true;
    else
        options = experim_json.global.analysis;
    end

    torun_runmap = runall || ~isfield(options, 'runmap') ||  options.runmap == 1;
    torun_supply = runall || ~isfield(options, 'supply') ||  options.supply == 1;

    % running the runmap analysis for the global platform
    if torun_runmap
        fprintf('[ANALYSIS] Running runmap for global\n');
        % TODO: call the runmap function
    end

    % running the supply function analysis for the global platform
    if torun_supply
        fprintf('[ANALYSIS] Running supply for global\n');
        % TODO: call the supply function
        % parameters used: refjob_method, refjob_value, refjob_path
    end



