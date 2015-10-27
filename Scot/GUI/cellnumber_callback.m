function cellnumber_callback(source, eventdata, handles)
    % cellnumber_callback ---  resets gui after selection of a new cell
    %
    % Synopsis:        cellnumber_callback(source, eventdata, handles);
    %
    % Input:           source = handle to the calling uicontrol (cellnumber box) 
    %                  eventdata = structure, carries details of entry
    % Output:          handles = structure, with details of GUI and timelapse
    
    % Notes:    If the GUI is in 'SetUp' mode then the timelapse will not
    %           have been tracked - therefore the 'Cell number' entered
    %           should be considered to be a tracking number which can be
    %           used to identify cells (if the currently-selected timepoint
    %           has been segmented using the segment one timepoint button).

    handles=guidata(handles.gui);
    showMessage(handles,'');
    
     %Get the input number
     cellnumber=str2double(get(source,'String'));
     
     handles=changeCell(handles, cellnumber, handles.timelapse.CurrentFrame);            
    
    guidata(handles.gui, handles);
end