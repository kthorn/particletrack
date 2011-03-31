classdef models
    properties
        %name of model
        modelnames = {'1 or 2dot','2dot','Track only','None'};
        %function handles to class that implements that model
        %should inherit from cellDotModel
        modelfunctions = {@yeast_dot_track, @cellDotModel2Dots, @track_only, @none};
    end
    methods
        function namelist = names(obj)
            %return the complete list of available models
            namelist = obj.modelnames;
        end
        function fh = getFitFunc(obj,name)
            fh = obj.modelfunctions{strcmpi(name, obj.modelnames)};
        end
        
    end
    
end
