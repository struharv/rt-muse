function [best_alpha, best_delta] = bestAlphaDelta(x,y)
% BESTALPHADELTA
% Input:
%   (x,y), coordinates of the convex hull of the supply lower bound (column
%     vectors) 
% Output:
%   best_alpha, bandwidth of the best linear lower bound
%   best_delta, delay of the best linear lower bound

  if (length(x) ~= length(y))
    fprintf('[BESTALPHADELTA] Error: vectors ''x'' and ''y'' should have the same size\n');
    return;
  end

  % time horizon
  H = max(x);
  % number of points
  N = length(x);

  % searching for the (alpha, Delta) which maximize the area below the
  % linear lower bound over [0, H]

  % serching first among the solutions with the linear bound through TWO
  % points of the supply function
  max_area = 0;
  % starting from i=2, because i=1 should always give cur_area = 0
  for i=2:N-1,
    alpha = (y(i+1)-y(i))./(x(i+1)-x(i));
    delta = x(i)-y(i)/alpha;
    y_at_H = alpha*(H-delta);
    % if stationary point
    if ((y_at_H*.5 >= y(i)) && (y_at_H*.5 <= y(i+1)))
      fprintf('[BESTALPHADELTA] Found one local max of line through TWO points\n');
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
      fprintf('[BESTALPHADELTA] Found one local max of line through ONE point (rare)\n');
      area = cur_y*cur_y/alpha*2;
      if (area > max_area)
        best_alpha = alpha;
        best_delta = delta;
        max_area = area;
      end
    end
  end
  
end

