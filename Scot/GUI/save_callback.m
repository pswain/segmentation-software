function handles = save_callback (source, eventdata, handles)
    % save_callback --- segments and tracks a new timelapse     
    %
    % Synopsis:  handles = save (source, eventdata, handles)
    %
    % Input:     handles = structure carrying segmentation and gui data
    %                                               
    % Output:    handles = structure carrying segmentation and gui data
    %
    % Notes:     This is the callback for the save button of the gui. Saves
    %            the handles structure, including the timelapse data, in
    %            standart Matlab format (ie .mat format), but with a .sct
    %            extension.
    handles=guidata(handles.gui);
    cd (handles.timelapse.Moviedir);
    [FileName,PathName,FilterIndex] = uiputfile('*.sct','Save timelapse dataset');
    if FileName~=0
        if exist(PathName,'dir')==7
            showMessage('Saving timelapse dataset...');
            timelapse=handles.timelapse;
            timelapse.saveTimelapse(PathName,FileName);
            showMessage('Timelapse saved');
        else
            showMessage(handles, 'Timelapse not saved - did not receive valid path',r);
        end
    else
        showMessage(handles, 'Timelapse not saved - no filename entered',r);
    end
    
end