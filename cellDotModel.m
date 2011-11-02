classdef cellDotModel < handle
    %cellModel - Superclass for models of yeast cells with fluorescent dots
    %   a cellModel describes a dataset that models a 3d image of a single
    %   yeast cell
    
    properties (Abstract = true, SetAccess = private)
        n_submodels %how many submodels were tested
        
    end
    properties (SetAccess = protected, GetAccess = protected)
        %can be array of parameters of multiple models
        %e.g. if comparing one dot vs two dot model
        model_params %fitted model parameters
    end
    properties (SetAccess = protected) %, GetAccess = private)
        
        imsize %X, Y, Z dimensions of the image fitted to        
        %can be array of parameters of multiple models
        %e.g. if comparing one dot vs two dot model
        sse %sum of squared errors
    end
    
    properties
        boxsize
        initcoords %center of data that this model was fit to
        
    end
    
    methods (Abstract)
        fit(obj, data, sigmas)
        %fit the model to data, updating parameters and fit properties.  
        %Sigmas are widths of diffraction limited gaussians.     
        
        I = getIntensity(obj, submodel)
        %return fitted dot intensity
        
        dist = getDistance(obj, submodel, scale)
        %return distance between two dots in case of multi-dot model
        
        coords = getCoords(obj, submodel)
        %return x,y coordinates of object(s) for plotting
        
        modelim = showModel(obj, submodel, sigmas)
        %return the modeled image
        
        coords = finalCoords(obj, frame)
        %returns the best estimate for the center of the cell following
        %fitting
        %frame can be either 'sub' or 'full' depending on whether
        %coordinates should be in subimage coordiantes or full image
        %coordinates
        
        params = censoredParams(obj, submodel)
        %returns a cesored version of the model parameters, removing
        %nonsensical values
                
    end
    
    methods
        
        function set.sse(obj,value)
            obj.sse = value;
        end
        
        function status = isFit(obj)
            %return true if a fit has been done, false otherwise
            status = numel(obj.model_params)>0;
        end
        function grid = generategrid(obj)
            [x,y,z]=meshgrid(1:obj.imsize(1),1:obj.imsize(2),1:obj.imsize(3));
            grid=[x(:),y(:),z(:)];
        end
               
    end
    
end

