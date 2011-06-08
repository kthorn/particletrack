classdef fitModel < handle
    %fitmodel - an objeect describing the fitted model for a stack of yeast
    %images in particletrack2
    
    properties (SetAccess = private)
        directory;
        boxsize;
        master; %name of master channel
        ncells;
        ntime;
        nchannels;
    end
    properties
        channel;
        
        % channel is an array with subproperties
        % name
        % modelname - name of the model that was fit to
        % nmodels - how many models an individual fitter returns
        % models - all the fits to that channel
        %        this is a ncells x ntime array of celldotmodels
    end
    methods
        function newobj = fitModel (inputdata, ntime)
            %creates a new fit model from inputdata, which is a
            %fitdatadescriptor object
            
            %copy params
            newobj.directory = inputdata.directory;
            newobj.master = inputdata.master;
            newobj.boxsize = inputdata.boxsize;
            
            clist = inputdata.getChannelNames();
            nn=1;
            for n=1:numel(clist)
                model = inputdata.getModelName(clist{n});
                %don't include unmodeled channels
                if ~strcmpi(model, 'None');
                    newobj.channel(nn).name = clist{n};
                    newobj.channel(nn).modelname = model;
                    nn=nn+1;
                end
            end
            
            newobj.nchannels = nn-1;
            newobj.ntime = ntime;
            newobj.ncells = inputdata.getNumCells;
            modlist = models;
            %initialize models
            for n = 1:newobj.nchannels
                mh = modlist.getFitFunc(newobj.channel(n).modelname);
                %build array of model objects
                newobj.channel(n).models(newobj.ncells, newobj.ntime) = mh();
            end
        end
        
        function channellist = getChannelNames(obj)
            channellist={};
            for n=1:numel(obj.channel)
                channellist{n} = obj.channel(n).name;
            end
        end
        
        function chan_idx = getChannelIndex(obj, name);
            chan_idx =0;
            for n=1:numel(obj.channel)
                if strcmp(obj.channel(n).name, name)
                    chan_idx = n;
                end
            end
        end
        
        function I = intensity(obj, chan, cell, varargin)
            %one optional argument - submodel to get intensity for
            %if omitted, uses preferred submodel
            %returns vector of intensity vs. time
            %length of I may be less than ntime if model got lost
            
            if numel(varargin) == 0
                for t = 1:obj.ntime
                    submodel = obj.channel(chan).models(cell,t).preferred_submodel;
                    if obj.channel(chan).models(cell,t).isFit
                        I(t) = obj.channel(chan).models(cell,t).getIntensity(submodel);
                    else
                        I(t) = NaN;
                    end
                end
            else
                submodel = varargin{1};
                for t = 1:obj.ntime
                    if obj.channel(chan).models(cell,t).isFit
                        I(t) = obj.channel(chan).models(cell,t).getIntensity(submodel);
                    else
                        I(t) = NaN;
                    end
                end
            end
        end
        
        function dist = distance(obj, chan, cell, varargin)
            %one optional argument - submodel to get intensity for
            %if omitted, uses preferred submodel
            %returns vector of intensity vs. time
            %length of I may be less than ntime if model got lost
            
            if numel(varargin) == 0
                for t = 1:obj.ntime
                    submodel = obj.channel(chan).models(cell,t).preferred_submodel;
                    if obj.channel(chan).models(cell,t).isFit
                        dist(t) = obj.channel(chan).models(cell,t).getDistance(submodel);
                    else
                        dist(t) = NaN;
                    end
                end
            else
                submodel = varargin{1};
                for t = 1:obj.ntime
                    if obj.channel(chan).models(cell,t).isFit
                        dist(t) = obj.channel(chan).models(cell,t).getDistance(submodel);
                    else
                        dist(t) = NaN;
                    end
                end
            end
        end
        
        function coords = coords(obj, chan, cell)
            %uses preferred submodel
            %returns a cell array of object coordinates vs. time
            %length of I may be less than ntime if model got lost
            %number of coordinates can vary if preferred submodel changes
            for t = 1:obj.ntime
                if obj.channel(chan).models(cell,t).isFit
                    coords{t} = obj.channel(chan).models(cell,t).getCoords;
                else
                    break
                end
            end
        end
        
        function MI = masterIndex(obj)
            %return index of master channel
            for chan = 1:obj.nchannels
                if strcmp(obj.master, obj.channel(chan).name)
                    MI = chan;
                end
            end
        end
        
        function setPreferredSubmodel(obj, chan, cell, submodel)
            %submodel is a 1 x ntime vector
            for t = 1:numel(submodel)
                obj.channel(chan).models(cell,t).setPreferredSubmodel(submodel(t));
            end
        end
        
    end
end