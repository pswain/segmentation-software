function handles=schedule_callback(source, event, handles)
    % schedule_callback --- Runs scheduler dialogue to define scheduled segmentation and data extraction tasks
    %
    % Synopsis:  handles = schedule_callback (source, eventdata, handles)
    %
    % Input:     source = handle to the calling axis
    %            eventdata = structure, empty in this case
    %            handles = structure, carrying gui and timelapse information
    %
    % Output:    handles = structure, carrying gui and timelapse information


    % Notes:    This callback is executed when the user clicks the Schedule
    %           button. It allows users to define 1. source folders for
    %           timelapse segmentations. 2. A folder in which to save the
    %           data. 3. Data extraction methods with parameters.
    
    handles=guidata(handles.gui);
    %Variables to hold the schedule
    h.schedule.paths={''};
    h.schedule.extractmethods=0;
    %Create the dialog
    h.scheduleDialog=uipanel('Parent',handles.gui,'Units','Normalized','Position',[.3333 .475 .4 .3375],'Title','Scheduler');%WindowStyle','Modal', -   RESTORE AFTER WRITING THE CODE
    %panels
    h.panels.buttons=uipanel('Parent',h.scheduleDialog,'Position',[0 0 .2 1]);
    h.panels.targets=uipanel('Parent',h.scheduleDialog,'Position',[0.2 0.5 .4 .5]);
    h.panels.extractmethods=uipanel('Parent',h.scheduleDialog,'Position',[0.2 0 .4 .5]);
    h.panels.right=uipanel('Parent',h.scheduleDialog,'Position',[0.6 0 .4 1]);
    %List boxes
    h.list=uicontrol('Parent',h.panels.targets,'Style','Listbox','Units','Normalized','Position',[0 0 1 1]);  
    h.extractlist=uicontrol('Parent',h.panels.extractmethods,'Style','Listbox','Units','Normalized','Position',[0 0 1 1]);  
    %File selection window
    [h.jFileChoose, h.matFileChoose] = javacomponent('javax.swing.JFileChooser');
    h.jFileChoose.setMultiSelectionEnabled(true);
    set(h.matFileChoose,'Parent', h.panels.right,'Units','Normalized','Position',[0 0 1 1]);
    h.jFileChoose.setControlButtonsAreShown(false);
    h.jFileChoose.setFileSelectionMode(javax.swing.JFileChooser.DIRECTORIES_ONLY);%THIS WILL NEED TO BE CHANGED WHEN BIOFORMATS FILE IMPORT IS INTRODUCED - ALLOW FILES TO BE SELECTED
    %Buttons and menu
    h.add=uicontrol('Parent',h.panels.buttons,'Style','PushButton','Units','Normalized','Position',[.02 .848 .98 .15],'String','Add','Callback',{@addToSchedule_callback, h},'ToolTipString','Add a timelapse dataset to the schedule');
    h.delete=uicontrol('Parent',h.panels.buttons,'Style','PushButton','Units','Normalized','Position',[.02 .696 .98 .15],'String','Delete','Callback',{@deleteFromSchedule_callback, h},'ToolTipString','Remove selected dataset from the schedule');
    h.addextract=uicontrol('Parent',h.panels.buttons,'Style','PushButton','Units','Normalized','Position',[.02 .544 .98 .15],'String','Add data extraction method','Callback',{@addExtract_callback, h},'ToolTipString','Add the current data extraction method to the schedule');
    h.deleteextract=uicontrol('Parent',h.panels.buttons,'Style','PushButton','Units','Normalized','Position',[.02 .392 .98 .15],'String','Remove selected data extraction method','Callback',{@deleteExtract_callback, h},'ToolTipString','Click to delete the selected data extraction method');
    h.return=uicontrol('Parent',h.panels.buttons,'Style','PushButton','Units','Normalized','Position',[.02 .02 .98 .15],'String','Exit','Callback',{@exitSchedule_callback, h},'ToolTipString','Return to main GUI');
    %Inactivate GUI controls not used in schedule setup. Activate controls
    %for defining extract data methods
    controls=[get(handles.panels.general, 'Children'); get(handles.panels.inputoutput,'Children') ;get(handles.panels.workflow,'Children')];
    for n=1:size(controls,1)
        if strcmp(fields(get(controls(n))),'Enable')
            set(controls(n),'Enable','off');
        elseif strcmp(fields(get(controls(n))),'Visible')
            set(controls(n),'Visible','off');                
        end
    end
    
end

function addToSchedule_callback(source, event, h)
    scheduleList=get(h.list,'String');
    selected=h.jFileChoose.getSelectedFiles;
    for n=1:size(selected,1)
        path=char(selected(n));
        if ~any(strcmp(scheduleList,path));
            if isempty(scheduleList)
                numDirs=0;
            else
                numDirs=size(scheduleList,2);
            end            
            scheduleList{numDirs+1}=path;
        end
        
    end
    set(h.list,'String',scheduleList);
end



function deleteFromSchedule_callback(source, event, h)
    scheduleList=get(h.list,'String');
    scheduleList{get(h.list,'Value')}=[''];
    scheduleList(strcmp(scheduleList,''))=[];
    set(h.list,'String',scheduleList);
end



function exitSchedule_callback(source, event, h)

disp('stop');

end