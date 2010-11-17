function F = model_results(x)
k = 0.0035;
tstart=x(2);
tend=tstart+x(3);
xdata=1:60;

F(1:tstart)=x(1)* exp(-k * xdata(1:tstart));

slope = (F(tstart) - x(4)) / (tend-tstart);
F(tstart:tend) = F(tstart) - slope * (0:(tend-tstart));
F(tend:size(xdata,2))=x(4);
