classdef models
    properties
        modelnames = {'1 or 2dot','2dot','Track only','None'};
        modelfunctions = {@yeast_dot_track, @fit_cell_models_2dots, @track_only, @none};
    end
    methods
        function namelist = names(obj)
            %return the complete list of available models
            namelist = obj.modelnames;
        end
        function fh = getfunction(obj,name)
            fh = obj.modelfunctions(strcmpi(name, obj.modelnames));
        end
    end
    
end
