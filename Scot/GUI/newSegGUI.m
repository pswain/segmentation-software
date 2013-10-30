function handles=newSegGUI(handles)
    % newSegGUI ---  sets the GUI up for new segmentations
    %
    % Synopsis:        handles=newSegGUI(handles)
    %
    % Input:           handles=structure, holds all gui information
    % 
    % Output:          handles=structure, holds all gui information
    
    % Notes:    In this form the user should be able to set the timepoint,
    %           have a 'Run for this timepoint' button. Also should be able
    %           to set parameters for the current method and use a 'Set
    %           further parameters' button to progress through the methods
    %           that are used to segment the timelapse.
    
    %Make irrelevant panels invisible
    set(handles.panels.data,'Visible','Off');
    %set(handles.panels.requiredimages,'Visible','Off');
    %set(handles.panels.tpResult);%Leave this visible for browsing input
    %data
    %set(handles.panels.cellResult,'Visible','Off');
    handles=defineCallbacks(handles);
    set(handles.infobox,'String', 'Set up new timelapse segmentation. Set parameters for this method, then click proceed button to get to next method. Click ''Segment single timepoint'' to see result of current selections.');
end