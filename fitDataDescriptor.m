classdef fitDataDescriptor < handle
    %   fitDataDescriptor - Input data for fitters in particletrack2
    %   Detailed explanation goes here
    
    properties
        directory;
        coordinates;
        master; %name of master channel
        boxsize; %size of region around each coordinate to cut out for analysis
    end
    properties (SetAccess = private, GetAccess = private)
        channel;
        % channel is an array with subproperties
        % name
        % model
    end
    
    methods
        function newobj = fitDataDescriptor (directory, channels)
            %constructor
            %directory is a string
            %channels is a cell array of strings
            newobj.directory = directory;
            for n=1:numel(channels)
                newobj.addChannel(channels{n});
            end
        end
        
        function addChannel (obj, cname)
            nchannels = numel(obj.channel);
            for n=1:nchannels
                if strcmp (cname, obj.channel(n).name)
                    error ('pt:cname','Cannot have duplicate channel names');
                end
            end
            obj.channel(nchannels+1).name = cname;
            obj.channel(nchannels+1).model = 'None';
            if nchannels == 0
                obj.master = cname;
                %first channel is master, by default
            end
        end
        
        function clist = getChannelNames (obj)
            for n=1:numel(obj.channel);
                clist{n} = obj.channel(n).name;
            end
        end
        
        function model = getModelName (obj, cname)
            found = false;
            for n=1:numel(obj.channel);
                if strcmp (cname, obj.channel(n).name)
                    model = obj.channel(n).model;
                    found = true;
                end
            end
            if ~found
                error ('pt:cname',['Could not find channel ', cname]);
            end
        end
        
        function setModelName (obj, cname, mname)
            found = false;
            for n=1:numel(obj.channel);
                if strcmp (cname, obj.channel(n).name)
                    obj.channel(n).model = mname;
                    found = true;
                end
            end
            if ~found
                error ('pt:cname',['Could not find channel ', cname]);
            end
        end
        
        function set.master (obj, cname)
            %set channel cname to master
            for n=1:numel(obj.channel);
                if strcmp (cname, obj.channel(n).name)
                    obj.master = cname;
                    found = true;
                end
            end
            if ~found
                error ('pt:cname',['Could not find channel ', cname]);
            end
        end
        function state = isMaster (obj, cname)
            %return true if cname channel is master
            if strcmp (cname, obj.master)
                state = true;
            else
                state = false;
            end
            
        end
        
        function ncells = getNumCells (obj)
            ncells = size(obj.coordinates,1);
        end
        
    end
end
