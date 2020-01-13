%-----------------------------------------------------------------
%
%   audiometer.m : implement a more or less standard manual audiometer
%       Levels are controlled by multiple csv files containing appropriate
%       calibration information.
%
%   Initial information is read from the hard-coded file named 'AudiometerConditions.csv'
%       A typical file contains 12 columns, with the header row containing
%       the name of the parameter and the first row holding the relevant
%       values. The order of the parameters is irrelevant as the names are
%       taken from the header row. Here is a list along with possible
%       values:
%             minLevel	0
%             maxLevel	50
%               min & maxLevels refer to the minimum & maximum levels in dB
%               HL displayed on the GUI
%             HeadphoneTypeFile	DD450.csv
%               A csv file containing the properties of the frequency
%               response appropriate for a general class or model of transducer
%             TweaksFile	DD450_001.csv
%               The tweaks file has 2 columns, additional adjustments to
%               make for a particular pair of headphones on each side (see
%               below)
%             VolumeSettingsFile	VolumeSettings.txt
%             correctionType	SPL
%               There are 3 main types of correction files:
%               SPL, SPL-FREx or FPL (see below for further details)
%               The FPL correction requires a .mat file name (see below)
%               The other two corrections require an appropriate
%               HeadphoneTypeFile and TweaksFile
%             usePlayrec	0
%               A binary variable to use (or not) the playrec functions
%             numPulses	3
%               an integer specifying the number of pulses desired
%             nPulseDuration 300
%               the duration of each pulse in the set, even if only 1
%             nPulsePause 200
%               the ISI between pulses
%             longDuration	8
%               the duration of the tone played when the 'Long Play' button
%               is pressed
%             FPLmat2	Flat115_L_computedFPLestimates_Ch1.mat
%             FPLmat	KZ_L_computedFPLestimates_Ch1.mat
%
%       For correctionType=SPL
%       The HeadphoneTypeFile contains the attenuations necessary to obtain
%           a measured dB SPL that is equal to 0 dB HL at each frequency
%           when attenuated by the maximum dB HL allowed,
%           given the Volume Settings contained in the VolumeSettingsFile
%           (only relevant for sound cards under typical Windows/iOS
%           control -- not relevant for RME fireface which is handled
%           differently using playrec). For example:
%               freq	HD-25
%                250	0
%                500	-11.2
%               1000	-18.1
%               2000	-18.8
%               4000	-15.6
%               8000	-13.3
%       The tweaks file has 2 columns, additional adjustments to make for
%       a particular pair of headphones on each side:
%           freq	HD-25 left	HD-25 right
%           250          0          -0.5
%           500          0             0
%               ...
%           4000         0             0.7
%           8000         0             -0.3
%
%       Perhaps inconveniently, this means that the absolute thresholds in
%       dB SPL are conflated with the headphone response
%       Probably better if these were separate - TBD!
%
%       How it's done:
%       Headphone corrections and tweaks (for L & R separately on the
%       latter) are read in & interpolated to specified audiometric
%       frequencies.
%
%       For correctionType = SPL-FREx (SPL for Frequency Response in .csv Excel file)
%           Here the headphone transfer function is specified in an excel
%           file in the form of the output sound levels as a function of
%           frequency for the maximum voltage level presented to the
%           transducers. This is more or less identical to the FPL method,
%           only with the format of the information different.
%
%%-------------------------------------------------------------------------
% Vs 4.6 December 2019
%   Document better
%   Add a lot more defaults so less needs to be specified in
%   AudiometerConditions file. Delete use of variable 'dur' as redundant.
%   Check more carefully for the required values.
%   Output a parameter values file
%
% Vs 4.5 April 2019
%   implement version in which a headphone transfer function is specified
%   in an excel file. Thi is in the form of the output sound levels as a
%   function of frequency for the maximum voltage level presented to the
%   transducers. This is more or less identical to the FPL method, only
%   with the format of the information different.
%   correctionType = SPL-FREx (SPL for Frequency Response in Excel file)
%
% Vs 4.0 April 2019
%   put extra information on GUI
%   allow arbitrary test frequency to be specified (may only work with FPL)
%
% Vs 3.5 April 2019
%   catch errors when levels can't be reached
%
% Vs 3.0 April 2019
%   full blown FPL implementation
%   put more parameters into configuration file
%   fix long play when there are multiple pulses
%
% Vs 2.5 April 2019 - tweaks
%
% Vs 2.0 April 2019
%   implement higher frequency testing
%   text output of every button pressed, with initial specification of
%       listener code
%   Improve documentation!
%   Incomplete implementation of usePlayrec
%       need to rewrite playback for ease of use

% Vs 1.6 9th January 2014 Steve Nevard
%   allow for separate adjustment of left and right channels in tweaks file.

% Vs 1.5 - January 2014
%   correct problem with overload
%   rename files for clearer rationale about how values are used
%   work in dB throughout and only convert to linear factors at final
%       stage, in playback.m

% Vs 1.0 - November 2013
%   Started from audiometerW7 dated March 2013
%   extended volume controls to work with XP, W7 and babyface
%
%   stuart@phon.ucl.ac.uk


function varargout = audiometer(varargin)
% AUDIOMETER Application M-file for audiometer.fig
%    FIG = AUDIOMETER launch audiometer GUI.
%    AUDIOMETER('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.5 16-Apr-2019 07:07:48

if nargin == 0  % LAUNCH GUI
    
    fig = openfig(mfilename,'reuse');
    movegui(fig, 'center');
    
    % Use system color scheme for figure:
    set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
    
    
    % Generate a structure of handles to pass to callbacks, and store it.
    handles = guihandles(fig);
    guidata(fig, handles);
    
    if nargout > 0
        varargout{1} = fig;
    end
    
    OddWarning=warndlg({...
        'Known bug: if you change the tone frequency';...
        'before the tone stops playing, the value will';...
        'change at the bottom of the GUI, but the old';...
        'tone frequency will be played. Carefully note';...
        'the frequency displayed in the yellow box as';...
        'the tone is being played'},'Obs!', 'modal');
    
    %% important variables to set
    handles.audiometricFreqs = [250 500 1000 2000 4000 8000 11000 16000 20000];
    OutputDir = 'results';
    if ~exist(OutputDir, 'dir')
        status = mkdir(OutputDir);
        if status==0
            error('Cannot create new output directory for results: %s.\n', OutputDir);
        end
    end
    
    [handles.I, handles.DOB, handles.sex] = ListenerIDv2('x');
    handles.version = '4.6';
    
    %% get controlling parameters
    AudiometerConditionsFile = 'AudiometerConditions.csv';
    if exist(AudiometerConditionsFile,'file')
        [~, strText, allText] = xlsread(AudiometerConditionsFile);
    else
        close(fig)
        close(OddWarning)
        error('Audiometer Conditions File does not exist: %s\n', AudiometerConditionsFile);
    end
    for i=1:size(allText,2)
        if ~isempty(strText{2,i})
            eval([allText{1,i} '= ''' allText{2,i} ''';'])
        else
            eval([allText{1,i} '=' num2str(allText{2,i}) ';'])
        end
    end
    
    soundOptions={'PC' 'RME'};
    soundOption=soundOptions{usePlayrec+1};
    if strcmp(correctionType(1:3),'SPL')
        responseFile=strrep(HeadphoneTypeFile,'.csv','');
    else
        responseFile=strrep(FPLmat,'.mat','');
    end
    
    handles.ListenerName = [handles.I, '_', handles.DOB,'_', handles.sex];
    %% get start time and date
    StartTime=fix(clock);
    handles.StartTimeString=sprintf('%02d:%02d:%02d',...
        StartTime(4),StartTime(5),StartTime(6));
    handles.StartDate=date;
    FileNamingStartTime = sprintf('%02d-%02d-%02d',StartTime(4),StartTime(5),StartTime(6));
    FileListenerName=[handles.ListenerName '_' responseFile  '_' soundOption  '_' handles.StartDate '_' FileNamingStartTime];
    handles.OutFile = fullfile(OutputDir, [FileListenerName '.csv']);
    handles.summaryOutFile = fullfile(OutputDir, [FileListenerName '_sum.csv']);
    handles.parametersOutFile = fullfile(OutputDir, [FileListenerName '_parms.csv']);
    %% write some headings and preliminary information to the output file
    fout = fopen(handles.OutFile, 'wt');
    fprintf(fout, 'listener,date,time,trial,ear,frq,dBHL,atten,rTime\n');
    fclose(fout);
    fout = fopen(handles.summaryOutFile, 'wt');
    fprintf(fout, 'listener,date,time,trial,ear,frq,dBHL,atten,rTime\n');
    fclose(fout);
    
    %% set values on to GUI
    set(handles.textFPLmatFile, 'BackgroundColor', .93*[ 1 1 1]);
    % SPL-FREx
    
    % allow pulsed tones as in GP audiometer
    if ~exist('numPulses', 'var')
        numPulses=3;
    end
    handles.numPulses=numPulses; % if > 1, call different script to generate sound
    
    if ~exist('nPulseDuration', 'var')
        if numPulses>1
            nPulseDuration=300;
        else
            nPulseDuration=1000;
        end
    end
    handles.nPulseDuration=nPulseDuration;
    
    if ~exist('nPulsePause', 'var')
        nPulsePause=200;
    end
    handles.nPulsePause=nPulsePause;
    
    if ~exist('longDuration', 'var')
        longDuration=8; % 8 seconds
    end
    handles.longDuration=longDuration;
    
    if ~exist('correctionType', 'var')
        error('correctionType must be specified in AudiometerConditions file')
    end
    handles.correctionType=correctionType; % SPL or FPL
    handles.minLevel=minLevel;
    handles.maxLevel=maxLevel;
    if ~exist('VolumeSettingsFile', 'var')
        VolumeSettingsFile="VolumeSettings.txt";
    end
    
    set(handles.textParameters, 'String', sprintf('%s %s: %d pulse(s)',...
        correctionType, soundOption, numPulses));
    set(handles.textFPLmatFile, 'String', responseFile);
    
    handles.usePlayrec=usePlayrec;
    
    if strcmpi(correctionType,'FPL')
        handles.FPLcorrection=load(FPLmat);
        handles.maxdBHL=0; % just a dummy value to prevent errors
        set(handles.textFPLmatFile, 'String', strrep(FPLmat,'.mat',''));
        handles.FPLmatFile = FPLmat;
    elseif strcmpi(correctionType,'SPL-FREx')
        set(handles.textFPLmatFile, 'String', strrep(HeadphoneTypeFile,'.csv',''));
        handles.SPLFRExFile = HeadphoneTypeFile;
        handles.maxdBHL=0; % just a dummy value to prevent errors
        % get in the dB SPL generated at the maximum output level
        handles.maxSPLs = csvread(HeadphoneTypeFile,1,0);
    else
        %% get in the typical voltage corrections (in dB) needed for a
        %  particular headphone type, and interpolate to audiometric frequencies
        handles.SPLFile = HeadphoneTypeFile;
        M = csvread(HeadphoneTypeFile,1,0);
        dBVolts = interp1(M(:,1), M(:,2),handles.audiometricFreqs);
        
        %% get in the headphone specific tweaks, and interpolate to audiometric frequencies
        handles.TweaksFile = TweaksFile;
        M = csvread(TweaksFile,1,0);
        twksLeft = interp1(M(:,1), M(:,2),handles.audiometricFreqs);
        twksRight = interp1(M(:,1), M(:,3),handles.audiometricFreqs);
        
        %% add together the two sets of adjustments, and convert to linear factors
        % Left Channel
        MLeft = twksLeft + dBVolts;
        maxLeft = max(MLeft);
        % Right Channel
        MRight = twksRight + dBVolts;
        maxRight = max(MRight);
        % Find max of both channels
        maxOverall = min(maxLeft, maxRight);
        
        % Adjust values for left and right with largest value 0dB
        handles.adjLeft = (MLeft-maxOverall);
        handles.adjRight = (MRight-maxOverall);
        
        % maximum level in dB HL - GUI will only display pushbuttons
        % <= this level
        handles.maxdBHL=maxLevel;
    end
    
    %% Settings for level -- set sound card to get maximum level required at 250 Hz
    if ~handles.usePlayrec
        SetLevels(VolumeSettingsFile);
    else
    end
    
    %% make invisible the levels that are not necessary
    handles.tweak = maxLevel;
    if ~(70>=minLevel && 70<=maxLevel)
        set(handles.pushbutton70dB, 'Visible', 'off');
    end
    if ~(65>=minLevel && 65<=maxLevel)
        set(handles.pushbutton65dB, 'Visible', 'off');
    end
    if ~(60>=minLevel && 60<=maxLevel)
        set(handles.pushbutton60dB, 'Visible', 'off');
    end
    if ~(55>=minLevel && 55<=maxLevel)
        set(handles.pushbutton55dB, 'Visible', 'off');
    end
    if ~(50>=minLevel && 50<=maxLevel)
        set(handles.pushbutton50dB, 'Visible', 'off');
    end
    if ~(45>=minLevel && 45<=maxLevel)
        set(handles.pushbutton45dB, 'Visible', 'off');
    end
    if ~(40>=minLevel && 40<=maxLevel)
        set(handles.pushbutton40dB, 'Visible', 'off');
    end
    if ~(35>=minLevel && 35<=maxLevel)
        set(handles.pushbutton35dB, 'Visible', 'off');
    end
    if ~(30>=minLevel && 30<=maxLevel)
        set(handles.pushbutton30dB, 'Visible', 'off');
    end
    if ~(25>=minLevel && 25<=maxLevel)
        set(handles.pushbutton25dB, 'Visible', 'off');
    end
    if ~(20>=minLevel && 20<=maxLevel)
        set(handles.pushbutton20dB, 'Visible', 'off');
    end
    if ~(15>=minLevel && 15<=maxLevel)
        set(handles.pushbutton15dB, 'Visible', 'off');
    end
    if ~(10>=minLevel && 10<=maxLevel)
        set(handles.pushbutton10dB, 'Visible', 'off');
    end
    if ~(5>=minLevel && 5<=maxLevel)
        set(handles.pushbutton5dB, 'Visible', 'off');
    end
    if ~(0>=minLevel && 0<=maxLevel)
        set(handles.pushbutton0dB, 'Visible', 'off');
    end
    
    % initialise variables
    handles.trial=1;
    handles.HL=20;
    handles.tone=1000;  % frequency of tone
    set(handles.text4,'String',handles.tone);
    set(handles.text6,'String',sprintf('%d',handles.HL));
    if strcmpi(handles.correctionType,'SPL')
        handles.att=handles.HL-handles.maxdBHL;
        handles.HL_correctionLeft=interp1(handles.audiometricFreqs, handles.adjLeft,handles.tone);
        handles.HL_correctionRight=interp1(handles.audiometricFreqs, handles.adjRight,handles.tone);
    else
        handles.att=handles.HL-handles.maxdBHL;
    end
    
    handles.channel=0; % left
    set(handles.text8,'string','Left');
    guidata(fig, handles);
    %% output a summary file, including all the control paramters
    [varNames, varValues] = outputSummaryFromStructure(handles);
    fout = fopen(handles.parametersOutFile, 'wt');
    %     fprintf(fout,'%s,\n',varNames);
    %     fprintf(fout,'%s,\n',varValues);
    xx=split(varNames,",");
    yy=split(varValues,",");
    index = find(contains(xx,'I'));
    xx(1:index-1)=[];
    yy(1:index-1)=[];
    for k=1:length(xx)
        fprintf(fout, '%s,', char(xx{k}));
    end
    fprintf(fout,'\n');
    for k=1:length(xx)
        fprintf(fout, '%s,', char(yy{k}));
    end
    fprintf(fout,'\n');
    fclose(fout);
    
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    
    try
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    catch
        disp(lasterr);
    end
    
end

%%----------------------------------------------------------------------
%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and
%| sets objects' callback properties to call them through the FEVAL
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.


%% Set tone frequency
% --------------------------------------------------------------------
function varargout = pushbutton4_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.pushbutton4.
% disp('pushbutton4 Callback not implemented yet.')
handles.tone=250;
set(handles.text4,'String',handles.tone);
if strcmpi(handles.correctionType,'SPL')
    handles.HL_correctionLeft=interp1(handles.audiometricFreqs, handles.adjLeft,handles.tone);
    handles.HL_correctionRight=interp1(handles.audiometricFreqs, handles.adjRight,handles.tone);
end
guidata(h, handles);
% --------------------------------------------------------------------
function varargout = pushbutton5_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.pushbutton5.
%disp('pushbutton5 Callback not implemented yet.')
handles.tone=500;
set(handles.text4,'String',handles.tone);
if strcmpi(handles.correctionType,'SPL')
    handles.HL_correctionLeft=interp1(handles.audiometricFreqs, handles.adjLeft,handles.tone);
    handles.HL_correctionRight=interp1(handles.audiometricFreqs, handles.adjRight,handles.tone);
end
guidata(h, handles);
% --------------------------------------------------------------------
function varargout = pushbutton6_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.pushbutton6.
%disp('pushbutton6 Callback not implemented yet.')
handles.tone=1000;
set(handles.text4,'String',handles.tone);
if strcmpi(handles.correctionType,'SPL')
    handles.HL_correctionLeft=interp1(handles.audiometricFreqs, handles.adjLeft,handles.tone);
    handles.HL_correctionRight=interp1(handles.audiometricFreqs, handles.adjRight,handles.tone);
end
guidata(h, handles);
% --------------------------------------------------------------------
function varargout = pushbutton7_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.pushbutton7.
%disp('pushbutton7 Callback not implemented yet.')
handles.tone=2000;
set(handles.text4,'String',handles.tone);
if strcmpi(handles.correctionType,'SPL')
    handles.HL_correctionLeft=interp1(handles.audiometricFreqs, handles.adjLeft,handles.tone);
    handles.HL_correctionRight=interp1(handles.audiometricFreqs, handles.adjRight,handles.tone);
end
guidata(h, handles);
% --- Executes on button press in pushbutton9.
function varargout = pushbutton9_Callback(h, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.tone=4000;
set(handles.text4,'String',handles.tone);
if strcmpi(handles.correctionType,'SPL')
    handles.HL_correctionLeft=interp1(handles.audiometricFreqs, handles.adjLeft,handles.tone);
    handles.HL_correctionRight=interp1(handles.audiometricFreqs, handles.adjRight,handles.tone);
end
guidata(h, handles);
% --- Executes on button press in pushbutton10.
function varargout = pushbutton10_Callback(h, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.tone=8000;
set(handles.text4,'String',handles.tone);
if strcmpi(handles.correctionType,'SPL')
    handles.HL_correctionLeft=interp1(handles.audiometricFreqs, handles.adjLeft,handles.tone);
    handles.HL_correctionRight=interp1(handles.audiometricFreqs, handles.adjRight,handles.tone);
end
guidata(h, handles);

% --- Executes on button press in pushbutton11k.
function pushbutton11k_Callback(h, eventdata, handles)
% hObject    handle to pushbutton11k (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.tone=11000;
set(handles.text4,'String',handles.tone);
if strcmpi(handles.correctionType,'SPL')
    handles.HL_correctionLeft=interp1(handles.audiometricFreqs, handles.adjLeft,handles.tone);
    handles.HL_correctionRight=interp1(handles.audiometricFreqs, handles.adjRight,handles.tone);
end
guidata(h, handles);

% --- Executes on button press in pushbutton16k.
function pushbutton16k_Callback(h, eventdata, handles)
% hObject    handle to pushbutton16k (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.tone=16000;
set(handles.text4,'String',handles.tone);
if strcmpi(handles.correctionType,'SPL')
    handles.HL_correctionLeft=interp1(handles.audiometricFreqs, handles.adjLeft,handles.tone);
    handles.HL_correctionRight=interp1(handles.audiometricFreqs, handles.adjRight,handles.tone);
end
guidata(h, handles);

% --- Executes on button press in pushbutton20k.
function pushbutton20k_Callback(h, eventdata, handles)
% hObject    handle to pushbutton20k (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.tone=20000;
set(handles.text4,'String',handles.tone);
if strcmpi(handles.correctionType,'SPL')
    handles.HL_correctionLeft=interp1(handles.audiometricFreqs, handles.adjLeft,handles.tone);
    handles.HL_correctionRight=interp1(handles.audiometricFreqs, handles.adjRight,handles.tone);
end
guidata(h, handles);


%%-----------------------------------------------------------------------------------
% set a level in dB HL, adjust level dependent on channel and play out
% --- Executes on button press in pushbutton70dB.
function pushbutton0dB_Callback(h, eventdata, handles)
% h    handle to pushbutton70dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=0-handles.maxdBHL;
set(handles.text6,'String','0');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton70dB.
function pushbutton5dB_Callback(h, eventdata, handles)
% h    handle to pushbutton70dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=5-handles.maxdBHL;
set(handles.text6,'String','5');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton10dB.
function pushbutton10dB_Callback(h, eventdata, handles)
% hObject    handle to pushbutton10dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=10-handles.maxdBHL;
set(handles.text6,'String','10');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton15dB.
function pushbutton15dB_Callback(h, eventdata, handles)
% hObject    handle to pushbutton15dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=15-handles.maxdBHL;
set(handles.text6,'String','15');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton20dB.
function pushbutton20dB_Callback(h, eventdata, handles)
% hObject    handle to pushbutton20dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=20-handles.maxdBHL;
set(handles.text6,'String','20');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton25dB.
function pushbutton25dB_Callback(h, eventdata, handles)
% hObject    handle to pushbutton25dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=25-handles.maxdBHL;
set(handles.text6,'String','25');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton30dB.
function pushbutton30dB_Callback(h, eventdata, handles, varargin)
% hObject    handle to pushbutton30dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=30-handles.maxdBHL;
set(handles.text6,'String','30');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton35dB.
function pushbutton35dB_Callback(h, eventdata, handles)
% hObject    handle to pushbutton35dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=35-handles.maxdBHL;
set(handles.text6,'String','35');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton40dB.
function pushbutton40dB_Callback(h, eventdata, handles)
% hObject    handle to pushbutton40dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=40-handles.maxdBHL;
set(handles.text6,'String','40');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton45dB.
function pushbutton45dB_Callback(h, eventdata, handles)
% h    handle to pushbutton45dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=45-handles.maxdBHL;
set(handles.text6,'String','45');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton50dB.
function pushbutton50dB_Callback(h, eventdata, handles)
% h    handle to pushbutton50dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=50-handles.maxdBHL;
set(handles.text6,'String','50');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton55dB.
function pushbutton55dB_Callback(h, eventdata, handles)
% h    handle to pushbutton55dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=55-handles.maxdBHL;
set(handles.text6,'String','55');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton60dB.
function pushbutton60dB_Callback(h, eventdata, handles)
% h    handle to pushbutton60dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=60-handles.maxdBHL;
set(handles.text6,'String','60');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton65dB.
function pushbutton65dB_Callback(h, eventdata, handles)
% h    handle to pushbutton65dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=65-handles.maxdBHL;
set(handles.text6,'String','65');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
% --- Executes on button press in pushbutton70dB.
function pushbutton70dB_Callback(h, eventdata, handles)
% h    handle to pushbutton70dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.att=70-handles.maxdBHL;
set(handles.text6,'String','70');
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);
%--------------------------------------------------------------------------

%% choose ear to play from
% --- Executes on button press in pushbuttonLear.
function pushbuttonLear_Callback(h, eventdata, handles)
% hObject    handle to pushbuttonLear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.channel=0; %left earphone selected
set(handles.text8,'string','Left');
guidata(h, handles);
% --- Executes on button press in pushbuttonRear.
function pushbuttonRear_Callback(h, eventdata, handles)
% hObject    handle to pushbuttonRear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.channel=1; %right earphone selected
set(handles.text8,'string','Right');
guidata(h, handles);

%% play buttons
% --- Executes on button press in pushbuttonPlay.
function pushbuttonPlay_Callback(h, eventdata, handles)
% hObject    handle to pushbuttonPlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
playback(handles)
set(handles.text9,'Visible','Off');
outPutOneTonePlayed(handles);
guidata(h, handles);

% --- Executes on button press in pushbuttonNoPlay.
function pushbuttonNoPlay_Callback(h, eventdata, handles)
% hObject    handle to pushbuttonNoPlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbuttonLongPlay.
function pushbuttonLongPlay_Callback(h, eventdata, handles)
% hObject    handle to pushbuttonLongPlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.text9,'String',handles.tone);
set(handles.text9,'Visible','On');
% Select correction dependent on channel
currentDuration=handles.dur;
handles.dur=handles.longDuration;
currentNumPulses=handles.numPulses;
handles.numPulses=1;
playback(handles)
handles.dur=currentDuration;
handles.numPulses=currentNumPulses;
set(handles.text9,'Visible','Off');

% --- Executes on button press in recordCurrent.
function recordCurrent_Callback(h, eventdata, handles)
% save away the current configuration into a separate summary file
%
% hObject    handle to recordCurrent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
outPutOneTonePlayed(handles, handles.summaryOutFile)



function arbitraryFrequency_Callback(h, eventdata, handles)
% hObject    handle to arbitraryFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of arbitraryFrequency as text
%        str2double(get(hObject,'String')) returns contents of arbitraryFrequency as a double
if strcmpi(handles.correctionType,'SPL')
    opts = struct('WindowStyle','modal','Interpreter','tex');
    warndlg({'\fontsize{11} Not implemented for SPL method'},'Obs!', opts);
else
    handles.tone=1000*str2double(get(handles.arbitraryFrequency, 'String'));
    set(handles.text4,'String',handles.tone);
    guidata(h, handles);
end


% --- Executes during object creation, after setting all properties.
function arbitraryFrequency_CreateFcn(h, eventdata, handles)
% hObject    handle to arbitraryFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(h,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(h,'BackgroundColor','white');
end
