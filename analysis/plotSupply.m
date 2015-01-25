%% Template for plotting supply functions

%% Add input data in section below from <experiment>.output.txt
% SLBF_FILE
slbf_file = 'sched_other_long.1.slbf.csv';
% SLBF_CONV_IDX
lowb_sel_conv = [1;2;16;30;322;466;668;1942;2210;6464;19948;24684;37262;39556;59440;61380;65946;65962;66120;70774;70792;70830;70966;70988;71172;71174;71178;71182;71186;71188;71190;71191];
% SLBF_ALPHADELTA(1) or ALPHADELTAS(1)
lowb_alpha = 0.412116;
% SLBF_ALPHADELTA(2) or ALPHADELTAS(2)
lowb_delta = 0.590724;
% SUBF_FILE
subf_file = 'sched_other_long.1.subf.csv';
% SUBF_CONV_IDX
uppb_sel_conv = [1;2;4;10;14;34;96;98;166;188;330;370;390;2348;2552;3562;3728;5328;5344;10018;12384;59454;71870;72058;72072;72080;72092;72093];
% SUBF_ALPHADELTA(1) or ALPHADELTAS(1)
uppb_alpha = 0.412116;
% SUBF_ALPHADELTA(2) or ALPHADELTAS(2)
uppb_delta = -1.142381;
max_slope = 1;    % 1 or min(num_threads, num_cpus)

%% Plotting
slbf_data = csvread(slbf_file);
x_L = slbf_data(:,1);
y_L = slbf_data(:,2);
subf_data = csvread(subf_file);
x_U = subf_data(:,1);
y_U = subf_data(:,2);
uppb_burst = -uppb_delta*uppb_alpha;

time_horizon = max(max(x_L),max(x_U));

% supply lower bound
plot(x_L, y_L,'r');
hold on;

% vertices on the convex hull of the supply lower bound
plot(x_L(lowb_sel_conv), y_L(lowb_sel_conv),'ro');

% linear lower bound
plot([0;lowb_delta;time_horizon],[0;0;lowb_alpha*(time_horizon-lowb_delta)],'k--');

% supply upper bound
plot(x_U, y_U,'b');

% vertices on the convex hull of the supply upper bound
plot(x_U(uppb_sel_conv), y_U(uppb_sel_conv),'bo');

% linear upper bound
plot([0; uppb_burst/(max_slope-uppb_alpha); time_horizon],[0;uppb_burst/(max_slope-uppb_alpha)*max_slope;uppb_alpha*time_horizon+uppb_burst],'k--');

set(gca,'xlim',[0 time_horizon]);
    
%% Choose the export formats
% printing EPS (both Matlab and Octave compatible)
print('supply.eps','-deps');

% printing XFig (only Octave compatible)
%print('supply.fig','-dfig');
