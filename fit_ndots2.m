function ndots = fit_ndots2 (fitratio, crossover, switch_penalty)
% ndots is a 1 x t array equal to 1 or 2 depending on how many dots this
% function determined fit the data best
% fitratio is 2dot error / 1dot error

%parameters
sigma = 0.01;

%initial guess
H = [1 1 1]/3; %3 bin smoothing
ndots = uint8(imfilter(fitratio,H,'symmetric') > crossover);
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
        dots = ndots == 1;
        err_1 = sum((crossover - fitratio(dots)) ./ sigma);
        
        %2 dot case
        dots = ndots == 2;
        err_2 = sum((fitratio(dots) - crossover) ./ sigma);
        
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