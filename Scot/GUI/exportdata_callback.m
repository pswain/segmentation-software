function  exportdata_callback(source, eventdata,handles)

    % exportdata_callback --- Saves the data extracted from segmented timelapse in a .csv file
    %
    % Synopsis:  exportdata_callback (source, eventdata,handles)
    %                        
    % Input:     source = handle to the calling uicontrol object
    %            eventdata = structure, details of calling event
    %            handles = structure, holds all gui and timelapse information
    %
    % Output:    

    % Notes:	 Executes when the exportdata button is clicked.
    
    handles=guidata(handles.gui);
    inputoutput.exportCSV(handles.timelapse);       
    %Record any changes to handles - this will allow use of a handles field
    %to record if there have been any changes since the last export
    guidata(handles.gui,handles);