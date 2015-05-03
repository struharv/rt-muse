function [best_alpha, best_burst] = bestAlphaBurst_upp(x,y,H,max_slope)
% BESTALPHABURTS_UPP
% Input:
%   (x,y), coordinates of the convex hull of the supply upper bound (column
%     vectors)
%   H, time horizon over which computing the minimal area
%   max_slope, the maximum instantaneous execution rate
% Output:
%   best_alpha, bandwidth of the best linear upper bound
%   best_burst, burstiness of the best linear upper bound. Notice that the
%     (negative) value of delay delta of the upper bound is
%       delta = -best_burst/best_alpha
% Method:
%   the returned pair corresponds to a linear upper bound with minimal area
%     over [0,H], with H = max(x)

if (length(x) ~= length(y))
  fprintf('[BESTALPHABURST_UPP] Error: vectors ''x'' and ''y'' should have the same size\n');
  return;
end

%% Init
% time horizon
%  H = max(x);
% number of points
N = length(x);

%% Evaluating the linear bound through (x(i),y(i)) and ((x(i+1),y(i+1))
min_area = H*H*max_slope/2;
best_alpha = max_slope;
best_burst = 0;
% starting from i=2, since for i=1, we should get the area above
for i=2:N-1,
  alpha = (y(i+1)-y(i))./(x(i+1)-x(i));
  burst = y(i)-alpha*x(i);
  tStar = burst/(max_slope-alpha);
  x_mid = (H+tStar)*.5;
  % if stationary point
  if ((x_mid >= x(i)) && (x_mid <= x(i+1)))
    fprintf('[BESTALPHABURST_UPP] Found one local max of line through TWO points\n');
    area = .5*(tStar*tStar*max_slope+(tStar*max_slope+burst+alpha*H)*(H-tStar));
    if (area < min_area)
      best_alpha = alpha;
      best_burst = burst;
      min_area = area;
    end
  end
end

%% Evaluating the linear bound through (x(i),y(i)) only
% starting from i=3, because y(1)=y(2)=0
for i=3:N-1,
  cur_x = x(i);
  cur_y = y(i);
  alpha = (max_slope*(H-2*cur_x)+cur_y)/(H-cur_x);
  burst = cur_y-alpha*cur_x;
  tStar = burst/(max_slope-alpha);
  prev_y = alpha*x(i-1)+burst;
  next_y = alpha*x(i+1)+burst;
  % if feasible
  if ((y(i-1) <= prev_y) && (y(i+1) <= next_y))
    fprintf('[BESTALPHABURST_UPP] Found one local max of line through ONE point (rare)\n');
    area = .5*(tStar*tStar*max_slope+(tStar*max_slope+burst+alpha*H)*(H-tStar));
    if (area < min_area)
      best_alpha = alpha;
      best_burst = burst;
      min_area = area;
    end
  end
end

end