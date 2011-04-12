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
%
%      PARTICLEANALYZE('Property','Value',...) creates a new PARTICLEANALYZE or raises the
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

% Last Modified by GUIDE v2.5 11-Apr-2011 14:22:35

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

%need to see if the model has multiple submodels, and if so, pick the best
%one at each time point
for n = 1:numel(clist)
    if handles.data.model.channel(n).models(1,1).n_submodels > 1
        %need to determine which submodel to use
        disp('Determining number of dots ... ')
        crossover = str2double(get(handles.crossover, 'Value'));
        penalty = str2double(get(handles.penalty, 'Value'));
    end
end

disp('Initializing ... ')
%create reduceddata object to contain summarized data
handles.data.outputModel = reducedModel(handles.data.model);

%update channel menu dropdown
for chan = 1:handles.data.outputModel.nchannels
    clist{chan} = handles.data.outputModel.channels(chan).name;
end
set(handles.channel_menu, 'String', clist);

disp('Modeling intensities ... ')
%model intensities of master channel
handles.data.outputModel.modelIntensity(handles.data.outputModel.masterIndex);

MI = handles.data.outputModel.masterIndex;

for n = 1:handles.data.outputModel.ncells    
    %find potential disappearing dots
    modelI = handles.data.outputModel.data(n,MI).modelI;
    if (modelI(4) / (modelI(1) + modelI(4)) < 0.3)
        handles.data.outputModel.addFlag(n, 'curious');
    end
end

update_image(handles.axes,handles.data);

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
    int_1dot = handles.data.model(handles.data.selected).params_1dot(:,13);
    int_2dot = handles.data.model(handles.data.selected).params_2dot(:,13)*2;    
    figure(1)
    clf
    subplot(3,1,1)
    plot(int_1dot);
    title('1 dot intensity')
    subplot(3,1,2)
    plot(int_2dot);
    title('2 dot intensity')
    subplot(3,1,3)
    plot(handles.data.model(handles.data.selected).dotI);
    hold on
    plot(model_results_lin(handles.data.model(handles.data.selected).modelI),'r')
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

results = handles.data.model;
results = rmfield(results, {'startims', 'modelims_1dot', 'modelims_2dot', 'initparams'});

%reformat model intensities to match previous version
%reformat from midpoint, slope to startpoint, duration
%and from start intensity + baseline intensity to start intensity, end
%intensity
for n=1:numel(results)
    results(n).modelI(2) = results(n).modelI(2) + (0.5/results(n).modelI(3));
    results(n).modelI(3) = -1/results(n).modelI(3);
    results(n).modelI(1) = results(n).modelI(1) + results(n).modelI(4);
end

variable_name=inputdlg('Name for output data');
assignin('base', variable_name{1}, results);


% --- Executes on button press in selectcell.
function selectcell_Callback(hObject, eventdata, handles)
% hObject    handle to selectcell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[x,y]=ginput(1);
dist=zeros([1 size(handles.data.model,2)]);
for n=1:size(handles.data.model,2)
    dist(n) = (handles.data.model(n).initparams(11)-x).^2 + (handles.data.model(n).initparams(10)-y).^2;
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

% --- Executes during object creation, after setting all properties.
function cell_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cell_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



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


% --- Executes on button press in showmodel.
function showmodel_Callback(hObject, eventdata, handles)
% hObject    handle to showmodel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.data.selected > 0
    %show one and two dot fits and relative performance    
    figure(1)
    clf
    %plot relative performance of one vs two-dot fits
    plot(handles.data.model(handles.data.selected).fit_2dot./handles.data.model(handles.data.selected).fit_1dot,'b')
    hold on
    plot(handles.data.model(handles.data.selected).ndots,'r');
    title('1 dot error / 2 dot error (in blue); Ndots (in red)');
        
    figure(2)
    for t=1:60
        subplot(4,15,t)
        dispim = pair_1dot_images(handles.data.model, handles.data.selected, t);
        imshow(dispim, [], 'InitialMagnification', 'fit')
        title(strcat(sprintf('%d',t)));
    end
    
    figure(3)
    for t=1:60
        subplot(4,15,t)
        dispim = pair_2dot_images(handles.data.model, handles.data.selected, t);
        imshow(dispim, [], 'InitialMagnification', 'fit')
        title(strcat(sprintf('%d',t)));
    end
end

    
% --- Executes on button press in play_tracks.
function play_tracks_Callback(hObject, eventdata, handles)
% hObject    handle to play_tracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

for t=1:size(handles.data.ims,4)
    handles.data.time=t;
    update_image(handles.axes,handles.data);
    
    drawnow expose update
end


% --- Executes on button press in delete_tracks.
function delete_tracks_Callback(hObject, eventdata, handles)
% hObject    handle to delete_tracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.data.model(handles.data.selected)=[];
update_image(handles.axes,handles.data);

guidata(hObject, handles);


% --- Executes on button press in curious_flag.
function curious_flag_Callback(hObject, eventdata, handles)
% hObject    handle to curious_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of curious_flag

if get(hObject, 'Value') == get(hObject, 'Max')
    handles.data.model = addflag(handles.data.model, handles.data.selected, 'curious');
elseif get(hObject, 'Value') == get(hObject, 'Min')    
    handles.data.model = remflag(handles.data.model, handles.data.selected, 'curious');
end

guidata(hObject, handles);



% --- Executes on button press in disappearing_flag.
function disappearing_flag_Callback(hObject, eventdata, handles)
% hObject    handle to disappearing_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of disappearing_flag

if get(hObject, 'Value') == get(hObject, 'Max')
    handles.data.model = addflag(handles.data.model, handles.data.selected, 'disappearing');
elseif get(hObject, 'Value') == get(hObject, 'Min')    
    handles.data.model = remflag(handles.data.model, handles.data.selected, 'disappearing');
end

guidata(hObject, handles);


% --- Executes on button press in single_flag.
function single_flag_Callback(hObject, eventdata, handles)
% hObject    handle to single_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of single_flag
if get(hObject, 'Value') == get(hObject, 'Max')
    handles.data.model = addflag(handles.data.model, handles.data.selected, 'single');
elseif get(hObject, 'Value') == get(hObject, 'Min')    
    handles.data.model = remflag(handles.data.model, handles.data.selected, 'single');
end

guidata(hObject, handles);


% --- Executes on button press in splitting_flag.
function splitting_flag_Callback(hObject, eventdata, handles)
% hObject    handle to splitting_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of splitting_flag
if get(hObject, 'Value') == get(hObject, 'Max')
    handles.data.model = addflag(handles.data.model, handles.data.selected, 'splitting');
elseif get(hObject, 'Value') == get(hObject, 'Min')    
    handles.data.model = remflag(handles.data.model, handles.data.selected, 'splitting');
end

guidata(hObject, handles);

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

% --- Executes on button press in recall_dots.
function recall_dots_Callback(hObject, eventdata, handles)
% hObject    handle to recall_dots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('Determining number of dots ... ')
crossover = str2double(get(handles.crossover, 'String'));
penalty = str2double(get(handles.penalty, 'String'));
for n=1:size(handles.data.model,2)
    fitratio = handles.data.model(n).fit_2dot./handles.data.model(n).fit_1dot;
    handles.data.model(n).ndots = fit_ndots2(fitratio, crossover, penalty);   
end
update_image(handles.axes,handles.data);

disp('Modeling intensities ... ')
%calculate intensities
for n = 1:size(handles.data.model,2)
    int_1dot = handles.data.model(n).params_1dot(:,13);
    int_2dot = handles.data.model(n).params_2dot(:,13)*2;
    handles.data.model(n).dotI = int_1dot .* (handles.data.model(n).ndots' == 1) + int_2dot .* (handles.data.model(n).ndots' == 2);
    
    %model intensity disappearance
    handles.data.model(n).modelI = fit_disappearance_lin(handles.data.model(n).dotI');
    
    %find potential disappearing dots
    if (handles.data.model(n).modelI(4)/(+handles.data.model(n).modelI(1)+handles.data.model(n).modelI(4)) < 0.3)
        handles.data.model = addflag(handles.data.model, n, 'curious');
    end
end

disp('Done')
guidata(hObject, handles);


function update_image(target_axis,data_struct)
time=data_struct.time;
model = data_struct.outputModel;
cla(target_axis)

%max intensity project
image = squeeze(max(data_struct.ims(:,:,:,time,:),[],3));

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
%for now, just do master channel
MI = model.masterIndex;
for cell=1:model.ncells
    % get coords
    if (time > model.nTimePoints(cell))
        continue; %cell was not fit at this time point
    else
        coords = model.data(cell, MI).coords{time};
    end
    
    color = 'r';
    if model.isFlag(cell, 'curious')
        color = 'g';
    end
    if (cell == data_struct.selected)
        color = 'w';
    end
    if (size(coords,1)>1)
        for n=1:size(coords,2)
            plot(target_axis,coords(n,1),coords(n,2),[color,'s']);
        end
     else            
        plot(target_axis,coords(1),coords(2),[color,'o']);
    end
end

function dispim = pair_1dot_images(model, n, t)
dispim=max(model(n).startims(:,:,:,t),[],3);
dispim=dispim-min(dispim(:));
dispim=[dispim;zeros([1 size(dispim,1)])];
fitim=max(model(n).modelims_1dot(:,:,:,t),[],3);
fitim=fitim-min(fitim(:));
dispim=[dispim; fitim];

function dispim = pair_2dot_images(model, n, t)
dispim=max(model(n).startims(:,:,:,t),[],3);
dispim=dispim-min(dispim(:));
dispim=[dispim;zeros([1 size(dispim,1)])];
fitim=max(model(n).modelims_2dot(:,:,:,t),[],3);
fitim=fitim-min(fitim(:));
dispim=[dispim; fitim];

function model = addflag (model, n, flag)
model(n).flags = [model(n).flags, flag];

function model = remflag (model, n, flag)
model(n).flags(strcmp(model(n).flags, flag)) = [];

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
update_image(handles.axes,handles.data);


% --- Executes on selection change in channel_menu.
function channel_menu_Callback(hObject, eventdata, handles)
% hObject    handle to channel_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channel_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_menu


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


% --- Executes on selection change in data_menu.
function data_menu_Callback(hObject, eventdata, handles)
% hObject    handle to data_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns data_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from data_menu


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
