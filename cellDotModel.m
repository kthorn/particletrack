classdef cellDotModel < handle
    %cellModel - Superclass for models of yeast cells with fluorescent dots
    %   a cellModel describes a dataset that models a 3d image of a single
    %   yeast cell
    
    properties (Abstract = true, SetAccess = private)
        n_submodels %how many submodels were tested
        preferred_submodel %which submodel to use for e.g. intensity
        
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
        fit(obj, data)
        %fit the model to data, updating parameters and fit properties
        
        
        
        I = getIntensity(obj, submodel)
        %return fitted dot intensity
        
        dist = getDistance(obj)
        %return distance between two dots in case of multi-dot model
        
        modelim = showModel(obj)
        %return the modeled image
        
        coords = finalCoords(obj, frame)
        %returns the best estimate for the center of the cell following
        %fitting
        %frame can be either 'sub' or 'full' depending on whether
        %coordinates should be in subimage coordiantes or full image
        %coordinates
        
        params = censoredParams(obj)
        %returns a cesored version of the model parameters, removing
        %nonsensical values
        
        grid = generateGrid(obj)
        
    end
    
    methods
        
        function set.sse(obj,value)
            obj.sse = value;
        end
        
        function status = isFit(obj)
            %return true if a fit has been done, false otherwise
            status = numel(obj.model_params)>0;
        end
    end
    
end

