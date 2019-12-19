function varargout = ListenerIDv2(varargin)
% LISTENERIDV2 MATLAB code for ListenerIDv2.fig
%      LISTENERIDV2, by itself, creates a new LISTENERIDV2 or raises the existing
%      singleton*.
%
%      H = LISTENERIDV2 returns the handle to a new LISTENERIDV2 or the handle to
%      the existing singleton*.
%
%      LISTENERIDV2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LISTENERIDV2.M with the given input arguments.
%
%      LISTENERIDV2('Property','Value',...) creates a new LISTENERIDV2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ListenerIDv2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ListenerIDv2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ListenerIDv2

% Last Modified by GUIDE v2.5 01-Nov-2018 12:45:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ListenerIDv2_OpeningFcn, ...
                   'gui_OutputFcn',  @ListenerIDv2_OutputFcn, ...
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


% --- Executes just before ListenerIDv2 is made visible.
function ListenerIDv2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ListenerIDv2 (see VARARGIN)

% process any arguments to re-set the TestSpecs GUI
if length(varargin{1})>1
    for index=1:2:length(varargin{1})
        if length(varargin{1}) < index+1
            break;
        elseif strcmpi('Listener', varargin{1}(index))
            set(handles.ListenerInitials,'String',char(varargin{1}(index+1)));
        else
            error('Illegal option: %s -- Legal options are:Listener\n', ...
                char(varargin{1}(index)));
        end
    end
end

% Choose default command line output for ListenerIDv2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Move the GUI to the center of the screen.
movegui(handles.ID, 'center')

% UIWAIT makes ListenerIDv2 wait for user response (see UIRESUME)
uiwait(handles.ID);


% --- Outputs from this function are returned to the command line.
function varargout = ListenerIDv2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;
if isempty(handles)
    varargout{1}='quit';
else
    varargout{1} = handles.listenerInitials;
    varargout{2} = handles.listenerDOB;    
    if get(handles.femaleButton,'Value')
        varargout{3} = 'F';
    else
        varargout{3} = 'M';
    end
end
%------------------------------
% The figure can be deleted now
delete(handles.ID);

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.listenerInitials=get(handles.ListenerInitials,'String');
handles.listenerDOB = get(handles.DateOfBirth,'String');

guidata(hObject, handles); % Save the updated structure
uiresume(handles.ID);


function ListenerInitials_Callback(hObject, eventdata, handles)
% hObject    handle to ListenerInitials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ListenerInitials as text
%        str2double(get(hObject,'String')) returns contents of ListenerInitials as a double


% --- Executes during object creation, after setting all properties.
function ListenerInitials_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ListenerInitials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DateOfBirth_Callback(hObject, eventdata, handles)
% hObject    handle to DateOfBirth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DateOfBirth as text
%        str2double(get(hObject,'String')) returns contents of DateOfBirth as a double


% --- Executes during object creation, after setting all properties.
function DateOfBirth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DateOfBirth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
