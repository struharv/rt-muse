function [x_clean, y_clean, sel_conv] = cleanuppb(x,y,max_slope, tol_cut)
% CLEANUPPB
% Input:
%   x, x coordinate of the supply upper bound (column vector)
%   y, y coordinate of the supply upper bound (column vector). Should have
%     the same size as x
%   max_slope, slope of the supply at full speed (tipically equal to the
%     minimum between number of CPUs and number of threads)
%   tol_cut, tolerance on the slope used to cut point. If equal to zero,
%     exact supply is computed. Larger values result in fewer points and
%     more pessimistic lower bound. Must be <1. Recommended to be <1e-2
%     (magic number)
% Output:
%   x_clean, y_clean, cleaned version of the supply lower bound
%   sel_conv, indices over (x_clean,y_clean) of the points along the lower
%     convex hull. Can be used to compute feasible (alpha, Delta) pairs

  if (length(x) ~= length(y))
    fprintf('[CLEANLOWB] Error: vectors ''x'' and ''y'' must have the same size\n');
    return;
  end

  % time horizon
  H = max(x);

  % number of points
  N = length(x);

  %% Computing the lower-right corners of the supply lower bound
  % starting from the last one
  x_LR = x(N);
  y_LR = y(N);
  for i=N-1:-1:1,
    % removing point in the current (x_LR,y_LR) which are dominated by the
    % new one (x(i),y(i))
    select = (y(i)-y_LR > max_slope*(1-tol_cut)*(x(i)-x_LR));
    x_LR = x_LR(select);
    y_LR = y_LR(select);
    % adding the new one, always
    x_LR = [x(i); x_LR];
    y_LR = [y(i); y_LR];
  end
  
  N_LR = length(x_LR);
  if (N_LR <= 1)
    fprintf('[CLEANUPPB] Too few points. Try the following:\n');
    fprintf('[CLEANUPPB]   (1) reducing ''tol_cut'', currently set to %f\n', tol_cut);
    fprintf('[CLEANUPPB]   (2) reducing the length of reference job\n');
    return;
  end
    
  %% Computing the upper-left corners from the lower-right ones
  x_clean = zeros(N_LR*2-1,1);
  y_clean = zeros(N_LR*2-1,1);
  x_clean(1) = x_LR(1);
  y_clean(1) = y_LR(1);
  for i=1:N_LR-1,
    x_clean(2*i) = x_LR(i)+(y_LR(i+1)-y_LR(i))/max_slope;
    y_clean(2*i) = y_LR(i+1);
    x_clean(2*i+1) = x_LR(i+1);
    y_clean(2*i+1) = y_LR(i+1);
  end

  %% Computing the points on the convex upper envelope
  % slecting the indices over [x_clean y_clean]
  sel_conv = [1;2];            % must always belong to convex envelope
  % looping over the points in [x_clean y_clean] at even position at
  %
  %     2; 4; 6; ...; 2*(N_LR-1)
  %
  %   as the ones at odd position cannot belong to the convex envelope,
  %   except the ones at 1 and 2*N_LR-1, which always belong
  for i=2:N_LR-1,
    slope_env = (y_clean(sel_conv(2:end))-y_clean(sel_conv(1:end-1)))./(x_clean(sel_conv(2:end))-x_clean(sel_conv(1:end-1)));
    slope_new = (y_clean(2*i)-y_clean(sel_conv(1:end-1)))./(x_clean(2*i)-x_clean(sel_conv(1:end-1)));
    cond = (slope_env > slope_new);
    sel_conv = sel_conv([true; cond]);
    sel_conv = [sel_conv; 2*i];
  end
  % always add the last point
  sel_conv = [sel_conv; 2*N_LR-1];
  if (length(sel_conv) <= 2)
    fprintf('[CLEANUPPB] The points over the convex envelope are less than 3\n');
    fprintf('[CLEANUPPB]   This is bad!!\n');
  end

% still pasted from cleanlowb.m, likely to be erased
%  if (y_clean(sel_conv(2)) ~= y_clean(sel_conv(1)))
%    fprintf('[CLEANLOWB] The first two points over the convex envelope have not the same Y\n');
%    fprintf('[CLEANLOWB]   This is unexpected!!\n');
%  end

end

