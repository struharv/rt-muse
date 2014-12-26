function process(experiment_name)
% PROCESS  Process the data for the experiment_name given.
%   It writes the processing results on files in the same 
%   directory of the input files. The function assumes that
%   a CSV file named 'experiment_name.csv' is in the current
%   directory.

	input_file  = strcat(experiment_name,'.csv');
	full_data = csvread(input_file);
	thread_set = unique(full_data(:,2));
	all_data = [];

	% loop on threads
	for k = 1:length(thread_set),

	% extracting timestamp of event (column 1) and job id (column 3) for each
	% thread id (column 2), CPU (column 4) is not used for the analysis
    thread_id = thread_set(k);
    thread_data = full_data((full_data(:,2) == thread_id),[1 3]);
    num_rows = size(thread_data,1);

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
        aux = linspace(thread_data(i-1,1),thread_data(i,1),sep_job+1)';
        thread_marks(i+num_lost:i+num_lost+sep_job-1) = aux(2:end);
        for j=1:sep_job-1,
          fprintf('[PROCESS] Lost mark of job %d of thread %d. Interpolated.\n',
            thread_data(i-1,2)+j, thread_id);
        end
        num_lost= num_lost+sep_job-1;
      end
    end
    all_data = [all_data; thread_marks];
    
    % thread sequence processing
    [seq_min, seq_idx_min, seq_max, seq_idx_max] = minmaxseq(thread_marks);
    output_file = strcat(experiment_name,'.',num2str(thread_id,'%d'),'.csv');
    fid = fopen(output_file,'w+');
    fprintf(fid,'%11.6f, %7u, %11.6f, %7u\n',
    	[seq_min, seq_idx_min, seq_max, seq_idx_max]');
    fclose(fid);

	end

	% all threads sequence processing
	all_data = sort(all_data);
	[seq_min, seq_idx_min, seq_max, seq_idx_max] = minmaxseq(all_data);
	output_file = strcat(experiment_name,'.all.csv');
	fid = fopen(output_file,'w+');
	fprintf(fid,'%11.6f, %7u, %11.6f, %7u\n',
		[seq_min, seq_idx_min, seq_max, seq_idx_max]');
	fclose(fid);

end
