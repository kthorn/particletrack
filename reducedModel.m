classdef reducedModel < handle
    %reducedModel - stores reduced data from modeled dots - I vs. t,
    %               position vs t, etc.
    
    properties
        directory
        ncells
        ntime
        nchannels
        flags
        cells %ncells by nchannels array with subfields to store results
        parentmodel %reference to model that data comes from
    end
    
    methods
        function newobj = reducedModel (inputmodel)
            %constructor
            %build a reducedModel object from a fitModel object
            newobj.directory = inputmodel.directory;
            %newobj.ncells = inputmodel.ncells;
            newobj.ntime = inputmodel.ntime;
            newobj.nchannels = inputmodel.nchannels;
            newobj.parentmodel = inputmodel;
            
            %populate cells array
            %ignore cells that have fewer than Ngood successful fits
            Ngood = 10;
            newcell = 1;
            for cell = 1:inputmodel.ncells
                I = inputmodel.intensity(1,cell);
                if numel(I) < Ngood
                    continue;
                end
                for chan = 1:inputmodel.nchannels
                    I = inputmodel.intensity(chan,cell);
                    newobj.cells(newcell, chan).intensity = I;
                    newobj.cells(newcell, chan).sourceCell = cell;
                end
                newcell = newcell + 1;
            end
            newobj.ncells = newcell - 1;
        end
        
        function setIntensity (obj, chan)
            %retrieve intensities from channel chan of a fitmodel object
            %for all cells and store them here
            for cell = 1:obj.ncells
                obj.cells(cell, chan).intensity = obj.parentmodel.intensity(chan,cell);
            end
        end
        
        function modelIntensity(obj, chan)
            for cell = 1:obj.ncells
                obj.cells(cell,chan).modelI = fit_disappearance_lin(obj.cells(cell, chan).intensity);
                
            end
        end
    end
    
end

