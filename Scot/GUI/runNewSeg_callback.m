function handles = runNewSeg_callback (source, eventdata, handles)
    % runNewSeg_callback --- segments and tracks a new timelapse     
    %
    % Synopsis:  handles = runNewSeg (handles)
    %
    % Input:     source = handle to the calling uicontrol
    %            eventdata - structure, not used
    %            handles = structure carrying segmentation and gui data
    
    % Output:    handles = structure carrying segmentation and gui data
    %
    % Notes:     This is the callback for the Run Segmentation button of
    %            the GUI when it has been used to set up a new
    %            segmentation. Runs and tracks a timelapse segmentation, by
    %            running its RunMethod, followed by its RunTrackMethod.
    handles=guidata(handles.gui);
    set(handles.gui,'CurrentAxes',handles.intResult);
    tic;
    showMessage (handles, 'Running Timelapse segmentation...');
    %try
        handles.timelapse.RunMethod.run(handles.timelapse);
    %catch err
     %   showMessage(handles, ['Error running timelapse segmentation. ' err.identifier err.message err.stack.name],'r'); 
     %   return;
    %end
    showMessage (handles, 'Running Timelapse Tracking...');
    handles.timelapse.RunTrackMethod.run(handles.timelapse);
    time=toc;
    showMessage (handles, ['Timelapse segmentation and tracking took ' num2str(time/60) 'min']);
    %Set up GUI and other handles variables for timelapse editing
    handles=beginEdit(handles);
    
    %store the handles structure in guidata for use by callbacks
    guidata(handles.gui,handles);
    
    

end