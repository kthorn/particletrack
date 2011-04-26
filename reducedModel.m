classdef reducedModel < handle
    %reducedModel - stores reduced data from modeled dots - I vs. t,
    %               position vs t, etc.
    
    properties
        directory
        ncells
        nchannels
        master
        channels %info about each channel
        cells %information about each cell
        data %ncells by nchannels array with subfields to store results
        parentmodel %reference to model that data comes from
    end
    
    methods
        function newobj = reducedModel (inputmodel)
            %constructor
            %build a reducedModel object from a fitModel object
            newobj.directory = inputmodel.directory;
            newobj.master = inputmodel.master;
            newobj.parentmodel = inputmodel;
            
            %build channel list
            newchan = 1;
            for chan = 1:inputmodel.nchannels
                %skip unmodeled channels
                if strcmpi(inputmodel.channel(chan).modelname, 'None')
                    continue;
                end
                newobj.channels(newchan).name = inputmodel.channel(chan).name;
                newobj.channels(newchan).model = inputmodel.channel(chan).modelname;
                newobj.channels(newchan).source = chan;
                newchan = newchan + 1;
            end
            newobj.nchannels = newchan - 1;
            
            %populate data array
            %ignore cells that have fewer than Ngood successful fits
            Ngood = 10;
            newcell = 1;
            for cell = 1:inputmodel.ncells
                I = inputmodel.intensity(1,cell);
                if numel(I) < Ngood
                    continue;
                end
                for chan = 1:newobj.nchannels
                    newobj.data(newcell, chan).sourceCell = cell;
                    newobj.data(newcell, chan).coords = inputmodel.coords(newobj.channels(chan).source,cell);
                end
                newcell = newcell + 1;
            end
            newobj.ncells = newcell - 1;
            for chan = 1:newobj.nchannels
                newobj.setIntensity(chan);
                newobj.setDistance(chan);
            end
            
            %create flag storage
            for n=1:newobj.ncells
                newobj.cells(n).flags={};
            end
        end
        
        function setIntensity (obj, chan)
            %retrieve intensities from channel chan of a fitmodel object
            %for all cells and store them here
            for cell = 1:obj.ncells
                obj.data(cell, chan).intensity = obj.parentmodel.intensity(chan,cell);
            end
        end
        
        function setDistance (obj, chan)
            %retrieve distances from channel chan of a fitmodel object
            %for all cells and store them here
            for cell = 1:obj.ncells
                obj.data(cell, chan).distance = obj.parentmodel.distance(chan,cell);
            end
        end
        
        function modelIntensity(obj, chan)
            for cell = 1:obj.ncells
                obj.data(cell,chan).modelI = fit_disappearance_lin(obj.data(cell, chan).intensity);
            end
        end
        
        function MI = masterIndex(obj)
            %return index of master channel
            for chan = 1:obj.nchannels
                if strcmp(obj.master, obj.channels(chan).name)
                    MI = chan;
                end
            end
        end
        
        function addFlag(obj, cell, flagname)
            if any(strcmp(obj.cells(cell).flags, flagname))
                %flag exists, do nothing
            else
                nflags = numel(obj.cells(cell).flags);
                obj.cells(cell).flags{nflags+1} = flagname;
            end
        end
        
        function remFlag(obj, cell, flagname)
            obj.cells(cell).flags(strcmp(obj.cells(cell).flags, flagname)) = [];            
        end
        
        function flagged = isFlag(obj, cell, flagname)
            flagged = any(strcmp(obj.cells(cell).flags, flagname));
        end
        
        function ntime = nTimePoints(obj, cell)
            %return number of fitted time points for cell
            ntime = numel(obj.data(cell,1).intensity);
        end
        
        function setReport(obj, chan, reporttype)
            %return index of master channel
            for cidx = 1:obj.nchannels
                if strcmp(chan, obj.channels(cidx).name)
                    obj.channels(cidx).report = reporttype;
                end
            end
        end
        
        function report = getReport(obj, chan)
            %return index of master channel
            for cidx = 1:obj.nchannels
                if strcmp(chan, obj.channels(cidx).name)
                    report = obj.channels(cidx).report;
                end
            end
        end
        
    end
    
end

