function result = fit_disappearance(intensities)

initI=max(intensities);
tend0=find(intensities < 2 * min(intensities(:)), 1 );
tstart0=find(intensities>(initI*0.6), 1, 'last' );
if isempty(tstart0)
    tstart0=1;
end
if isempty(tend0)
    tend0=tstart0+1;
end

maxtime = size(intensities,2);
tstart0 = min(maxtime - 1, tstart0);
tend0 = min(maxtime - tstart0 -1, tend0); %don't go past end of array

x=[initI, max(1,tstart0), max(1,tend0-tstart0), min(intensities)];

%simulated annealing parameters
%ANNEAL is from Joachim Vandekerckhove, found on Matlab Central
options.Generator = @params_generator;
options.Verbosity = 0;
%options.InitTemp = 10;
%options.MaxConsRej = 3000;

[result, fval] = anneal(@intmodel,x,options);

    function err=intmodel(x)
        
        %x(1) = initial intensity
        %x(2) = start of dissapearance
        %x(3) = end of dissapearance
        %x(4) = baseline
        
        %exponential decay rate - determined by fitting to non-disappearing dots
        k = 0.0035;
        tstart=x(2);
        tend=tstart+x(3);
        xdata=1:size(intensities,2);
        
        F(1:tstart)=x(1)* exp(-k * xdata(1:tstart));
        slope = (F(tstart) - x(4)) / (tend-tstart);
        F(tstart:tend) = F(tstart) - slope * (0:(tend-tstart));
        F(tend:size(intensities,2)) = x(4);
        %calculate error
        err = sum((intensities - F).^2);
    end


    function x = params_generator (x)
        % variability generator, choose one of the following at random
        % (1) move x(1) - initial intensity - by 5%, normally distributed
        % (2) move x(2) - disappearance start - by +/- 1
        % (3) move x(3) - disappearance end - by +/- 1
        % (4) move x(4) - final intensity - by 5%, normally distributed
        
        int_step_size = 0.05; %size of intensity steps to take
        opt = round(1 +  3 * rand(1));
        switch opt
            case 1
                x(1) = x(1) + (x(1) * int_step_size * randn(1));
            case 2
                step = round(2 * rand(1) - 1);
                x(2) = max(1, x(2) + step);
                x(2) = min(maxtime - 1, x(2));
                x(3) = min(maxtime - x(2) -1, x(3)); %don't go past end of array
            case 3
                step = round(2 * rand(1) - 1);
                x(3) = max(1, x(3) + step);
                x(3) = min(maxtime - x(2) -1, x(3)); %don't go past end of array
            case 4
                x(4) = x(4) + (x(4) * int_step_size * randn(1));
        end
    end

end