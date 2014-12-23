function process(experiment_name)

% Assumes that a CSV file with the following name is in current directory
input_file  = strcat(experiment_name,'.csv');
full_data = csvread(input_file);
thread_set = unique(full_data(:,2));

all_data = [];
% loop on threads
for k=1:length(thread_set),
    thread_id = thread_set(k);
    % extracting only timestamp and job number of the thread. thread
    % ID and CPU are discarded for the moment
    thread_data = full_data((full_data(:,2)==thread_id),[1 3]);
    num_rows = size(thread_data,1);
    % checking whether some mark was lost. May be made more
    % efficiently than this
    num_marks = thread_data(num_rows,2)-thread_data(1,2)+1;
    thread_marks = -ones(num_marks,1);   % init
    thread_marks(1) = thread_data(1,1);
    num_lost = 0;
    for i=2:num_rows,
        sep_job = thread_data(i,2)-thread_data(i-1,2);
        if (sep_job==1)
            thread_marks(i+num_lost) = thread_data(i,1);
        else
            aux = linspace(thread_data(i-1,1),thread_data(i,1),sep_job+1)';
            thread_marks(i+num_lost:i+num_lost+sep_job-1) = aux(2:end);
            for j=1:sep_job-1,
                fprintf('[PROCESS.M] Lost mark of job %d of thread %d. Reconstructed by linear interpolation.\n', thread_data(i-1,2)+j, thread_id);
            end
            num_lost= num_lost+sep_job-1;
        end
    end
    all_data = [all_data; thread_marks];
    
    % Analyzing the thread sequence
    [seq_min, seq_idx_min, seq_max, seq_idx_max] = minmaxseq(thread_marks);
    output_file = strcat(experiment_name,'.',num2str(thread_id,'%d'),'.csv');
    fid = fopen(output_file,'w+');
    fprintf(fid,'%11.6f, %7u, %11.6f, %7u\n', [seq_min, seq_idx_min, seq_max, seq_idx_max]');
    fclose(fid);
end

% Analyzing the thread sequence
all_data = sort(all_data);
[seq_min, seq_idx_min, seq_max, seq_idx_max] = minmaxseq(all_data);
output_file = strcat(experiment_name,'.all.csv');
fid = fopen(output_file,'w+');
fprintf(fid,'%11.6f, %7u, %11.6f, %7u\n', [seq_min, seq_idx_min, seq_max, seq_idx_max]');
fclose(fid);

end
