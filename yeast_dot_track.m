function model = yeast_dot_track_test(ims, model, len)
%%

nz=size(ims,3);

%parameters     bkgd  nuc x        y   z  sx  sy  sz cov int      dot x        y   z  int
lb =          [0,        -1,      -1,   -1,  3,  3, 2, -1,   0,      -1,      -1,   -1,   0];
ub =          [Inf, len*2+3, len*2+3, nz+2, 10, 10, 8,  1, Inf, len*2+3, len*2+3, nz+2, Inf];

lb2 =         [0,        -1,      -1,   -1,  3,  3,  2, -1,   0,      -1,      -1,   -1,   0,      -1,      -1,   -1];
ub2 =         [Inf, len*2+3, len*2+3, nz+2, 10, 10,  8,  1, Inf, len*2+3, len*2+3, nz+2, Inf, len*2+3, len*2+3, nz+2];
[X,Y,Z]=meshgrid(1:2*len+1,1:2*len+1,1:nz);
coords=[X(:),Y(:),Z(:)];
h=fspecial('log',5,1);
ntime=size(ims,4);

fit_options = optimset('Display','off');

%allocate memory for model structure
for n=1:size(model,2)
        model(n).params_1dot = zeros([ntime 13]);
        model(n).fit_1dot = zeros([1 ntime]);
        model(n).startims = zeros([len*2+1 len*2+1 nz ntime],'uint16');
        model(n).modelims_1dot = zeros([len*2+1 len*2+1 nz ntime],'uint16');
        model(n).modelims_2dot = zeros([len*2+1 len*2+1 nz ntime],'uint16');
        model(n).params_2dot = zeros([ntime 16]);
        model(n).fit_2dot = zeros([1 ntime]);
end
        
tic
%first time point, starting from initial guessed coordinates
parfor n=1:size(model,2)
    initparams1=model(n).initparams(1:13);
    initparams1(2:3)=len+1;
    initparams1(10:11)=len+1;

    %pull out subregion
    testim=double(ims(model(n).initparams(10)-len:model(n).initparams(10)+len,model(n).initparams(11)-len:model(n).initparams(11)+len,:,1));
    result=lsqcurvefit(@dotmodel_3d_nosigma,initparams1,coords,testim(:),lb,ub,fit_options);
    %adjust back to original coordinates
    updatedresult = update_coords_nosigma(result,model(n).initparams(10),model(n).initparams(11),len);
    model(n).params_1dot=updatedresult;
    fitim=dotmodel_3d_nosigma(result,coords);
    model(n).fit_1dot=sum((fitim(:)-testim(:)).^2);
    model(n).startims=uint16(testim);
    fitim = reshape(fitim,size(testim));
    model(n).modelims_1dot=uint16(fitim);
    
    %best guesses for 2 dots coordinates
    initparams=result;
    residim=testim-fitim;
    testimfilt = zeros(size(residim));
    for z=1:size(residim,3)
        testimfilt(:,:,z)=imfilter(residim(:,:,z),-h,'symmetric');
    end
    peak=find(testimfilt == max(testimfilt(:)));
    [q,r,s]=ind2sub(size(testimfilt),peak);
    initparams(14:16)=[r,q,s];
    
    result2=lsqcurvefit(@dotmodel2_3d_nosigma_1i,initparams,coords,testim(:),lb2,ub2,fit_options);
    updatedresult2 = update_coords_nosigma(result2,model(n).initparams(10),model(n).initparams(11),len);
    model(n).params_2dot=updatedresult2;
    fitim2=dotmodel2_3d_nosigma_1i(result2,coords);
    model(n).fit_2dot=sum((fitim2(:)-testim(:)).^2);
    model(n).modelims_2dot=uint16(reshape(fitim2,size(testim)));
end
%%
for t=2:size(ims,4)
    toc
    tic
    %check for points that have drifted too close to edge of image and
    %delete them from model
    for n=1:size(model,2)
        if (n > size(model,2))
            break;
        end
        startx = round(model(n).params_1dot(t-1,2)-len);
        endx = round(model(n).params_1dot(t-1,2)+len);
        starty = round(model(n).params_1dot(t-1,3)-len);
        endy = round(model(n).params_1dot(t-1,3)+len);        
        if startx < 1 || starty < 1 || endx > size(ims,2) || endy > size(ims,1) 
            model(n)=[];
        end
    end    
    
    parfor n=1:size(model,2)

        %pull out subregion 
        %use nucleus center
        startx = round(model(n).params_1dot(t-1,2)-len);
        endx = round(model(n).params_1dot(t-1,2)+len);
        starty = round(model(n).params_1dot(t-1,3)-len);
        endy = round(model(n).params_1dot(t-1,3)+len);
        
        testim=double(ims(starty:endy,startx:endx,:,t));
        
        initparams=model(n).params_1dot(t-1,:);
        initparams(2:3)=len+1;  %nucleus is center of box 
        %offset old coords
        %initparams(10:11)=len+1 + model(n).params_1dot(t-1,10:11) -model(n).params_1dot(t-1,2:3);
        
        %find brightest point to use as dot center. Works better than above
        %as dot can drift out of f.o.v.
        
        testimfilt = zeros(size(testim));
        for z=1:size(testim,3)
            testimfilt(:,:,z)=imfilter(testim(:,:,z),-h,'symmetric');
        end
        peak=find(testimfilt == max(testimfilt(:)));
        [q,r,s]=ind2sub(size(testimfilt),peak);
        initparams(10:12)=[r,q,s];
        
        result=lsqcurvefit(@dotmodel_3d_nosigma,initparams,coords,testim(:),lb,ub,fit_options);
        updatedresult = update_coords_nosigma(result,model(n).params_1dot(t-1,3),model(n).params_1dot(t-1,2),len);
        model(n).params_1dot(t,:) = updatedresult;
        fitim = dotmodel_3d_nosigma(result,coords);
        model(n).fit_1dot(t) = sum((fitim(:)-testim(:)).^2);
        model(n).startims(:,:,:,t) = uint16(testim);
        fitim = reshape(fitim,size(testim));
        model(n).modelims_1dot(:,:,:,t) = uint16(fitim);
        
        %best guesses for 2 dots coordinates
        initparams=result;
        residim=testim-fitim;
        testimfilt = zeros(size(residim));
        for z=1:size(residim,3)
            testimfilt(:,:,z)=imfilter(residim(:,:,z),-h,'symmetric');
        end
        peak=find(testimfilt == max(testimfilt(:)));
        [q,r,s]=ind2sub(size(testimfilt),peak);
        initparams(14:16)=[r,q,s];
        
        result2=lsqcurvefit(@dotmodel2_3d_nosigma_1i,initparams,coords,testim(:),lb2,ub2,fit_options);
        updatedresult2 = update_coords_nosigma(result2,model(n).params_1dot(t-1,3),model(n).params_1dot(t-1,2),len);
        model(n).params_2dot(t,:) = updatedresult2;
        fitim2 = dotmodel2_3d_nosigma_1i(result2,coords);
        model(n).fit_2dot(t) = sum((fitim2(:)-testim(:)).^2);
        model(n).modelims_2dot(:,:,:,t) = uint16(reshape(fitim2,size(testim)));
    end
end