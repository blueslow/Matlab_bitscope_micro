function varargout = scope(varargin)
% SCOPE MATLAB code for scope.fig
%      SCOPE, by itself, creates a new SCOPE or raises the existing
%      singleton*.
%
%      H = SCOPE returns the handle to a new SCOPE or the handle to
%      the existing singleton*.
%
%      SCOPE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SCOPE.M with the given input arguments.
%
%      SCOPE('Property','Value',...) creates a new SCOPE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before scope_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to scope_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help scope

% Last Modified by GUIDE v2.5 10-Dec-2016 15:47:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @scope_OpeningFcn, ...
                   'gui_OutputFcn',  @scope_OutputFcn, ...
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
end

% --- Executes just before scope is made visible.
function scope_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to scope (see VARARGIN)

    % Choose default command line output for scope
    handles.output = hObject;
    

    if nargin == 4
        handles.scope=varargin{1};
    end
    handles.x = [];
    handles.y = [];
    handles.channel = 'a';
    handles.tcount = 0;
        
    % Update handles structure
    guidata(hObject, handles);

    if nargin == 4
        scope_Update(handles);
    else
        disp('Run main instead');
        closereq();
    end
    % UIWAIT makes scope wait for user response (see UIRESUME)
    % uiwait(handles.scope);

end

% --- Outputs from this function are returned to the command line.
function varargout = scope_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    % Get default command line output from handles structure
    try
     varargout{1} = handles.output;
    catch me
        varagout{1} = handles;
    end
end

% --- Executes on selection change in lChannel.
function lChannel_Callback(hObject, ~, handles)
% hObject    handle to lChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lChannel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lChannel
    if hObject.Value == 1
        handles.channel = 'a';
        handles.scope.assign_channel('a');
    else
        handles.channel ='b';
        handles.scope.assign_channel('b');
    end  
    guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function lChannel_CreateFcn(hObject, ~, ~)
% hObject    handle to lChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

end

% --- Executes on slider movement.
function sOffset_Callback(hObject, ~, handles)
% hObject    handle to sOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine lrange of slider
    range = handles.scope.data{'range'};
    oldval = range{'offset'};
    value = hObject.Value;
    increment = value - oldval;
    handles.scope.move_range(increment);
    newval = range{'offset'};
    if newval ~= oldval
        hObject.Value = newval;
    end
    scope_Update(handles);

end
% --- Executes during object creation, after setting all properties.
function sOffset_CreateFcn(hObject, ~, ~)
% hObject    handle to sOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

end
% --- Executes on selection change in lTrigger.
function lTrigger_Callback(hObject, ~, handles)
% hObject    handle to lTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lTrigger contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lTrigger

end
% --- Executes during object creation, after setting all properties.
function lTrigger_CreateFcn(hObject, ~, ~)
% hObject    handle to lTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

end

% --- Executes on slider movement.
function sTimebase_Callback(hObject, ~, handles)
% hObject    handle to sTimebase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine lrange of slider
    timebase = handles.scope.data{'timebase'};
    %oldval = timebase{'value'};
    value = int16(hObject.Value);
    handles.scope.set_timebase(value);
    newval = int16(timebase{'value'});
    if newval ~= value
        hObject.Value = newval;
    end
    scope_Update(handles);
end


% --- Executes during object creation, after setting all properties.
function sTimebase_CreateFcn(hObject, ~, ~)
% hObject    handle to sTimebase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

end
% --- Executes on button press in pbTrace.
function pbTrace_Callback(hObject, ~, handles)
% hObject    handle to pbTrace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [x,y] =scope_trace_aquire(hObject,handles);
    [x,y] =scope_trace_aquire(hObject,handles);    
    handles.x = x;
    handles.y = y;
    handles.tcount = handles.tcount +1;
    guidata(hObject,handles);
end

function [x,y] =scope_trace_aquire(hObject,handles)
    while not(handles.scope.ready)
       handles.scope.update();
    end
    while 1
        if handles.scope.trace_state == 1 
            handles.scope.update(); % init request
        elseif handles.scope.trace_state == 2
            handles.scope.update(); % Aquire data
        elseif handles.scope.trace_state == 3
            handles.scope.update()
            % Get data,scale and calculate sample rate
            yP =cell(handles.scope.active{'trace'}); % Get samples
            y=cellfun(@double,yP);
            range = handles.scope.data{'range'};
            scale = range{'span'}/256;
            m = range{'low'};
            y=y*scale+m;
            timebase = handles.scope.data{'timebase'};
            clockticks = double(timebase{'value'});
            samplePeriod =clockticks/40e6 ;
            x = (0:length(y)-1)*samplePeriod;
            plot(x,y,'b');
            ro=refline(0,range{'offset'});
            ro.Color='r';
            legend({'Signal','Offset'});
            ax=handles.axes;
            ax.YGrid='on';
            ax.XLim=[-ax.XTick(2)/size(ax.XTickLabel,1),...
                     ax.XLim(2)+ax.XTick(2)/size(ax.XTickLabel,1)];
            ax.YMinorTick='on';
            ax.XGrid='on';
            ax.XGrid='on';
            ax.XMinorTick='on';
            ax.XMinorGrid='on';
            ax.XAxisLocation='origin';
            xlabel('s')
            ylabel('V')
            break
        else
            break
        end
    end
end
% --- Executes on button press in cbRepeat.
function cbRepeat_Callback(hObject, ~, handles)
% hObject    handle to cbRepeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end


% --- Executes on slider movement.
function sSpan_Callback(hObject, ~, handles)
% hObject    handle to sSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    range = handles.scope.data{'range'};
    oldval = range{'span'};
    value = hObject.Value;
    increment = value - oldval;
    handles.scope.adjust_span(increment);
    newval = range{'span'};
    if newval ~= oldval
        hObject.Value = newval;
    end
    scope_Update(handles);
end
% --- Executes during object creation, after setting all properties.
function sSpan_CreateFcn(hObject, ~, ~)
% hObject    handle to sSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

end
% --- Executes on slider movement.
function sHigh_Callback(hObject, ~, handles)
% hObject    handle to sHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    range = handles.scope.data{'range'};
    oldval = range{'high'};
    value = hObject.Value;
    increment = value - oldval;
    handles.scope.adjust_range('high',increment);
    newval = range{'high'};
    if newval ~= oldval
        hObject.Value = newval;
    end
    scope_Update(handles);

end
% --- Executes during object creation, after setting all properties.
function sHigh_CreateFcn(hObject, ~, ~)
% hObject    handle to sHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

end


% --- Executes on slider movement.
function sLow_Callback(hObject, ~, handles)
% hObject    handle to sLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    range = handles.scope.data{'range'};
    oldval = range{'low'};
    value = hObject.Value;
    increment = value - oldval;
    handles.scope.adjust_range('low',increment);
    newval = range{'low'};
    if newval ~= oldval
        hObject.Value = newval;
    end
    scope_Update(handles);

end
% --- Executes during object creation, after setting all properties.
function sLow_CreateFcn(hObject, ~, ~)
% hObject    handle to sLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function scope_Update(h)
    range = h.scope.data{'range'};
    h.sSpan.Min=0;
    h.sSpan.Max=range{'max'}-range{'min'};
    h.sSpan.Value = range{'span'};
    h.stSpanValue.String= [num2str(h.sSpan.Value,3),'V'];
    
    h.sHigh.Min=range{'min'};
    h.sHigh.Max=range{'max'};
    h.sHigh.Value = range{'high'};
    h.stHighValue.String= [num2str(h.sHigh.Value,3),'V'];
    
    h.sOffset.Min=range{'min'};
    h.sOffset.Max=range{'max'};
    h.sOffset.Value = range{'offset'};
    h.stOffsetValue.String= [num2str(h.sOffset.Value,3),'V'];
    
    h.sLow.Min=range{'min'};
    h.sLow.Max=range{'max'};
    h.sLow.Value = range{'low'};
    h.stLowValue.String= [num2str(h.sLow.Value,3),'V'];
    
    timebase = h.scope.data{'timebase'};
    h.sTimebase.Min = timebase{'min'};
    h.sTimebase.Max = timebase{'max'};
    h.sTimebase.Value = int16(timebase{'value'});
    h.scope.ticks_to_timebase();
    h.stTimebaseValue.String= [num2str(timebase{'display'},5),'µs'];
    
    h.axes.YLim = [h.sLow.Value,h.sHigh.Value];

    h.axes.XLim = [0,timebase{'display'}];
    
    h.sFreq.Value = h.scope.data{'frequency'};
    h.tFreqValue.String = [num2str(h.sFreq.Value),'kHz'];
    
    h.sSym.Value = h.scope.data{'symetry_percentage'};
    h.tSymValue.String = [num2str(h.sSym.Value),'%'];

   
    % Starta och vänta tills klar för s_init_req.
    k=0;
    while not(h.scope.ready)
       h.scope.update();
       k = k+1;
       if k>20
           e=questdlg('No bitscope found, connect one and try again or abort', ...
                      'Cmmunication error',...
                      'Try again',...
                      'Abort',...
                      'Try again');
           switch e
               case 'Try again'
                   k=0;
               case 'Abort'
                   closereq();
                   return
           end
       end         
    end

end


% --- Executes on selection change in lWaveform.
function lWaveform_Callback(hObject, ~, handles)
% hObject    handle to lWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lWaveform contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lWaveform
    value = int32(get(hObject,'Value'));
    handles.scope.select_waveform(value);
    
end
% --- Executes during object creation, after setting all properties.
function lWaveform_CreateFcn(hObject, ~, ~)
% hObject    handle to lWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on button press in pbIncFreq.
function pbIncFreq_Callback(~, ~, handles)
% hObject    handle to pbIncFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.scope.adjust_frequency(int16(1));
    handles.sFreq.Value = handles.scope.data{'frequency'};
    handles.tFreqValue.String = [num2str(handles.sFreq.Value),'kHz'];
end
% --- Executes on button press in pbDecFreq.
function pbDecFreq_Callback(~, ~, handles)
% hObject    handle to pbDecFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.scope.adjust_frequency(int16(-1));
    handles.sFreq.Value = handles.scope.data{'frequency'};
    handles.tFreqValue.String = [num2str(handles.sFreq.Value),'kHz'];
end
% --- Executes on slider movement.
function sFreq_Callback(hObject, ~, handles)
% hObject    handle to sFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    value = get(hObject,'Value');
    handles.scope.assign_frequency(value);
    handles.sFreq.Value = handles.scope.data{'frequency'};
    handles.tFreqValue.String = [num2str(handles.sFreq.Value),'kHz'];
end
% --- Executes during object creation, after setting all properties.
function sFreq_CreateFcn(hObject, ~, ~)
% hObject    handle to sFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

end
% --- Executes on button press in pbResetFreq.
function pbResetFreq_Callback(~, ~, handles)
% hObject    handle to pbResetFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.scope.reset_frequency();
    handles.sFreq.Value = handles.scope.data{'frequency'};
    handles.tFreqValue.String = [num2str(handles.sFreq.Value),'kHz'];
end
% --- Executes on button press in pbIncSym.
function pbIncSym_Callback(~, ~, handles)
% hObject    handle to pbIncSym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.scope.adjust_on_off_time('on', int16(1));
    handles.sSym.Value = handles.scope.data{'symetry_percentage'};
    handles.tSymValue.String = [num2str(handles.sSym.Value,4),'%'];
end
% --- Executes on button press in pbDecSym.
function pbDecSym_Callback(~, ~, handles)
% hObject    handle to pbDecSym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.scope.adjust_on_off_time('on',int16( -1));
    handles.sSym.Value = handles.scope.data{'symetry_percentage'};
    handles.tSymValue.String = [num2str(handles.sSym.Value,4),'%'];
end
% --- Executes on slider movement.
function sSym_Callback(hObject, ~, handles)
% hObject    handle to sSym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    value = get(hObject,'Value');
    handles.scope.assign_symetry(value);
    handles.sSym.Value = handles.scope.data{'symetry_percentage'};
    handles.tSymValue.String = [num2str(handles.sSym.Value,4),'%'];
end
% --- Executes during object creation, after setting all properties.
function sSym_CreateFcn(hObject, ~, ~)
% hObject    handle to sSym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

end
% --- Executes on button press in pbResetSym.
function pbResetSym_Callback(~, ~, handles)
% hObject    handle to pbResetSym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.scope.reset_symetry();
    handles.sSym.Value = handles.scope.data{'symetry_percentage'};
    handles.tSymValue.String = [num2str(handles.sSym.Value,4),'%'];
end
% --- Executes on button press in pbWGOnOff.
function pbWGOnOff_Callback(hObject, ~, handles)
% hObject    handle to pbWGOnOff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if isequal(hObject.String,'On')
        hObject.String = 'Off';
        childs=allchild(findobj('Tag','uipWaveGen'));
        for c = childs'
            if not(isequal(c.Tag,'pbWGOnOff'))
                c.Enable = 'Off';
            end
        end
        handles.scope.stop_wave();
    else
        hObject.String = 'On';
        childs=allchild(findobj('Tag','uipWaveGen'));
        for c = childs'
            if not(isequal(c.Tag,'pbWGOnOff'))
                c.Enable = 'On';
            end
        end
        handles.scope.start_wave();
    end
    handles.scope.update();
end


% --- Executes on selection change in pm.
function pm_Callback(hObject, ~, handles)
% hObject    handle to pm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm
    if isempty(handles.x)
        errordlg('Nothing to do, get data by selecting trace','No data');
        return;
    end
    samples = horzcat(handles.x', handles.y');
    switch hObject.Value
        case 1 % Save to file
            uisave({'samples'},['samples_',num2str(handles.tcount)]);
        case 2 % Save to workspace
            p ={'Enter new name for the workspace variable '};
            t = 'Save trace to workspace';
            lines = 1;
            def = {['Trace_',num2str(handles.tcount)]};
            answer = inputdlg(p, t, lines, def);
            if not(isempty(answer));
                letter = isletter(answer{1});
                if letter(1) == 1
                    assignin('base',answer{1}, samples);
                else
                    p = 'Workspace variable must begin with a letter and can''t be empty';
                    t = 'Workspace variable error';
                    errordlg(p,t);
                end
            end
        case 3 % FFT
            Y = fft(handles.y);
            L = length(handles.y);
            P2 = abs(Y/L);
            P1= P2(1:L/2+1);
            P1(2:end-1) = 2*P1(2:end-1);
            timebase = handles.scope.data{'timebase'};
            clockticks = double(timebase{'value'});
            Fs=40e6/clockticks;
            f = Fs*(0:(L/2))/L;
            %hold on;
            figure('Name', 'FFT');
            plot(f(1:100),P1(1:100));
            title('Single-sided Amplitude spectrum of Y(t)');
            xlabel('f (Hz)');
            ylabel('|P1(f)|');
            %hold off;
        case 4 % rms
            Ymean = mean(handles.y);
            Yrms = rms(handles.y-Ymean);
            Ypeak2peak = peak2peak(handles.y);
            Ypeak2rms = peak2rms(handles.y);
            Ymean = mean(handles.y);
            rm=refline(0, Yrms);
            rm.Color='m';
            p2p=refline(0, Ypeak2peak);
            p2p.Color='c';
            p2r=refline(0, Ypeak2rms);
            p2r.Color = 'k';
            pmean=refline(0, Ymean);
            pmean.Color='g';
            ax=handles.axes;
            ax.XLim=[-ax.XTick(2)/size(ax.XTickLabel,1),...
                     ax.XLim(2)+ax.XTick(2)/size(ax.XTickLabel,1)];
            xlabel('s')
            ylabel('V')

            legend({'Signal','Offset','Rms','Peak 2 Peak','Peak 2 Rms', 'Mean'});
        case 5 % min max
            ymax = max(handles.y);
            ymin = min(handles.y);
            rymax=refline(0, ymax);
            rymax.Color='m';
            rymin=refline(0, ymin);
            rymin.Color='c';
            ax=handles.axes;
            ax.XLim=[-ax.XTick(2)/size(ax.XTickLabel,1),...
                     ax.XLim(2)+ax.XTick(2)/size(ax.XTickLabel,1)];
            xlabel('s')
            ylabel('V')

            legend({'Signal','Offset',...
                ['Max ',num2str(ymax)],['min ',num2str(ymin)]});
            
        otherwise
            % do nothing
    end
            
end
% --- Executes during object creation, after setting all properties.
function pm_CreateFcn(hObject, ~, ~)
% hObject    handle to pm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


% --- Executes during object deletion, before destroying properties.
function scope_DeleteFcn(~, ~, handles)
% hObject    handle to scope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if isequal(class(handles.scope),'py.machine_scope.MachineScope')
        handles.scope.soft_reset();
    end
end
