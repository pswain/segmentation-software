function handles = load_callback (source, eventdata, handles)
    % load_callback --- loads a saved timelapse and resets GUI based on saved results     
    %
    % Synopsis:  handles = load (source, eventdata, handles)
    %
    % Input:     handles = structure carrying segmentation and gui data
    %                                               
    % Output:    handles = structure carrying segmentation and gui data
    %
    % Notes:     This is the callback for the load button of the gui. Loads
    %            timelapse file (with a .sct extension) and recreates a
    %            timelapse object from that. Resets the GUI for editing,
    %            data extraction of this dataset.
    
    
    handles=guidata(handles.gui);
    cd (handles.timelapse.Moviedir);
    [FileName,PathName,FilterIndex] = uigetfile('*.sct','Load timelapse dataset');
    if FileName~=0
        showMessage(handles,'Loading timelapse data set...');
        handles.timelapse=Timelapse1.loadTimelapse([PathName FileName]);
    else
        showMessage(handles, 'No file loaded');
        return;
    end
    
    %Set up GUI for editing/extracting data from this timelapse
    handles=beginEdit(handles);

    guidata(handles.gui,handles);
    
end
