function [x_clean, y_clean, sel_conv] = cleanlowb(x,y,max_slope, tol_cut)
% CLEANLOWB
% Input:
%   x, x coordinate of the supply lower bound (column vector)
%   y, y coordinate of the supply lower bound (column vector). Should have
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

  % computing the upper-left corners of the supply lower bound
  x_UL = x(1);
  y_UL = y(1);
  
  for i=2:N,
    % removing point in the current (x_UL,y_UL) which are dominated by the
    % new one (x(i),y(i))
    select = (y(i)-y_UL < max_slope*(1-tol_cut)*(x(i)-x_UL));
    x_UL = x_UL(select);
    y_UL = y_UL(select);
    % adding the new one, always
    x_UL = [x_UL; x(i)];
    y_UL = [y_UL; y(i)];
  end
  
  N_UL = length(x_UL);
  if (N_UL <= 1)
    fprintf('[CLEANLOWB] Too few points. Try the following:\n');
    fprintf('[CLEANLOWB]   (1) reducing ''tol_cut'', currently set to %f\n', tol_cut);
    fprintf('[CLEANLOWB]   (2) reducing the length of reference job\n');
    return;
  end
    
  % computing the lower-right corners from the upper-left ones
  x_clean = zeros(N_UL*2-1,1);
  y_clean = zeros(N_UL*2-1,1);
  x_clean(1) = x_UL(1);
  y_clean(1) = y_UL(1);
  
  for i=1:N_UL-1,
    x_clean(2*i) = x_UL(i+1)-(y_UL(i+1)-y_UL(i))/max_slope;
    y_clean(2*i) = y_UL(i);
    x_clean(2*i+1) = x_UL(i+1);
    y_clean(2*i+1) = y_UL(i+1);
  end

  % computing the points on the convex lower envelope
  sel_conv = [1;2];
  for i=2:N_UL-1,
    slope_env = (y_clean(sel_conv(2:end))-y_clean(sel_conv(1:end-1)))./(x_clean(sel_conv(2:end))-x_clean(sel_conv(1:end-1)));
    slope_new = (y_clean(2*i)-y_clean(sel_conv(1:end-1)))./(x_clean(2*i)-x_clean(sel_conv(1:end-1)));
    cond = (slope_env < slope_new);
    sel_conv = sel_conv([true; cond]);
    sel_conv = [sel_conv; 2*i];
  end

  % always add the last point
  sel_conv = [sel_conv; 2*N_UL-1];
  if (length(sel_conv) <= 2)
    fprintf('[CLEANLOWB] The points over the convex envelope are less than 3\n');
    fprintf('[CLEANLOWB]   This is bad!!\n');
  end

  if (y_clean(sel_conv(2)) ~= y_clean(sel_conv(1)))
    fprintf('[CLEANLOWB] The first two points over the convex envelope have not the same Y\n');
    fprintf('[CLEANLOWB]   This is unexpected!!\n');
  end

end

