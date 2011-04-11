classdef cellDotModel2Dots < cellDotModel
    %cellDotModel2Dots - Fits a 2 dot model to a yeast cell
    
    properties (SetAccess = private)
        n_submodels = 1
        preferred_submodel = 1
    end
    
    methods
        function fit(obj, im)
            imsize = size(im);
            %update object properties
            obj.imsize = imsize;
            coords = obj.generateGrid();
            
            fit_options = optimset('Display','off','Algorithm','levenberg-marquardt');
            %fit the model to data, updating parameters and fit properties
            
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
            [result, sse] = lsqcurvefit(@dotmodel2_3d_nosigma,initparams,coords,double(im(:)),[],[],fit_options);
            
            obj.model_params = result;
            obj.sse = sse;
        end
        
        function I = intensity(obj, ~)
            params = obj.censoredParams();
            I = params(13) + params(17);
            
            if isnan(I)
                I = 0;
            end
        end
        %return fitted dot intensity
        
        function fitim = showModel(obj)
            fitim=dotmodel2_3d_nosigma(obj.model_params,obj.generateGrid());
            fitim=uint16(reshape(fitim,obj.imsize));
        end
        
        function censored = censoredParams(obj)
            %this function should largely be for internal use
            %returns a copy of the model parameters where values for dots
            %that have intensities < 0 or that have drifted outside the
            %image are set to NaN.
            %generate censored parameters
            censored = obj.model_params;
            max_coords = obj.imsize + 1;
            min_coords = [0 0 0];
            
            %test dot 1
            if any(censored(1,10:12) > max_coords) || any(censored(1,10:12) < min_coords) || ...
                    censored(13) < 0
                censored(1,10:13) = NaN;
            end
            %test dot 2
            if any(censored(1,14:16) > max_coords) || any(censored(1,14:16) < min_coords) || ...
                    censored(17) < 0
                censored(1,14:17) = NaN;
            end
            
            %test cell - let it drift further
            max_coords = obj.imsize .*1.5;
            min_coords = obj.imsize .*-0.5;
            if any(censored(1,2:4) > max_coords) || any(censored(1,2:4) < min_coords) || ...
                    censored(9) < 0
                censored(1,2:9) = NaN;
            end
        end
        
        function coords = finalCoords(obj, frame)
            censored = obj.censoredParams;
            %average coords of all 3 objects to determine center of next image
            coords(2) = nanmean([censored(2), censored(10), censored(14)]);
            coords(1) = nanmean([censored(3), censored(11), censored(15)]);
            coords(3) = nanmean([censored(4), censored(12), censored(16)]);
            
            if strcmpi(frame , 'full')
                coords(1:2) = coords(1:2) + obj.initcoords(1:2) - (obj.boxsize+1);
            elseif strcmpi(frame , 'sub')
            else
                error('unknown keyword for frame')
            end
        end
        
        function grid = generateGrid(obj)
            [X,Y,Z]=meshgrid(1:obj.imsize(1),1:obj.imsize(2),1:obj.imsize(3));
            grid=[X(:),Y(:),Z(:)];
        end
        
    end
    
end

