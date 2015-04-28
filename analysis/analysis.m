function analysis(experiment_name)

  % importing JSON file with experiment description
  json_file = strcat(experiment_name,'.json');
  experim_json = loadjson(json_file);

  % loading analysis options from json file
  select_string = experim_json.analysis.select;
  select_vector = strsplit(select_string,', ');
  select_vector = setdiff(select_vector, '');
  window_method = experim_json.analysis.window.method;
  window_parameter = experim_json.analysis.window.parameter;
  refjob_method = experim_json.analysis.refjob.method;
  refjob_parameter = experim_json.analysis.refjob.parameter;
  runmap_string = experim_json.analysis.runmap;
  runmap_vector = strsplit(runmap_string,', ');
  runmap_vector = setdiff(runmap_vector, '');
  plotrunmap_string = experim_json.analysis.plot_runmap;
  plotrunmap_vector = strsplit(plotrunmap_string,', ');
  plotrunmap_vector = setdiff(plotrunmap_vector, '');
  statistical_string = experim_json.analysis.statistical;
  statistical_vector = strsplit(statistical_string,', ');
  statistical_vector = setdiff(statistical_vector, '');
  plotstatistical_string = experim_json.analysis.plot_statistical;
  plotstatistical_vector = strsplit(plotstatistical_string,', ');
  plotstatistical_vector = setdiff(plotstatistical_vector, '');
  supply_string = experim_json.analysis.supply;
  supply_vector = strsplit(supply_string,', ');
  supply_vector = setdiff(supply_vector, '');
  plotsupply_string = experim_json.analysis.plot_supply;
  plotsupply_vector = strsplit(plotsupply_string,', ');
  plotsupply_vector = setdiff(plotsupply_vector, '');
  maxblock_string = experim_json.analysis.maxblock;
  maxblock_vector = strsplit(maxblock_string,', ');
  maxblock_vector = setdiff(maxblock_vector, '');
  convexhull_string = experim_json.analysis.convexhull;
  convexhull_vector = strsplit(convexhull_string,', ');
  convexhull_vector = setdiff(convexhull_vector, '');
  alphadelta_string = experim_json.analysis.alphadelta;
  alphadelta_vector = strsplit(alphadelta_string,', ');
  alphadelta_vector = setdiff(alphadelta_vector, '');

  % checking options for running the analysis on the entire platform
  run_supply_all = ismember(['all'], supply_vector);
  supply_vector = setdiff(supply_vector, 'all');
  run_plotsupply_all = ismember(['all'], plotsupply_vector);
  plotsupply_vector = setdiff(plotsupply_vector, 'all');
  run_convexhull_all = ismember(['all'], convexhull_vector);
  convexhull_vector = setdiff(convexhull_vector, 'all');
  run_alphadelta_all = ismember(['all'], alphadelta_vector);
  alphadelta_vector = setdiff(alphadelta_vector, 'all');

  % we have to apply select to the selected ones but also to the ones that
  % depend on select (like runmap and supply)
  select_vector_augmented = [];
  select_vector_augmented = union(select_vector_augmented, select_vector);
  select_vector_augmented = union(select_vector_augmented, runmap_vector);
  select_vector_augmented = union(select_vector_augmented, supply_vector);
  select_vector_augmented = union(select_vector_augmented, statistical_vector);
  select_vector_augmented = union(select_vector_augmented, plotrunmap_vector);
  select_vector_augmented = union(select_vector_augmented, plotsupply_vector);
  select_vector_augmented = union(select_vector_augmented, plotstatistical_vector);
  select_vector_augmented = union(select_vector_augmented, convexhull_vector);
  select_vector_augmented = union(select_vector_augmented, alphadelta_vector);

  % apply select, window, cut and reconstruct for the selected threads
  for i = 1 : length(select_vector_augmented)
    thread_name = char(select_vector_augmented{i});
    fprintf('Applying SELECT for thread %s\n', thread_name)
    % TODO: call to select function
    
    fprintf('Applying WINDOW for selected thread %s\n', thread_name)
    % TODO: call to window function with window_method and window_parameter

    fprintf('Applying CUT for selected thread %s\n', thread_name)
    % TODO: call to cut function

    if (experim_json.analysis.reconstruct)
      fprintf('Applying RECONSTRUCT for selected thread %s\n', thread_name)
      % TODO: call to reconstruct function
    end
  end

  % get data about the reference job
  % TODO: call the refjob function with refjob_method and refjob_parameter

  % applying runmap
  if ~isempty(runmap_vector)
    for i = 1 : length(runmap_vector)
      thread_name = char(runmap_vector{i});
      fprintf('Applying RUNMAP for thread %s\n', thread_name)
      % TODO: call to runmap function
    end
  end

  % applying plotrunmap
  if ~isempty(plotrunmap_vector)
    for i = 1 : length(plotrunmap_vector)
      thread_name = char(plotrunmap_vector{i});
      fprintf('Applying PLOTRUNMAP for thread %s\n', thread_name)
      % TODO: call to plotrunmap function
    end
  end

  % applying statistical
  if ~isempty(statistical_vector)
    for i = 1 : length(statistical_vector)
      thread_name = char(statistical_vector{i});
      fprintf('Applying STATISTICAL for thread %s\n', thread_name)
      % TODO: call to statistical function
    end
  end

  % applying plotstatistical
  if ~isempty(plotstatistical_vector)
    for i = 1 : length(plotstatistical_vector)
      thread_name = char(plotstatistical_vector{i});
      fprintf('Applying PLOTSTATISTICAL for thread %s\n', thread_name)
      % TODO: call to plotstatistical function
    end
  end

  % applying supply
  if ~isempty(supply_vector)
    for i = 1 : length(supply_vector)
      thread_name = char(supply_vector{i});
      fprintf('Applying SUPPLY for thread %s\n', thread_name)
      % TODO: call to supply function
    end
  end
  if run_supply_all
    fprintf('Applying SUPPLY for ALL\n')
    % TODO: call to supply function
  end

  % applying plotsupply
  if ~isempty(plotsupply_vector)
    for i = 1 : length(plotsupply_vector)
      thread_name = char(plotsupply_vector{i});
      fprintf('Applying PLOTSUPPLY for thread %s\n', thread_name)
      % TODO: call to plotsupply function
    end
  end
  if run_plotsupply_all
    fprintf('Applying PLOTSUPPLY for ALL\n')
    % TODO: call to plotsupply function
  end

  % applying maxblock
  if ~isempty(maxblock_vector)
    for i = 1 : length(maxblock_vector)
      thread_name = char(maxblock_vector{i});
      fprintf('Applying MAXBLOCK for thread %s\n', thread_name)
      % TODO: call to maxblock function
    end
  end

  % applying convexhull
  if ~isempty(convexhull_vector)
    for i = 1 : length(convexhull_vector)
      thread_name = char(convexhull_vector{i});
      fprintf('Applying CONVEXHULL for thread %s\n', thread_name)
      % TODO: call to convexhull function
    end
  end
  if run_convexhull_all
    fprintf('Applying CONVEXHULL for ALL\n')
    % TODO: call to convexhull function
  end

  % applying alphadelta
  if ~isempty(alphadelta_vector)
    for i = 1 : length(alphadelta_vector)
      thread_name = char(alphadelta_vector{i});
      fprintf('Applying ALPHADELTA for thread %s\n', thread_name)
      % TODO: call to alphadelta function
    end
  end
  if run_alphadelta_all
    fprintf('Applying ALPHADELTA for ALL\n')
    % TODO: call to alphadelta function
  end
