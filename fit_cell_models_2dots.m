function model = fit_cell_models_2dots(ims, coord_list, len)
%fits a model of two gaussian spots plus a large gaussian to model nuclear
%background to an image of a yeast cell.

%ims is an X x Y x Z x T stack of images
%coord_list is an n x 3 array of cell coordinates
%len is the half size of the box to cut out

%returns model, a structure of the fit data.

%set up parameters
ntime = size(ims,4);
nz = size(ims,3);
ncells = size(coord_list,1);
[X,Y,Z]=meshgrid(1:2*len+1,1:2*len+1,1:nz);
coords=[X(:),Y(:),Z(:)];
fit_options = optimset('Display','off','Algorithm','levenberg-marquardt');

%censoring parameters
max_xy = (len*2+1) + 1;
min_xy = -1;
max_z = nz + 1;
min_z = -1;

%build model structure
zeroim = zeros([len*2+1 len*2+1 nz ntime],'uint16');
zerofitim = zeros([len*2+1 len*2+1 nz ntime],'uint16');
zeroparams = zeros([ntime 17]);
zerofit = zeros([1 ntime]);
model(1:ncells) = struct('im', zeroim, 'fitim', zerofitim, ...
    'raw_params', zeroparams, 'params', zeroparams, 'fit', zerofit);

for cell = 1:ncells
    %coordinates to take initial image from
    startcoords = [coord_list(cell,2), coord_list(cell,1)]; %these are flipped from return of regionprops
    for t=1:ntime
        %if startcoords would force subimage off edge of full image, reset
        %them appropriately
        startcoords = max(startcoords, len+1);
        startcoords(1) = min(startcoords(1), size(ims,1)-len-1);
        startcoords(2) = min(startcoords(2), size(ims,2)-len-1);
        
        im=ims(startcoords(1)-len:startcoords(1)+len,startcoords(2)-len:startcoords(2)+len,:,t);
        
        %sharpen image to find dots
        testimfilt = sharpen_image(im);
        
        %autothresholding
        thresh = max(testimfilt(:))/2;
        
        %find peaks
        s=regionprops(testimfilt > thresh, im, 'WeightedCentroid','MaxIntensity');
        peak = 1;
        
        %if multiple peaks, take one with brightest single pixel
        if size(s,1) > 1
            for n=1:size(s,1)
                if s(n).MaxIntensity > s(peak).MaxIntensity
                    peak = n;
                end
            end
        end
        
        %now fit a single gaussian to this peak
        initparams = double([]);
        initparams(1) = median(im(:));
        initparams(5) = s(peak).MaxIntensity;
        initparams(2:4) = s(peak).WeightedCentroid;
        
        result1=lsqcurvefit(@dotmodel_3d_dotonly,initparams,coords,double(im(:)),[],[],fit_options);
        fitim=dotmodel_3d_dotonly(result1,coords);
        fitim=uint16(reshape(fitim,size(im)));
        
        %%%%%%%%%%%%%%%%%%%%%%%
        %now add a 2nd dot
        
        %sharpen difference image to find 2nd dot
        diffim = im - fitim;
        testimfilt = sharpen_image(diffim);
        
        %autothresholding
        thresh = max(testimfilt(:))/2;
        
        %find peaks
        s=regionprops(testimfilt>thresh,diffim,'WeightedCentroid','MaxIntensity');
        peak = 1;
        
        %if multiple peaks, take one with brightest single pixel
        if size(s,1) > 1
            for n=1:size(s,1)
                if s(n).MaxIntensity > s(peak).MaxIntensity
                    peak = n;
                end
            end
        end
        
        %fit the 2 gaussian model to this
        initparams = result1;
        initparams(6:8) = s(peak).WeightedCentroid;
        initparams(9) = s(peak).MaxIntensity;
        result2=lsqcurvefit(@dotmodel_3d_2dotonly,initparams,coords,double(im(:)),[],[],fit_options);
        fitim=dotmodel_3d_2dotonly(result2,coords);
        fitim=uint16(reshape(fitim,size(im)));
        
        diffim = im - fitim;
        %estimate nuclear background location
        %find peaks (no sharpening)
        s=regionprops(diffim > max(diffim(:))/2, diffim, 'WeightedCentroid','MeanIntensity','Area');
        peak = 1;
        
        %if multiple peaks, take one with largest area
        if size(s,1) > 1
            for n=1:size(s,1)
                if (s(n).Area) > (s(peak).Area)
                    peak = n;
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %now fit the full model
        initparams(1) = result2(1);
        initparams(10:17) = result2(2:9);
        initparams(2:4) = s(peak).WeightedCentroid;
        initparams(5:6) = 5; %cell sigmaxy
        initparams(7) = 3; %cell sigmaz
        initparams(8) = 0; %cell covariance
        initparams(9) = s(peak).MeanIntensity * 2; %cell intensity
        result=lsqcurvefit(@dotmodel2_3d_nosigma,initparams,coords,double(im(:)),[],[],fit_options);
        fitim=dotmodel2_3d_nosigma(result,coords);
        fitim=uint16(reshape(fitim,size(im)));
        
        %generate censored version of results
        %censoring sets negative intensities to 0
        %and sets coordinates more than 1 pixel outside of the image to
        %the center of the image
        %intensities associated with censored coords are set to 0
        
        censored = result;
        %force negative values to 0
        censored(1,[13,17]) = max(censored(1,[13,17]),0);
        %test dot 1
        if any(censored(1,10:11) > max_xy) || any(censored(1,10:11) < min_xy) || ...
                censored(12) > max_z || censored(12) < min_z
            censored(1,[10,11]) = len+1;
            censored(12) = round(nz/2);
            censored(13) = 0;
        end
        %test dot 2
        if any(censored(1,14:15) > max_xy) || any(censored(1,14:15) < min_xy) || ...
                censored(16) > max_z || censored(16) < min_z
            censored(1,[14,15]) = len+1;
            censored(16) = round(nz/2);
            censored(17) = 0;
        end
        
        %update coordinates to image space
        updatedresult = update_coords_nosigma(result,startcoords(1),startcoords(2),len);
        updatedcensored = update_coords_nosigma(censored,startcoords(1),startcoords(2),len);
        
        %average coords of all 3 objects to determine center of next image
        startcoords(2) = round(mean([updatedcensored(2), updatedcensored(10), updatedcensored(14)]));
        startcoords(1) = round(mean([updatedcensored(3), updatedcensored(11), updatedcensored(15)]));
        
        %update model
        model(cell).im(:,:,:,t) = im;
        model(cell).fitim(:,:,:,t) = fitim;
        model(cell).raw_params(t,:) = updatedresult;
        model(cell).params(t,:) = updatedcensored;
        model(cell).fit(t) = sqrt(sum( (fitim(:) - im(:)).^2 ));
        
        dispim=max(im,[],3);
        dispim=[dispim;zeros([1 size(dispim,1)])];
        fitimd=max(fitim,[],3);
        dispim=[dispim; fitimd];
        
        figure(1)
        subplot(4,15,t)
        imshow(dispim, [], 'InitialMagnification', 'fit')
    end
end