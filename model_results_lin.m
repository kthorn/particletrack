function F = model_results_lin(x)

%x(1) = initial intensity
%x(2) = midpoint of exponential
%x(3) = time constant
%x(4) = baseline

xdata=1:60;

k = 0.0035;
tmid = x(2);
m = x(3);

%baseline bleaching
F = x(1)* exp(-k * xdata);
%times constant followed by linear decay followed by 0
line = (m*(xdata-tmid)) + 0.5;
line = max(line,0);
line = min(line,1);
F = F.*line;
%plus baseline
F = F + x(4);
%calculate error

