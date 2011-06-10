classdef cellDotModelTrack2Dots < cellDotModel
    %cellDotModelTrackOnly - tracks 2 dots in an image
    
    properties (SetAccess = private)
        n_submodels = 1
        preferred_submodel = 1
    end
    
    methods
        function fit(obj, im)
%             disp('fitting...')
%             figure(1)
%             imshow(max(im,[],3),[])
%             drawnow
            obj.imsize = size(im);
            testimfilt = sharpen_image(im);
            
            %find a threshold that returns two peaks
            
            hi_thresh = max(testimfilt(:));
            lo_thresh = min(testimfilt(:)) + hi_thresh/10;
            %curr_thresh = max(testimfilt(:));
            curr_thresh = lo_thresh;
            prev_thresh = -1;
            s=regionprops(testimfilt > curr_thresh, im, 'WeightedCentroid','MaxIntensity','Area');
            if numel(s) < 2
                %if we can't find two peaks at low threshold, they are
                %likely close together, so start high and work down.
                curr_thresh = hi_thresh;
            end
            while numel(s) ~= 2
                if numel(s) > 2
                    %threshold too low
                    lo_thresh = curr_thresh;
                    prev_thresh = curr_thresh;
                    curr_thresh = curr_thresh + (hi_thresh - curr_thresh)/10;
                elseif numel(s) < 2
                    if abs(curr_thresh - lo_thresh) < 1
                        %already at minimum
                        break;
                    end
                    %threshold too high
                    hi_thresh = curr_thresh;
                    prev_thresh = curr_thresh;
                    curr_thresh = curr_thresh + (lo_thresh - curr_thresh)/10;
                end
                %find peaks
                s=regionprops(testimfilt > curr_thresh, im, 'WeightedCentroid', 'MaxIntensity', 'Area');
                if abs(hi_thresh - lo_thresh) < 1
                    %two peaks of equal intensity
                    break;
                end
            end
            %delete single pixel events
            bad=[];
            for n=1:numel(s)
                if s(n).Area == 1;
                    bad = n;
                end
            end
            if ~isempty(bad)
                s(bad)=[];
            end
            if numel(s) < 2
                obj.model_params = [s(1).WeightedCentroid, s(1).WeightedCentroid, s(1).MaxIntensity, s(1).MaxIntensity];
                %disp ('less than 2 peaks')
            else
                obj.model_params = [s(1).WeightedCentroid, s(2).WeightedCentroid, s(1).MaxIntensity, s(2).MaxIntensity];
            end
            obj.sse = NaN;
            %store intensity so we can scale displayed image correctly

        end
        
        function fitim = showModel(obj, ~)
            fitim = zeros(obj.imsize);
            coords = round(obj.model_params);
            fitim(coords(2), coords(1), coords(3)) = coords(7);            
            fitim(coords(5), coords(4), coords(6)) = coords(7);
        end
        
        function censored = censoredParams(obj, ~)
            %this function should largely be for internal use
            %returns a copy of the model parameters where values for dots
            %that have intensities < 0 or that have drifted outside the
            %image are set to nan.
            %generate censored parameters
            censored = double(obj.model_params);
        end
        
        function coords = finalCoords(obj, frame)
            censored = obj.censoredParams(1);
            coords(2) = (censored(2)*censored(7) + censored(5)*censored(8))/(censored(7)+censored(8));
            coords(1) = (censored(1)*censored(7) + censored(4)*censored(8))/(censored(7)+censored(8));
            
            if strcmpi(frame , 'full')
                coords(1:2) = coords(1:2) + obj.initcoords(1:2) - (obj.boxsize+1);
            elseif strcmpi(frame , 'sub')
            else
                error('unknown keyword for frame')
            end
        end
        
        function coords = getCoords(obj)
            %return coordinates of preferred submodel
            censored = obj.censoredParams(1);
            coords(1,:) = censored(1:2) + obj.initcoords(1:2) - (obj.boxsize+1);
            coords(2,:) = censored(4:5) + obj.initcoords(1:2) - (obj.boxsize+1);
        end
        
        function i = getIntensity(obj, ~)
            i = 0;
        end
        
        function dist = getDistance(obj, submodel)
            coords = obj.censoredParams(submodel);
            dist = sqrt(sum((coords(1:3)-coords(4:6)).^2));
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

