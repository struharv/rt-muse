function process(experiment_name)
% PROCESS  Process the data for the experiment_name given. It writes
%   the processing results on files in the same directory of the
%   input files. Also, it writes 'analysis.m', which can be used to
%   perform various types of analyses.
%
%   The function 'process.m' assumes that a CSV file named
%   'experiment_name.csv' is in the current directory, and it has
%   the following CSV format
%
%     #Time, #Thread-number, #Job-number, #CPU
%
%   meaning that at time #Time, the job #Job-number of thread
%   #Thread-number started on CPU #CPU.
%
%     - #Time is absolute time in seconds
%
%     - #Thread-number is the index of thread determined by the
%     order of appearence in 'experiment_name.json', starting from 1
%
%     - #Job-number is the index of job, starting from 0, of thread
%     #Thread-number, which started at #Time
%
%     - #CPU is the index of CPU, starting from 0, on which the job
%     started

  % importing JSON file with experiment description and initializing
  json_file = strcat(experiment_name,'.json');
  % it is required JSONlab toolbox. Download it at
  % http://iso2mesh.sourceforge.net/cgi-bin/index.cgi?jsonlab
  experim_json = loadjson(json_file);
  
  % TODO: check if all goes smoothly when threads have names of different lengths
  thread_names = fieldnames(experim_json.tasks);
  thread_num = size(thread_names,1);
  res_num = experim_json.resources;
  sim_duration = experim_json.global.duration;
  affinities = cell(thread_num,1);
  cpu_set = []; % init with empty set, then add other CPUs
  for i=1:thread_num,
    cpu_cur = sort(experim_json.tasks.(thread_names{i}).cpus);
    affinities{i,1} = cpu_cur;
    cpu_set = union(cpu_set, cpu_cur);
  end
  cpu_num = length(cpu_set);
  
  % building a 0/1 map from affinities
  %   affinity_map(i,k) = 1   <==> thread i may execute over CPU k
  affinity_map = zeros(thread_num,cpu_num);
  for i=1:thread_num,
    cpu_cur = affinities{i,1};
    for k=1:cpu_num,
      if (ismember(cpu_set(k),cpu_cur))
        affinity_map(i,k) = 1;
      end
    end
  end
  
  %% Importing data from 'experiment_name.csv'
  input_file = strcat(experiment_name,'.csv');
  full_data = csvread(input_file);
  thread_run = unique(full_data(:,2));
  thread_not_run = setdiff((1:thread_num)',thread_run);
  if (~isempty(thread_not_run))
    fprintf('[PROCESS] WARNING: Threads %s did not ever start!\n', ...
      mat2str(thread_not_run'));
  end
  cpu_run = unique(full_data(:,4));
  all_marks = [];
  interpolated = 0;
  thread_window = zeros(thread_num,2);
  thread_nJobs = zeros(thread_num,1);

  % loop on threads to compute the time windows only
  for k = 1:length(thread_run),
    thread_id = thread_run(k);
    thread_data = full_data((full_data(:,2) == thread_id),[1 3]);
    thread_window(thread_id,1) = min(thread_data(:,1));
    thread_window(thread_id,2) = max(thread_data(:,1));
  end
  
  % interval in which all threads, which started once, have at least one
  % pending job 
  win_a = max(thread_window(thread_run,1));
  win_b = min(thread_window(thread_run,2));
  
  % loop on threads to process each trace
  for k = 1:length(thread_run),

    % extracting timestamps of thread k
    %  #CPU is not used for the analysis, still can be used for other analysis
    thread_id = thread_run(k);
    fprintf('[PROCESS] Processing data of thread ''%s''\n', ...
      thread_names{thread_id});
    thread_data = full_data((full_data(:,2) == thread_id),[1 3]);
    
    % keeping data only when all threads have at least one pending job
    thread_data = ...
      thread_data((thread_data(:,1) >= win_a) & (thread_data(:,1) <= win_b),:);
    num_rows = size(thread_data,1);
    if (num_rows <= 0)
      fprintf('[PROCESS] No job execution of thread ''%s'' in [%f,%f]\n', ...
        thread_names{thread_id},win_a,win_b);
      continue;
    end
    
    % checking whether some mark was lost
    num_marks = thread_data(num_rows,2) - thread_data(1,2) + 1;
    thread_marks = -ones(num_marks,1); % init
    thread_marks(1) = thread_data(1,1);
    num_lost = 0;

    for i=2:num_rows,
      sep_job = thread_data(i,2) - thread_data(i-1,2);
      if (sep_job==1)
        thread_marks(i+num_lost) = thread_data(i,1);	
      else
        interpolated = 1;
        aux = linspace(thread_data(i-1,1),thread_data(i,1),sep_job+1)';
        thread_marks(i+num_lost:i+num_lost+sep_job-1) = aux(2:end);
        for j=1:sep_job-1,
          fprintf('[PROCESS] Lost mark of job %d of thread %d, interpolated\n', ...
            thread_data(i-1,2)+j, thread_id);
        end
        num_lost= num_lost+sep_job-1;
      end
    end
    thread_nJobs(thread_id) = length(thread_marks); 
    all_marks = [all_marks; thread_marks];

    % computing min/max separation of consecutive job starts of each thread
    [seq_min, seq_idx_min, seq_max, seq_idx_max] = minmaxseq(thread_marks);
    output_file = strcat(experiment_name,'.',num2str(thread_id,'%d'),'.csv');
    fid = fopen(output_file,'w+');
    fprintf(fid,'%11.6f, %7u, %11.6f, %7u\n', ...
      [seq_min, seq_idx_min, seq_max, seq_idx_max]');
    fclose(fid);

  end

  % computing min/max separation of consecutive job starts of any thread
  fprintf('[PROCESS] Processing data of all threads\n');
  all_marks = sort(all_marks);
  [seq_min, seq_idx_min, seq_max, seq_idx_max] = minmaxseq(all_marks);
  output_file = strcat(experiment_name,'.all.csv');
  fid = fopen(output_file,'w+');
  fprintf(fid,'%11.6f, %7u, %11.6f, %7u\n', [seq_min, seq_idx_min, seq_max, seq_idx_max]');
  fclose(fid);

  % creating the file to perform the analysis
  analysis_file = 'experiment_data.m';
  fid_analysis = fopen(analysis_file,'w');
  fprintf(fid_analysis,'%% -------- WARNING -------- \n');
  fprintf(fid_analysis,'%% This file is automatically generated by ''analysis/process.m''. It reports\n');
  fprintf(fid_analysis,'%%   the data of the experiment ''%s'', extracted from\n', experiment_name);
  fprintf(fid_analysis,'%%   ''%s.json''. It is going to be loaded in the preample in the\n', experiment_name);
  fprintf(fid_analysis,'%%   analysis file ''results/%s/analysis.m''\n', experiment_name);
  fprintf(fid_analysis,'%%\n');
  fprintf(fid_analysis,'%% In case you make any modification that you would like to save, make sure\n');
  fprintf(fid_analysis,'%%   not to run ''analysis/process.m'' again. You actually should not need to\n');
  fprintf(fid_analysis,'%%   re-run ''analysis/process.m''\n');
  fprintf(fid_analysis,'%% -------- WARNING --------\n');
  fprintf(fid_analysis,'\n');
  fprintf(fid_analysis,'%%%% Experiment source data\n');
  fprintf(fid_analysis,'%% File with original input data in the format\n');
  fprintf(fid_analysis,'%%    #Time, #Thread-number, #Job-number, #CPU\n');
  fprintf(fid_analysis,'input_file = ''%s'';\n',input_file);
  fprintf(fid_analysis,'\n');
  fprintf(fid_analysis,'%%%% Thread data\n');
  fprintf(fid_analysis,'thread_names = {');
  for i=1:thread_num,
    fprintf(fid_analysis,'''%s''; ',thread_names{i});
  end
  fprintf(fid_analysis,'};\n');
  fprintf(fid_analysis,'thread_run = %s;\n',mat2str(thread_run));
  fprintf(fid_analysis,'thread_num = length(thread_run);\n');
  fprintf(fid_analysis,'cpu_set = %s;\n',mat2str(cpu_set'));
  fprintf(fid_analysis,'%% if affinity_map(i,k) = 1, then i-th thread may execute over k-th CPU\n');
  fprintf(fid_analysis,'affinity_map = %s;\n', mat2str(affinity_map));
  fprintf(fid_analysis,'\n');
  fprintf(fid_analysis,'%%%% Simulation data\n');
  fprintf(fid_analysis,'%% simulation duration extracted from JSON file\n');
  fprintf(fid_analysis,'sim_duration = %d;\n',sim_duration);
  fprintf(fid_analysis,'\n');
  fprintf(fid_analysis,'%% thread_window(i,1) = start instant of first job of i-th thread\n');
  fprintf(fid_analysis,'%% thread_window(i,2) = start instant of last job of i-th thread\n');
  fprintf(fid_analysis,'thread_window = %s;\n',mat2str(thread_window));
  fprintf(fid_analysis,'\n');
  fprintf(fid_analysis,'%% thread_nJobs(i) = number of i-th thread''s jobs in interval\n');
  fprintf(fid_analysis,'%%   [thread_window(i,1), thread_window(i,2)]\n');
  fprintf(fid_analysis,'thread_nJobs = %s;\n',mat2str(thread_nJobs));
  fprintf(fid_analysis,'\n');
  fprintf(fid_analysis,'%%%% Analysis data\n');
  fprintf(fid_analysis,'%% Time horizon, in seconds, over which computing the supply function and\n');
  fprintf(fid_analysis,'%%   the best (alpha,Delta) approximation. It should be significantly\n');
  fprintf(fid_analysis,'%%   smaller than the simulation time specified in the .json file\n');
  fprintf(fid_analysis,'%%   ("global.duration"), like one order of magnitude less. Default is\n');
  fprintf(fid_analysis,'%%   ''sim_duration/20''\n');
  fprintf(fid_analysis,'time_horizon = %f;\n', sim_duration/20);
  fprintf(fid_analysis,'\n');
  fprintf(fid_analysis,'%% The reference thread should have the following characteristics:\n');
  fprintf(fid_analysis,'%%   (1) the job body is the same as in the simulation\n');
  fprintf(fid_analysis,'%%   (2) the reference thread runs as uninterrupted as possible, for example\n');
  fprintf(fid_analysis,'%%       with high priority (SCHED_FIFO) and no migration\n');
  fprintf(fid_analysis,'%% ''ref_infile'' is the file name of such a processed trace\n');
  fprintf(fid_analysis,'ref_infile = ''%s.1.csv'';\n',experiment_name);
  fprintf(fid_analysis,'%% ref_infile = ''../results/sched_fifo/sched_fifo.1.csv'';\n');
  fprintf(fid_analysis,'ref_data = csvread(ref_infile);\n');
  fprintf(fid_analysis,'tol_ref = 2e-3;      %% tolerance to compute nominal job length\n');
  fprintf(fid_analysis,'[ref_seq, ind_last] = uniformYvalues(ref_data(:,1), tol_ref, max(thread_nJobs)+1);\n')
  fprintf(fid_analysis,'\n');
  fclose(fid_analysis);
  fprintf('[PROCESS] Octave/Matlab file ''%s'' written\n',analysis_file);
  fprintf('[PROCESS]   it contains the experiment data, to be used by\n');
  fprintf('[PROCESS]   ''results/%s/analysis.m''\n',experiment_name);
end

