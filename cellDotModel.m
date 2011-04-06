classdef cellDotModel < handle
    %cellModel - Superclass for models of yeast cells with fluorescent dots
    %   a cellModel describes a dataset that models a 3d image of a single
    %   yeast cell
    
    properties (SetAccess = protected) %, GetAccess = private)
        
        imsize %X, Y, Z dimensions of the image fitted to
        
        %both of these can be arrays of parameters of multiple models
        %e.g. if comparing one dot vs two dot model
        model_params %fitted model parameters
        sse %sum of squared errors
    end
    
    properties
        boxsize
        initcoords %center of data that this model was fit to
    end
    
    methods (Abstract)
        fit(obj, data)
        %fit the model to data, updating parameters and fit properties
        
        I = intensity(obj)
        %return fitted dot intensity
        
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
    end
    
end

