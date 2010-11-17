function result = dotfit(intensities)

initI=max(intensities);
tend0=find(intensities < 2 * min(intensities(:)), 1 );
tstart0=find(intensities>(initI*0.6), 1, 'last' );
if isempty(tstart0)
    tstart0=1;
end
if isempty(tend0)
    tend0=tstart0+1;
end

x0=[initI, max(1,tstart0), max(1,tend0-tstart0), min(intensities)];
options=optimset('MaxFunEvals',1e6);

result = fminsearch(@intmodel,x0,options);

    function err=intmodel(x)
        
        %x(1) = initial intensity
        %x(2) = start of dissapearance
        %x(3) = end of dissapearance
        %x(4) = baseline
        
        %exponential decay rate - determined by fitting to non-disappearing dots
        k = 0.0035;
        x(2)=round(x(2));
        x(3)=round(x(3));
        x(2)=max(1,x(2));
        x(3)=max(1,x(3));
        tstart=x(2);
        tend=tstart+x(3);
        xdata=1:size(intensities,2);
        tend=min(tend,size(xdata,2));
        tstart=min(tstart,size(xdata,2));
        
        F(1:tstart)=x(1)* exp(-k * xdata(1:tstart));
        slope = F(tstart) / (tend-tstart);
        F(tstart:tend) = F(tstart) - slope * (0:(tend-tstart));
        F(tend:size(intensities,2))=0;
        F=F+x(4);
        %calculate error
        err = sum((intensities - F).^2);
    end
end