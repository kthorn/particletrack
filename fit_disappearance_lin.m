function result = fit_disappearance_lin(intensities)

initI = max(intensities);
minI = min(intensities);
midI = (initI+minI) /2;

ntime = numel(intensities);
t0 = (max(find(intensities>=midI)) + min(find(intensities<=midI)))/2;

x=[initI, max(1,t0), -0.1, minI];

%simulated annealing parameters
%ANNEAL is from Joachim Vandekerckhove, found on Matlab Central
options.Generator = @params_generator;
options.Verbosity = 0;
%options.InitTemp = 10;
%options.MaxConsRej = 3000;

[result, fval] = anneal(@intmodel,x,options);

    function err=intmodel(x)
        
        F = model_results_lin(x, 1:ntime);
        err = sum((intensities - F).^2);
    end


    function x = params_generator (x)
        % variability generator, choose one of the following at random
        % (1) move x(1) - initial intensity - by 5%, normally distributed
        % (2) move x(2) - midpoint - by 1 time point, normally distributed
        % (3) move x(3) - time constant - by 5%, normally distributed
        % (4) move x(4) - final intensity - by 5%, normally distributed

        
        int_step_size = 0.05; %size of intensity steps to take
        opt = round(1 +  3 * rand(1));
        switch opt
            case 1
                x(1) = x(1) + (x(1) * int_step_size * randn(1));
            case 2
                step = 2 * rand(1) - 1;
                x(2) = x(2) + step;
            case 3
                x(3) = x(3) + (x(3) * int_step_size * randn(1));
            case 4
                x(4) = x(4) + (x(4) * int_step_size * randn(1));
        end
    end

end