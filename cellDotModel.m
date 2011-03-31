classdef cellDotModel < handle
    %cellModel - Superclass for models of yeast cells with fluorescent dots
    %   a cellModel describes a dataset that models a 3d image of a single
    %   yeast cell
    
    properties (SetAccess = protected) %, GetAccess = private)
        initcoords %center of data that this model was fit to
        imsize %X, Y, Z dimensions of the image fitted to
        
        grid %pixel grid that data was fit on
        %both of these can be arrays of parameters of multiple models
        %e.g. if comparing one dot vs two dot model
        model_params %fitted model parameters
        sse %sum of squared errors
    end
    
    methods (Abstract)
        fit(obj, data)
        %fit the model to data, updating parameters and fit properties
        
        I = intensity(obj)
        %return fitted dot intensity
        
        modelim = showModel(obj)
        %return the modeled image
        
        coords = finalCoords(obj)
        %returns the best estimate for the center of the cell following
        %fitting
        
        params = censoredParams(obj)
        %returns a cesored version of the model parameters, removing
        %nonsensical values
    end
    
    methods
        function set.grid(obj,value)
            obj.grid = value;
        end
        function set.sse(obj,value)
            obj.sse = value;
        end
    end
    
end

