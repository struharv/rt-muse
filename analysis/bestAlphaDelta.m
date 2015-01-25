function [best_alpha, best_delta_low, best_delta_upp] = bestAlphaDelta(x_L,y_L,x_U,y_U)
% BESTALPHADELTA_LOW
% Input:
%   (x_L,y_L), coordinates of the convex hull of the supply lower bound
%     (column vectors) 
%   (x_U,y_U), coordinates of the convex hull of the supply upper bound
%     (column vectors) 
% Output:
%   best_alpha, bandwidth of the best linear bound
%   best_delta_low, delay of the best linear lower bound
%   best_delta_upp, delay of the best linear upper bound
% Method:
%   The returned values model both upper and lower linear bounds such that
%     best_alpha*(x_L-best_delta_low) <= y_L
%     best_alpha*(x_U-best_delta_upp) >= y_U
%   and the distance between lower and upper bound is minimized

  if (length(x_L) ~= length(y_L))
    fprintf('[BESTALPHADELTA] Error: vectors ''x_L'' and ''y_L'' should have the same size\n');
    return;
  end
  if (length(x_U) ~= length(y_U))
    fprintf('[BESTALPHADELTA] Error: vectors ''x_U'' and ''y_U'' should have the same size\n');
    return;
  end

  N_L = length(x_L);
  N_U = length(x_U);

  % Could be made more efficiently with a deeper investigatio of the
  %   optimization problem (constraints are linear, cost function is not
  %   too bad). Nonetheless, we are not spending too much time here
  min_dist = +Inf;
  %% Evaluating alpha=(y_L(i+1)-y_L(i))/(x_L(i+1)-x_L(i)), with upper bound through (x_U(j),y_U(j)) 
  for i=1:N_L-1,
      alpha = (y_L(i+1)-y_L(i))/(x_L(i+1)-x_L(i));
      beta_L = y_L(i)-alpha*x_L(i);
      for j=1:N_U,
          beta_U = y_U(j)-alpha*x_U(j);
          if (all(alpha*x_L+beta_L <= y_L) && all(alpha*x_U+beta_U >= y_U))
              % is feasible
              dist = (beta_U-beta_L)/sqrt(1+alpha*alpha);
              if (dist < min_dist)
                  % if better solution
                  min_dist = dist;
                  best_alpha = alpha;
                  best_delta_low = -beta_L/alpha;
                  best_delta_upp = -beta_U/alpha;
              end
          end
      end
  end
  
  %% Evaluating alpha=(y_U(i+1)-y_U(i))/(x_U(i+1)-x_U(i)), with upper bound through (x_L(j),y_L(j)) 
  for i=1:N_U-1,
      alpha = (y_U(i+1)-y_U(i))/(x_U(i+1)-x_U(i));
      beta_U = y_U(i)-alpha*x_U(i);
      for j=1:N_L,
          beta_L = y_L(j)-alpha*x_L(j);
          if (all(alpha*x_L+beta_L <= y_L) && all(alpha*x_U+beta_U >= y_U))
              % is feasible
              dist = (beta_U-beta_L)/sqrt(1+alpha*alpha);
              if (dist < min_dist)
                  % if better solution
                  min_dist = dist;
                  best_alpha = alpha;
                  best_delta_low = -beta_L/alpha;
                  best_delta_upp = -beta_U/alpha;
              end
          end
      end
  end  
end