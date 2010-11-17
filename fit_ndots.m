function ndots = fit_ndots (fitratio)
% ndots is a 1 x t array equal to 1 or 2 depending on how many dots this
% function determined fit the data best
% fitratio is 2dot error / 1dot error

%parameters
%switch_penalty = 15; %penalty paid for switching between 1 and 2 dot states
switch_penalty = 10;

%error for 1 dot prediction = (fitratio - mean_1dot)/sigma_1dot for
%fitratio < mean_1dot, 0 otherwise.
mean_1dot = 1; %expected ratio value for 1 dot case
sigma_1dot = 0.01;
%sigma_1dot = 0.02;

%error for 2 dot prediction = (fitratio - mean_2dot)/sigma_2dot for
%fitratio > mean_2dot, 0 otherwise.
mean_2dot = 0.92; %expected ratio value for 2 dot case
sigma_2dot = 0.01;
%mean_2dot = 0.82; %expected ratio value for 2 dot case
%sigma_2dot = 0.02;

%initial guess
H = [1 1 1]/3; %3 bin smoothing
ndots = uint8(imfilter(fitratio,H,'symmetric') > mean_2dot);
ndots(ndots == 0) = 2;

%simulated annealing parameters
%ANNEAL is from Joachim Vandekerckhove, found on Matlab Central
options.Generator = @ndots_generator;
options.Verbosity = 0;
%options.InitTemp = 10;
%options.MaxConsRej = 3000;

[ndots, fval] = anneal(@errfunc,ndots,options);

    function err = errfunc(ndots)  
        %1 dot case
        dots = ndots == 1 & fitratio < mean_1dot;
        err_1 = sum((mean_1dot - fitratio(dots)) / sigma_1dot);
        
        %2 dot case
        dots = ndots == 2 & fitratio > mean_2dot;
        err_2 = sum((fitratio(dots) - mean_2dot) / sigma_2dot);
        
        %penalty
        nswitches = size(find(diff(ndots)),2);
        err_s = nswitches * switch_penalty;
        
        err = err_1 + err_2 + err_s;
    end

    function ndots = ndots_generator (ndots)
        %flip from 1 <-> 2 dots at a random time point
        r = round(1 + (size(ndots,2)-1) * rand(1));
        if ndots(r) == 1;
            ndots(r) = 2;
        else 
            ndots(r) = 1;
        end
    end
        
end