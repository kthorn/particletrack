function F = model_results_lin(x0,xdata)

%x(1) = initial intensity
%x(2) = midpoint of exponential
%x(3) = time constant
%x(4) = baseline

k = 0.0035; %photobleaching rate
tmid = x0(2);
m = x0(3);

%baseline bleaching
F = x0(1)* exp(-k * xdata);
%times constant followed by linear decay followed by 0
line = (m*(xdata-tmid)) + 0.5;
line = max(line,0);
line = min(line,1);
F = F.*line;
%plus baseline
F = F + x0(4);
%calculate error

