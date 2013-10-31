function handles=initialize_callback(source, event, handles)

    % initialize_callback --- runs the initializeFields method of the current method and displays result
    %
    % Synopsis:  handles = initialize_callback(source, event, handles)
    %
    % Input:     source = handle to the calling uicontrol
    %            event = structure (not used)
    %            handles = structure carrying segmentation and gui data
    %                                               
    % Output:    handles = structure carrying segmentation and gui data
    %
    % Notes:     This function was introduced to prevent slow running of
    %            the gui when methods have initializeFields methods that
    %            take time to run.
    
    handles=guidata(handles.gui);
    
    handles=initializeCurrentObj(handles);
    
    handles=displayImages(handles);
    
    
    
    guidata(handles.gui, handles);