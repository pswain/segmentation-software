function handles=restoreInitial_callback(source, eventdata, handles)
    % restoreInitial_callback  ---  Reverts to the original version of the current method
    %              
    % Synopsis:    handles =  restoreInitial_callback(source, eventdata, handles)
    %
    % Input:       source = handle to the calling uicontrol
    %              eventdata = (unused) structure
    %              handles = structure, carrying all gui information

    %
    % Output:      handles = structure, carrying all gui information

    % Notes:       This callback is run when the restore initial button is
    %              clicked. It reverts to the version of the current
    %              method stored as handles.initialObject (defined by the
    %              setParameters function).
    
    handles=guidata(handles.gui);
    handles.currentMethod=handles.timelapse.methodFromNumber(handles.initialObject);
    handles=setParameters(handles);  
    set(handles.initialize,'Enable','on');
    showMessage('Reverted to initial parameters. Click show intermediate images button to show images created using these parameters');
    
    guidata(handles.gui,handles);
end