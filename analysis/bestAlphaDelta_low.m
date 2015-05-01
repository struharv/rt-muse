function [best_alpha, best_delta] = bestAlphaDelta_low(x,y,H)
% BESTALPHADELTA_LOW
% Input:
%   (x,y), coordinates of the convex hull of the supply lower bound (column
%     vectors)
%   H, time horizon over which computing the maximal area
% Output:
%   best_alpha, bandwidth of the best linear lower bound
%   best_delta, delay of the best linear lower bound
% Method:
%   the returned pair corresponds to a linear lower bound with maximal area
%     over [0,H], with H = max(x)

  if (length(x) ~= length(y))
    fprintf('[BESTALPHADELTA_LOW] Error: vectors ''x'' and ''y'' should have the same size\n');
    return;
  end

  %% Init
  % time horizon
%  H = max(x);
  % number of points
  N = length(x);

  %% Evaluating the linear bound through (x(i),y(i)) and ((x(i+1),y(i+1))
  max_area = 0;
  % starting from i=2, because i=1 should always give cur_area = 0
  for i=2:N-1,
    alpha = (y(i+1)-y(i))./(x(i+1)-x(i));
    delta = x(i)-y(i)/alpha;
    y_at_H = alpha*(H-delta);
    % if stationary point
    if ((y_at_H*.5 >= y(i)) && (y_at_H*.5 <= y(i+1)))
      fprintf('[BESTALPHADELTA_LOW] Found one local max of line through TWO points\n');
      area = y_at_H*(H-delta)*.5;
      if (area > max_area)
        best_alpha = alpha;
        best_delta = delta;
        max_area = area;
      end
    end
  end

  % now searching among lines through ONE point of the supply function
  % starting from i=3, because y(1)=y(2)=0
  for i=3:N-1,
    cur_x = x(i);
    cur_y = y(i);
    alpha = cur_y/(H-cur_x);
    delta = cur_x-cur_y/alpha;
    prev_y = alpha*(x(i-1)-delta);
    next_y = alpha*(x(i+1)-delta);
    % if feasible
    if ((y(i-1) >= prev_y) && (y(i+1) >= next_y))
      fprintf('[BESTALPHADELTA_LOW] Found one local max of line through ONE point (rare)\n');
      area = cur_y*cur_y/alpha*2;
      if (area > max_area)
        best_alpha = alpha;
        best_delta = delta;
        max_area = area;
      end
    end
  end
  
end