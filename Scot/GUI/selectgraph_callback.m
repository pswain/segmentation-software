function handles = selectgraph_callback(source, eventdata, handles)   
    % selectgraph_callback --- displays an alternative extracted data set
    %
    % Synopsis:  handles = selectgraph_callback (source, eventdata, handles)
    %
    % Input:     source = handle to the calling axis
    %            eventdata = structure, empty in this case
    %            handles = structure, carrying gui and timelapse information
    %
    % Output:    handles = structure, carrying gui and timelapse information


    % Notes:    This callback is executed when the user selects an entry in
    %           the selectGraph popup menu.
    
    handles=guidata(handles.gui);
    dataFields=fields(handles.timelapse.Data);
    handles.currentDataField=dataFields{get(source,'Value')};    
    handles=plotSegmented(handles);
    guidata(handles.gui,handles);