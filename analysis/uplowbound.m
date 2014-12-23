function uplowbound(experiment_name)

% ----------------------------------------------------------
% INPUT to the script are listed below
% ----------------------------------------------------------

% filename from which read the duration of jobs
%   assuming format "min_seq, idx_min, max_seq, idx_max"
ref_infile = strcat(experiment_name,'.all.csv');


% The number of the jobs used to compute the minimum job lenght is the
% minimum between
idx_last_ref = 1000;
% ... and the following fraction of the available jobs
portion_ref = .01;

% filename containing the simulation data
%   assuming format "min_seq, idx_min, max_seq, idx_max"
sim_infile = strcat(experiment_name,'.all.csv');

% Maximum istantaneous slope. Tipically equal to the number of cores
max_slope = 3;

% In the simulation there is a very large number of points, roughly
% proportional to:
%
%   simulation_duration/size_of_job*share_of_resource
%
% To cut points which do not substantially impact in the supply function
% the followinf tollerance is used. If set to zero, then the exact (with
% many point) supply function is considered. A value of 1e-4 was shown to
% be a good compromise. If you feel like "whats-going-on-here" set it
% to zero and the analysis will just take longer
tol_cut = 1e-5;
%tol_cut = 0;

% Time horizon, in seconds, over which computing the best (alpha,Delta)
% approximation. Also used for plotting. It should be significantly smaller
% than the simulation time specified in the .json file ("global.duration"),
% something like one order of magnitude less
time_horizon = 1;
% ----------------------------------------------------------

ref_data = csvread(ref_infile);
sim_data = csvread(sim_infile);

num_ref_marks = size(ref_data,1);
num_sim_marks = size(sim_data,1);

% performing an average of the minimum separation of reference sequence to
% compute the 
ind_last_ref = min(ceil(num_ref_marks*portion_ref),idx_last_ref);
lowb_all_y = linspace(0,ref_data(ind_last_ref,1)*(num_sim_marks-1)/(ind_last_ref-1),num_sim_marks)';

lowb_all_x = sim_data(:,3);           % max separations

% computing the inner corners of the supply function, thanks to the supply
% function properties 
lowb_inner_x = lowb_all_x(1);
lowb_inner_y = lowb_all_y(1);
for i=2:num_sim_marks,
    select = (lowb_inner_y-lowb_all_y(i)>max_slope*(1-tol_cut)*(lowb_inner_x-lowb_all_x(i)));
    lowb_inner_x = lowb_inner_x(select);
    lowb_inner_y = lowb_inner_y(select);
    lowb_inner_x = [lowb_inner_x; lowb_all_x(i)];
    lowb_inner_y = [lowb_inner_y; lowb_all_y(i)];
end
num_inner_corners = length(lowb_inner_x);
if (num_inner_corners <= 1)
    disp('[UPLOWBOUND] Too few points. Try the following:');
    disp('[UPLOWBOUND] - reducing tol_cut, possibly to zero');
    disp('[UPLOWBOUND] - reducing the length of reference job, by reducing portion_ref');
    break;
end

% now computing both inner and outer corners of the  of the lower bound
lowb_inout_x = zeros(num_inner_corners*2-1,1);
lowb_inout_y = zeros(num_inner_corners*2-1,1);
lowb_inout_x(1) = lowb_inner_x(1);
lowb_inout_y(1) = lowb_inner_y(1);
for i=1:num_inner_corners-1,
    lowb_inout_x(2*i) = lowb_inner_x(i+1)-(lowb_inner_y(i+1)-lowb_inner_y(i))/max_slope;
    lowb_inout_y(2*i) = lowb_inner_y(i);
    lowb_inout_x(2*i+1) = lowb_inner_x(i+1);
    lowb_inout_y(2*i+1) = lowb_inner_y(i+1);
end

% computing the points on the convex lower envelope
sel_conv = [1;2];
% slope_env(1) = (lowb_conv_y(2)-lowb_conv_y(1))/(lowb_conv_x(2)-lowb_conv_x(1));
% last_slope = -1;
%last_conv_idx = 1;
for i=2:num_inner_corners-1,
    slope_env = (lowb_inout_y(sel_conv(2:end))-lowb_inout_y(sel_conv(1:end-1)))./(lowb_inout_x(sel_conv(2:end))-lowb_inout_x(sel_conv(1:end-1)));
    slope_new = (lowb_inout_y(2*i)-lowb_inout_y(sel_conv(1:end-1)))./(lowb_inout_x(2*i)-lowb_inout_x(sel_conv(1:end-1)));
    cond = (slope_env < slope_new);
    sel_conv = sel_conv([true; cond]);
    sel_conv = [sel_conv; 2*i];
end
% always add the last point
sel_conv = [sel_conv; 2*num_inner_corners-1];
if (length(sel_conv) <= 2)
    disp('[UPLOWBOUND] The points over the convex envelope are less than 3.');
    disp('[UPLOWBOUND]   This is bad!!');
end

if (lowb_inout_y(sel_conv(2)) ~= lowb_inout_y(sel_conv(1)))
    disp('[UPLOWBOUND] The first two points over the convex envelope have not the same Y');
    disp('[UPLOWBOUND]   This is unexpected!!');
end

% searching for the (alpha,Delta) which maximize the area below the linear
% lower bound over [0, time_horizon]
%
% serching first among the solutions with the linear bound through TWO
% points of the supply function
max_area = 0;
for i=2:length(sel_conv)-1,
    cur_alpha = (lowb_inout_y(sel_conv(i+1))-lowb_inout_y(sel_conv(i)))./(lowb_inout_x(sel_conv(i+1))-lowb_inout_x(sel_conv(i)));
    cur_delta = lowb_inout_x(sel_conv(i))-lowb_inout_y(sel_conv(i))/cur_alpha;
    y_at_horizon = cur_alpha*(time_horizon-cur_delta);
    if ((y_at_horizon/2 >= lowb_inout_y(sel_conv(i))) && (y_at_horizon*.5 <= lowb_inout_y(sel_conv(i+1))))
        disp('[UPLOWBOUND] Found one local max of line through TWO points');
        cur_area = y_at_horizon*(time_horizon-cur_delta)*.5;
        if (cur_area > max_area)
            best_alpha = cur_alpha;
            best_delta = cur_delta;
            max_area = cur_area;
        end
    end
end
% now searching among lines throuhg ONE point of the supply function
for i=3:length(sel_conv)-1,
    cur_x = lowb_inout_x(sel_conv(i));
    cur_y = lowb_inout_y(sel_conv(i));
    cur_alpha = cur_y/(time_horizon-cur_x);
    cur_delta = cur_x-cur_y/cur_alpha;
    prev_y = cur_alpha*(lowb_inout_x(sel_conv(i-1))-cur_delta);
    next_y = cur_alpha*(lowb_inout_x(sel_conv(i+1))-cur_delta);
    if ((lowb_inout_y(sel_conv(i-1)) >= prev_y) && (lowb_inout_y(i+1) >= next_y))
        disp('[UPLOWBOUND] Found one local max of line through ONE point. Should be rare');
        cur_area = cur_y*cur_y/cur_alpha*2;
        if (cur_area > max_area)
            best_alpha = cur_alpha;
            best_delta = cur_delta;
            max_area = cur_area;
        end
    end
end

best_alpha
best_delta

end