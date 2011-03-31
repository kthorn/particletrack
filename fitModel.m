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
        
    end
    
    
end