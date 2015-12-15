function handles=segmentsingle_callback(source, event, handles)
    % segmentsingle_callback --- Runs segmentation of a single timepoint
    %
    % Synopsis:  handles = segmentsingle_callback (source, eventdata, handles)
    %
    % Input:     source = handle to the calling axis
    %            eventdata = structure, empty in this case
    %            handles = structure, carrying gui and timelapse information
    %
    % Output:    handles = structure, carrying gui and timelapse information


    % Notes:    This callback is executed when the user clicks the segment
    %           single timepoint button. It allows evaluation of methods
    %           with a quicker run before the whole timelapse is processed.