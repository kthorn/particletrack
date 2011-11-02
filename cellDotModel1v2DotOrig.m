classdef cellDotModel1v2DotOrig < cellDotModel
    %cellDotModel1v2DotOrig - fits a 1 and a 2 dot model to a yeast cell.
    %uses original particletrack code.
    
    properties (SetAccess = private)
        n_submodels = 2
        preferred_submodel = 1
    end
    
    methods
        function fit(obj, im, sigmas)
%             disp('fitting...')
%             figure(1)
%             imshow(max(im,[],3),[])
%             drawnow 
            im = double(im); %to make LSQcurvefit happy
            imsize = size(im);
            len = (imsize(1)-1)/2;
            %update object properties
            obj.imsize = imsize;
            coords = obj.generategrid();
            Imax = max(im(:));
            nz = imsize(3);
            
            %bounds on coordinates
            %parameters     bkgd  nuc x        y   z  sx  sy  sz cov int      dot x        y   z  int
            lb =          [0,         0,       0,    0,  3,  3, 2, -1,   0,       0,       0,    0,   0];
            ub =          [Inf, len*2+2, len*2+2, nz+2, 10, 10, 8,  1, Inf, len*2+2, len*2+2, nz+2, Inf];
            
            lb2 =         [0,         0,       0,    0,  3,  3,  2, -1,   0,       0,       0,    0,   0,      -1,      -1,   -1];
            ub2 =         [Inf, len*2+2, len*2+2, nz+2, 10, 10,  8,  1, Inf, len*2+2, len*2+2, nz+2, Inf, len*2+3, len*2+3, nz+2];
            initparams = double([min(im(:)), len+1, len+1, 5, 4, 4, 3, 0, Imax/5, len+1, len+1, 5, Imax]);
            
            fit_options = optimset('Display','off');
            
            %fit the model to data, updating parameters and fit properties
            
            %sharpen image to find dots
            testimfilt = sharpen_image(im);
            
            peak = find(testimfilt == max(testimfilt(:)));
            [q,r,s]=ind2sub(size(testimfilt),peak);
            initparams(10:12)=[r,q,s];
            
            
            fitfunc = @(x, xdata)dotmodel_3d_nosigma(x, xdata, sigmas);   
            [result, sse] = lsqcurvefit(fitfunc,initparams,coords,im(:),lb,ub,fit_options);
            obj.model_params{1} = result;
            obj.sse(1) = sse;
            fitim = dotmodel_3d_nosigma(result,coords,sigmas);
            fitim = reshape(fitim,size(im));
            
            %best guesses for 2 dots coordinates
            initparams = result;
            residim = im-fitim;
            testimfilt = sharpen_image(residim);
            peak = find(testimfilt == max(testimfilt(:)));
            [q,r,s] = ind2sub(size(testimfilt),peak);
            initparams(14:16) = [r,q,s];
            
            fitfunc = @(x, xdata)dotmodel2_3d_nosigma_1i(x, xdata, sigmas);
            [result, sse] = lsqcurvefit(fitfunc,initparams,coords,im(:),lb2,ub2,fit_options);
            obj.model_params{2} = result;
            obj.sse(2) = sse;
        end
               
        function fitim = showModel(obj, submodel, sigmas)
            switch submodel
                case 1
                    fitim=dotmodel_3d_nosigma(obj.model_params{submodel}, obj.generategrid(), sigmas);
                case 2                    
                    fitim=dotmodel2_3d_nosigma_1i(obj.model_params{submodel}, obj.generategrid(), sigmas);
            end
            fitim=uint16(reshape(fitim,obj.imsize));
        end
        
        function censored = censoredParams(obj, submodel)
            %this function should largely be for internal use
            %returns a copy of the model parameters where values for dots
            %that have intensities < 0 or that have drifted outside the
            %image are set to nan.
            %don't censor, since we enforce bounds on the fit.
            censored = obj.model_params{submodel};
        end
        
        function coords = finalCoords(obj, frame)
            %always use 1 dot model
            censored = obj.censoredParams(1);
            %use just center of nucleus for fit
            coords(2) = censored(3);
            coords(1) = censored(2);
            
            if strcmpi(frame , 'full')
                coords(1:2) = coords(1:2) + obj.initcoords(1:2) - (obj.boxsize+1);
            elseif strcmpi(frame , 'sub')
            else
                error('unknown keyword for frame')
            end
        end
               
        function coords = getCoords(obj)
            %return coordinates of preferred submodel
            censored = obj.censoredParams(obj.preferred_submodel);
            coords(1,:) = censored(10:11) + obj.initcoords(1:2) - (obj.boxsize+1);
            if obj.preferred_submodel == 2
                coords(2,:) = censored(14:15) + obj.initcoords(1:2) - (obj.boxsize+1);
            end
        end
        
        function i = getIntensity(obj, submodel)
            %return fitted dot intensity
            switch submodel
                case 1
                    params = obj.censoredParams(submodel);
                    i = params(13);
                case 2
                    params = obj.censoredParams(submodel);
                    i = params(13) * 2;
            end
            if isnan(i)
                i = 0;
            end
        end
        
        function dist = getDistance(obj, submodel)
            switch submodel
                case 1
                    dist = 0;
                case 2
                    coords = obj.censoredParams(submodel);
                    dist = sqrt(sum((coords(10:12)-coords(14:16)).^2));
            end            
        end
        
        function setPreferredSubmodel(obj, submodel)
            if submodel < 1 || submodel > obj.n_submodels
                error('submodel index is out of bounds')
            else
                obj.preferred_submodel = submodel;
            end
        end
        
    end    
end

