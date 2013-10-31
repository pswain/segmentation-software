function handles=proceed_callback(source, eventdata, handles)
    % proceed_callback  ---  moves to next method in the segmentation workflow
    %              
    % Synopsis:    handles =  proceed_callback(source, eventdata, handles)
    %
    % Input:       source = handle to the parameter text box that has been used
    %              eventdata = (unused) structure
    %              handles = structure, carrying all gui information

    %
    % Output:      handles = structure, carrying all gui information

    %Notes:        This callback is used only when setting up new
    %segmentations.
    
    %Get the stored handles data
    handles=guidata(handles.gui);
    handles.Level=handles.Level+1;
    set(handles.workflowList,'Value',handles.Level);
    %Reset the current method object
    handles.currentMethod=handles.methodObjects(handles.Level).objects;
    %Reset the package menu
    if isempty(handles.currentMethod.Info)
       handles.currentMethod.Info=metaclass(handles.currentMethod);
    end
    set(handles.packageMenu,'Value',find(strcmp(get(handles.packageMenu,'String'),handles.currentMethod.Info.ContainingPackage.Name)));
    %Reset the methods menu to this package
    handles=populateMethod(handles);
    %Disable the package menu and methods menu
    set(handles.packageMenu,'Enable','Off');
    set(handles.methodsMenu,'Enable','Off');
    %Update gui based on the new method object.
    setParameters(handles);
    set(handles.description,'String', handles.currentMethod.description);
    
    
    
    
    
    %Record the modified handles data
    guidata(source, handles);