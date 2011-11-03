function varargout = particleanalyze(varargin)
% PARTICLEANALYZE M-file for particleanalyze.fig
%      PARTICLEANALYZE, by itself, creates a new PARTICLEANALYZE or raises the existing
%      singleton*.
%
%      H = PARTICLEANALYZE returns the handle to a new PARTICLEANALYZE or the handle to
%      the existing singleton*.
%
%      PARTICLEANALYZE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PARTICLEANALYZE.M with the given input arguments.
%      PARTICLEANALYZE('Property','Value',...) creates a new PARTICLEANALYZE or raises the
%
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before particleanalyze_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to particleanalyze_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help particleanalyze

% Last Modified by GUIDE v2.5 25-Apr-2011 16:37:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @particleanalyze_OpeningFcn, ...
    'gui_OutputFcn',  @particleanalyze_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before particleanalyze is made visible.
function particleanalyze_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to particleanalyze (see VARARGIN)

% Choose default command line output for particleanalyze
handles.output = hObject;

handles.data.model=evalin('base','model');

clist = handles.data.model.getChannelNames;
disp('Loading Images ... ')
handles.data.ims = MMparse(handles.data.model.directory,[],clist);
handles.data.time=1;
handles.data.selected=-1;

%call ndots, set intensities, model
handles = set_ndots_intensities(handles);

disp('Initializing ... ')
%update channel menu dropdown
for chan = 1:handles.data.outputModel.nchannels
    clist{chan} = handles.data.outputModel.channels(chan).name;
    handles.data.outputModel.setReport(handles.data.outputModel.channels(chan).name, 'Intensities');
end
set(handles.channel_menu, 'String', clist);

update_image(handles);

set(handles.cell_slider,'Max',handles.data.outputModel.ncells);
set(handles.cell_slider,'Min',1);
set(handles.cell_slider,'Value',1);
set(handles.cell_slider,'SliderStep',[1/handles.data.outputModel.ncells 10/handles.data.outputModel.ncells]);
disp('done')

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes particleanalyze wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = particleanalyze_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in plot_intensity.
function plot_intensity_Callback(hObject, eventdata, handles)
% hObject    handle to plot_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.data.selected > 0
    cell = handles.data.selected;
    MI = handles.data.model.masterIndex;
    %get final assigned intensity
    I = handles.data.outputModel.data(cell, MI).intensity;
    timepts = 1:numel(I);
    modelI = model_results_lin(handles.data.outputModel.data(cell,MI).modelI, timepts);
    parentcell = handles.data.outputModel.data(cell,MI).sourceCell;
    figure(1)
    clf
    
    if handles.data.model.channel(MI).models(parentcell, 1).n_submodels > 1
        %get individual submodel intensities
        subplot(3,1,1)
        plot(handles.data.model.intensity(MI, parentcell, 1));
        title('1 dot intensity')
        subplot(3,1,2)
        plot(handles.data.model.intensity(MI, parentcell, 2));
        title('2 dot intensity')
        subplot(3,1,3)
    end
    plot(I,'b');
    hold on
    plot(modelI,'r');
    title('Intensity of best fitting model')
end
guidata(hObject, handles);

% --- Executes on mouse press over axes background.
function axes_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in export.
function export_Callback(hObject, eventdata, handles)
% hObject    handle to export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%loop over channels, generating excel spreadsheet with details
%sheets as follows:
%if intensities are output, two sheets, one with raw intensities, one with
%modeled.  Modeled also has flag info.
%if disstances are output, add a sheet for positions
outputfile = fullfile(handles.data.model.directory, 'analysis.xls');
%remove old version, if present
delete(outputfile);
warning('off', 'MATLAB:xlswrite:AddSheet');


for cidx=1:handles.data.outputModel.nchannels
    cname = handles.data.outputModel.channels(cidx).name;
    report = handles.data.outputModel.channels(cidx).report;
    if strcmp(report, 'Intensities') || strcmp(report, 'Both')
        %loop over cells
        subidx = 1;
        clear Iall Idiss Imdiss fldiss Ddiss Imall
        for clidx = 1:handles.data.outputModel.ncells
            Iall(clidx,:) = handles.data.outputModel.data(clidx, cidx).intensity;
            modelI = handles.data.outputModel.data(clidx,cidx).modelI;
            %reformat model intensities to match previous version
            %reformat from midpoint, slope to startpoint, duration
            %and from start intensity + baseline intensity to start intensity, end
            %intensity
            if numel(modelI)>0
                modelI(2) = modelI(2) + (0.5/modelI(3));
                modelI(3) = -1/modelI(3);
                modelI(1) = modelI(1) + modelI(4);
                Imall(clidx,:) = modelI;
            end
            flaglist = handles.data.outputModel.cells(clidx).flags;
            if ~isempty(flaglist)
                flags{clidx} = strcat(flaglist{:});
                if any(strcmp('disappearing', flaglist))
                    Idiss(subidx,:) = handles.data.outputModel.data(clidx, cidx).intensity;
                    if numel(modelI)>0
                        Imdiss(subidx,:) = modelI;
                    end
                    fldiss{subidx} = strcat(flaglist{:});
                    subidx = subidx + 1;
                end
            end
        end
        sheetname =[cname,' intensities'];
        xlswrite(outputfile, Iall, sheetname);
        
        if exist('Imall','var')
            sheetname =[cname,' model'];
            xlswrite(outputfile, flags', sheetname, 'A1');
            xlswrite(outputfile, Imall, sheetname, 'B1');
        end
        
        if exist('fldiss','var')
            sheetname =[cname,' intensities flagged'];
            xlswrite(outputfile, fldiss', sheetname, 'A1');
            xlswrite(outputfile, Idiss, sheetname, 'B1');
            if exist('Imdiss','var')
                sheetname =[cname,' model flagged'];
                xlswrite(outputfile, fldiss', sheetname, 'A1');
                xlswrite(outputfile, Imdiss, sheetname, 'B1');
            end
        end
    end
    clear fldiss
    if strcmp(report, 'Distances') || strcmp(report, 'Both')
        %loop over cells
        subidx = 1;
        for clidx = 1:handles.data.outputModel.ncells
            Dall(clidx,:) = handles.data.outputModel.data(clidx, cidx).distance;
            flaglist = handles.data.outputModel.cells(clidx).flags;
            if ~isempty(flaglist)
                flags{clidx} = strcat(flaglist{:});
                if any(strcmp('disappearing', flaglist))
                    Ddiss(subidx,:) = handles.data.outputModel.data(clidx, cidx).distance;
                    fldiss{subidx} = strcat(flaglist{:});
                    subidx = subidx + 1;
                end
            end
        end
        sheetname =[cname,' distances'];
        xlswrite(outputfile, Dall, sheetname);
        
        if exist('fldiss', 'var')
            sheetname =[cname,' distances flagged'];
            xlswrite(outputfile, fldiss', sheetname, 'A1');
            xlswrite(outputfile, Ddiss, sheetname, 'B1');
        end
    end
    
end
warning('on', 'MATLAB:xlswrite:AddSheet');


% --- Executes on button press in selectcell.
function selectcell_Callback(hObject, eventdata, handles)
% hObject    handle to selectcell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[x,y]=ginput(1);
nCells = handles.data.outputModel.ncells;
dist=zeros([1 nCells]);
MI = handles.data.outputModel.masterIndex;
for n=1:handles.data.outputModel.ncells
    coords = handles.data.outputModel.data(n, MI).coords{handles.data.time};
    coords = nanmean(coords,1);
    dist(n) = sum((coords-[x, y]).^2);
end
[junk, selected_point]=min(dist);
handles = update_selection(handles, selected_point);

guidata(hObject, handles);


% --- Executes on slider movement.
function cell_slider_Callback(hObject, eventdata, handles)
% hObject    handle to cell_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

n_cell = round(get(hObject,'Value'));
set(handles.cell_slider, 'Value', n_cell);
set(handles.cell_text,'String',sprintf('%u',n_cell));
handles = update_selection(handles, n_cell);

guidata(hObject, handles);


function cell_text_Callback(hObject, eventdata, handles)
% hObject    handle to cell_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cell_text as text
%        str2double(get(hObject,'String')) returns contents of cell_text as a double

n_cell = str2double(get(handles.cell_text,'String'));
set(handles.cell_slider, 'Value', n_cell);
handles = update_selection(handles, n_cell);

guidata(hObject, handles);


% --- Executes on button press in showmodel.
function showmodel_Callback(hObject, eventdata, handles)
% hObject    handle to showmodel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.data.selected > 0
    cell = handles.data.selected;
    MI = handles.data.outputModel.masterIndex;
    parentcell = handles.data.outputModel.data(cell, MI).sourceCell;
    cname_list = get(handles.channel_menu, 'String');
    cname = cname_list{get(handles.channel_menu, 'Value')};
    chan = handles.data.model.getChannelIndex(cname);
    
    if handles.data.model.channel(chan).models(parentcell, 1).n_submodels > 1
        %show one and two dot fits and relative performance
        figure(1)
        clf
        fitratio = [];
        ndots =[];
        for t = 1:handles.data.model.ntime
            if handles.data.model.channel(chan).models(parentcell, t).isFit
                sse = handles.data.model.channel(chan).models(parentcell, t).sse;
                fitratio(t) = sse(2)/sse(1);
                ndots(t) = handles.data.model.channel(chan).models(parentcell, t).preferred_submodel;
            else
                break
            end
        end
        plot(fitratio,'b')
        hold on
        plot(ndots,'r');
        title('1 dot error / 2 dot error (in blue); Ndots (in red)');
    end
    figure(2)
    clf
    boxsize = handles.data.model.channel(chan).models(parentcell, 1).boxsize;
    %generate grid to reassemble images in
    nbox_x=round(sqrt(handles.data.model.ntime)/2);
    nbox_y=idivide(uint16(handles.data.model.ntime),nbox_x,'ceil');
    nbox_y=double(nbox_y);
    for t=1:handles.data.model.ntime
        if ~handles.data.model.channel(chan).models(parentcell, t).isFit
            break;
        end
        subplot(nbox_x,nbox_y,t)
        %cutout original image
        coords = handles.data.model.channel(chan).models(parentcell, t).initcoords;
        subimage = squeeze(handles.data.ims(coords(2)-boxsize:coords(2)+boxsize,coords(1)-boxsize:coords(1)+boxsize,:,t,chan));
        dispim=max(subimage,[],3);
        dispim=dispim-min(dispim(:));
        dispim=[dispim;zeros([1 size(dispim,1)])];
        modelim = handles.data.model.channel(chan).models(parentcell, t).showModel(1,handles.data.model.sigmas);
        fitim=max(modelim,[],3);
        fitim=fitim-min(fitim(:));
        dispim=[dispim; fitim];
        imshow(dispim, [], 'InitialMagnification', 'fit')
        title(strcat(sprintf('%d',t)));
    end
    if handles.data.model.channel(chan).models(cell, 1).n_submodels > 1
        figure(3)
        clf
        for t=1:handles.data.model.ntime
            if ~handles.data.model.channel(chan).models(parentcell, t).isFit
                break;
            end
            subplot(nbox_x,nbox_y,t)
            %cutout original image
            coords = handles.data.model.channel(chan).models(parentcell, t).initcoords;
            subimage = squeeze(handles.data.ims(coords(2)-boxsize:coords(2)+boxsize,coords(1)-boxsize:coords(1)+boxsize,:,t,chan));
            dispim=max(subimage,[],3);
            dispim=dispim-min(dispim(:));
            dispim=[dispim;zeros([1 size(dispim,1)])];
            modelim = handles.data.model.channel(chan).models(parentcell, t).showModel(2,handles.data.model.sigmas);
            fitim=max(modelim,[],3);
            fitim=fitim-min(fitim(:));
            dispim=[dispim; fitim];
            imshow(dispim, [], 'InitialMagnification', 'fit')
            title(strcat(sprintf('%d',t)));
        end
    end
end

    
% --- Executes on button press in play_tracks.
function play_tracks_Callback(hObject, eventdata, handles)
% hObject    handle to play_tracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

for t=1:size(handles.data.ims,4)
    handles.data.time=t;
    update_image(handles);    
    drawnow expose update
end
handles.data.time = 1;
update_image(handles);
guidata(hObject, handles);


% --- Executes on button press in curious_flag.
function curious_flag_Callback(hObject, eventdata, handles)
% hObject    handle to curious_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of curious_flag

if get(hObject, 'Value') == get(hObject, 'Max')
    handles.data.outputModel.addFlag(handles.data.selected, 'curious');
elseif get(hObject, 'Value') == get(hObject, 'Min')    
    handles.data.outputModel.remFlag(handles.data.selected, 'curious');
end

guidata(hObject, handles);


% --- Executes on button press in disappearing_flag.
function disappearing_flag_Callback(hObject, eventdata, handles)
% hObject    handle to disappearing_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of disappearing_flag

if get(hObject, 'Value') == get(hObject, 'Max')
    handles.data.outputModel.addFlag(handles.data.selected, 'disappearing');
elseif get(hObject, 'Value') == get(hObject, 'Min')    
    handles.data.outputModel.remFlag(handles.data.selected, 'disappearing');
end

guidata(hObject, handles);


% --- Executes on button press in single_flag.
function single_flag_Callback(hObject, eventdata, handles)
% hObject    handle to single_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of single_flag
if get(hObject, 'Value') == get(hObject, 'Max')
    handles.data.outputModel.addFlag(handles.data.selected, 'single');
elseif get(hObject, 'Value') == get(hObject, 'Min')    
    handles.data.outputModel.remFlag(handles.data.selected, 'single');
end

guidata(hObject, handles);


% --- Executes on button press in splitting_flag.
function splitting_flag_Callback(hObject, eventdata, handles)
% hObject    handle to splitting_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of splitting_flag
if get(hObject, 'Value') == get(hObject, 'Max')
    handles.data.outputModel.addFlag(handles.data.selected, 'splitting');
elseif get(hObject, 'Value') == get(hObject, 'Min')    
    handles.data.outputModel.remFlag(handles.data.selected, 'splitting');
end

guidata(hObject, handles);

% --- Executes on button press in recall_dots.
function recall_dots_Callback(hObject, eventdata, handles)
% hObject    handle to recall_dots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = set_ndots_intensities(handles);
update_image(handles);

disp('Done')
guidata(hObject, handles);

% --- Executes on selection change in data_menu.
function data_menu_Callback(hObject, eventdata, handles)
% hObject    handle to data_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get selected export type
contents = cellstr(get(hObject,'String'));
export = contents{get(hObject,'Value')};

contents = cellstr(get(handles.channel_menu,'String'));
chan = contents{get(handles.channel_menu,'Value')};
handles.data.outputModel.setReport(chan, export);
guidata(hObject, handles);

% --- Executes on selection change in channel_menu.
function channel_menu_Callback(hObject, eventdata, handles)
% hObject    handle to channel_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contents = cellstr(get(hObject,'String'));
chan = contents{get(hObject,'Value')};
report = handles.data.outputModel.getReport(chan);

contents = cellstr(get(handles.data_menu,'String'));
for n=1:numel(contents)
    if strcmp(contents{n}, report)
        set(handles.data_menu,'Value',n);
    end
end

%%%% end of used callbacks %%%%

%%%% utility functions %%%%

function update_image(handles)
time=handles.data.time;
model = handles.data.outputModel;
target_axis = handles.axes;
cla(target_axis)

%max intensity project
image = squeeze(max(handles.data.ims(:,:,:,time,:),[],3));

satfxn = 0.0002;
if ndims(image) == 3
    %generate RGB image
    RGB = zeros([size(image,1), size(image,2), 3]);
    [minI, maxI] = satvals(image(:,:,1), satfxn);
    tempim = double(image(:,:,1) - minI);
    tempim = tempim./maxI;
    tempim = max(tempim,0);
    tempim = min(tempim,1);
    RGB(:,:,2)=tempim;
    
    [minI, maxI] = satvals(image(:,:,2), satfxn);
    tempim = double(image(:,:,2) - minI);
    tempim = tempim./maxI;
    tempim = max(tempim,0);
    tempim = min(tempim,1);
    RGB(:,:,1)=tempim;
else    
    [minI, maxI] = satvals(image, satfxn);
    tempim = double(image - minI);
    tempim = tempim./maxI;
    tempim = max(tempim,0);
    tempim = min(tempim,1);
    RGB = tempim;
end

imshow(RGB,'Parent',target_axis);
hold on

%now plot coordinates

cname_list = get(handles.channel_menu, 'String');
cname = cname_list{get(handles.channel_menu, 'Value')};
chan = handles.data.model.getChannelIndex(cname);

for cell=1:model.ncells
    % get coords
    if (time > model.nTimePoints(cell))
        continue; %cell was not fit at this time point
    else
        coords = model.data(cell, chan).coords{time};
    end
    
    color = 'r';
    if model.isFlag(cell, 'curious')
        color = 'g';
    end
    if (cell == handles.data.selected)
        color = 'w';
    end
    if (size(coords,1)>1)
        for n=1:size(coords,2)
            plot(target_axis,coords(n,1),coords(n,2),[color,'s']);
        end
    else
        plot(target_axis,coords(1),coords(2),[color,'o']);
    end
    %display cell number
    offsety = -8;
    offsetx = 6;
    text(coords(1,1) + offsetx, coords(1,2)+offsety, sprintf('%d',cell),'Color',[1 1 1]);
end

function handles = update_selection(handles, selected_cell)

handles.data.selected=selected_cell;
set(handles.cell_text, 'String', sprintf('%u', selected_cell));
set(handles.cell_slider, 'Value', selected_cell);
if handles.data.outputModel.isFlag(selected_cell, 'curious')
    set(handles.curious_flag, 'Value', get(handles.curious_flag, 'Max'));
else    
    set(handles.curious_flag, 'Value', get(handles.curious_flag, 'Min'));
end
if handles.data.outputModel.isFlag(selected_cell, 'single')
    set(handles.single_flag, 'Value', get(handles.single_flag, 'Max'));
else    
    set(handles.single_flag, 'Value', get(handles.single_flag, 'Min'));
end
if handles.data.outputModel.isFlag(selected_cell, 'splitting')
    set(handles.splitting_flag, 'Value', get(handles.splitting_flag, 'Max'));
else
    set(handles.splitting_flag, 'Value', get(handles.splitting_flag, 'Min'));
end
if handles.data.outputModel.isFlag(selected_cell, 'disappearing')
    set(handles.disappearing_flag, 'Value', get(handles.disappearing_flag, 'Max'));
else
    set(handles.disappearing_flag, 'Value', get(handles.disappearing_flag, 'Min'));
end
update_image(handles);

function handles = set_ndots_intensities(handles)
%need to see if the model has multiple submodels, and if so, pick the best
%one at each time point
model = handles.data.model;
crossover = str2double(get(handles.crossover, 'String'));
penalty = str2double(get(handles.penalty, 'String'));

clist = model.getChannelNames;
for chan = 1:numel(clist)
    if model.channel(chan).models(1,1).n_submodels > 1
        %need to determine which submodel to use
        disp('Determining number of dots ... ')
        for cell = 1:model.ncells
            fitratio = [];
            for t = 1:model.ntime
                if model.channel(chan).models(cell, t).isFit
                    sse = model.channel(chan).models(cell, t).sse;
                    fitratio(t) = sse(2)/sse(1);
                else
                    break
                end
            end
            ndots = fit_ndots2(fitratio, crossover, penalty);
            model.setPreferredSubmodel(chan, cell, ndots);
        end
    end
end

handles.data.outputModel = reducedModel(handles.data.model);

disp('Modeling intensities ... ')
%model intensities of master channel
handles.data.outputModel.modelIntensity(handles.data.outputModel.masterIndex);

MI = handles.data.outputModel.masterIndex;

for clidx = 1:handles.data.outputModel.ncells
    %find potential disappearing dots    
    I = handles.data.outputModel.data(clidx, MI).intensity;
    timepts = 1:numel(I);
    modelI = model_results_lin(handles.data.outputModel.data(clidx,MI).modelI, timepts);
    if (modelI(end) / (modelI(end) + modelI(1)) < 0.3)
        handles.data.outputModel.addFlag(clidx, 'curious');
    end
end

%%%% Unused Callbacks %%%%
% --- Executes during object creation, after setting all properties.
function channel_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function data_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to data_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function penalty_Callback(hObject, eventdata, handles)
% hObject    handle to penalty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of penalty as text
%        str2double(get(hObject,'String')) returns contents of penalty as a double


% --- Executes during object creation, after setting all properties.
function penalty_CreateFcn(hObject, eventdata, handles)
% hObject    handle to penalty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function crossover_Callback(hObject, eventdata, handles)
% hObject    handle to crossover (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of crossover as text
%        str2double(get(hObject,'String')) returns contents of crossover as a double


% --- Executes during object creation, after setting all properties.
function crossover_CreateFcn(hObject, eventdata, handles)
% hObject    handle to crossover (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function cell_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cell_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function cell_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cell_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
