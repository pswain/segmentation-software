function handles=cellZoom_callback(source, event, handles)   
    % cellZoom_callback --- segments and tracks a new timelapse     
    %
    % Synopsis:  handles = cellZoom_callback (source, eventdata, handles)
    %
    % Input:     source = handle to the calling uicontrol
    %            event = structure, not used            
    %            handles = structure carrying segmentation and gui data
    %                                               
    % Output:    handles = structure carrying segmentation and gui data
    %
    % Notes:     This is the callback for the zoom slider for the cell
    %            display. Allows the user to zoom out to see the area
    %            surrounding the segmentation result.
    handles=guidata(handles.gui);
    position=get(source,'Value');
    %Define a centre
    ycentre=handles.region(2)+handles.region(4)/2;
    xcentre=handles.region(1)+handles.region(3)/2;
    baseregion=handles.region;
    if ~isempty(handles.timelapse.TrackingData)
        if ~isempty(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells)
            if size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells,2)>=handles.trackingnumber;
                xcentre=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).centroidx;
                ycentre=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).centroidy;
                baseRegion=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).region;
            end
        end
    end
    %Calculate new region
    ratio=(1+position)/1;    
    xlength=round(baseRegion(3)*ratio);
    ylength=round(baseRegion(4)*ratio);
    topLeftx=round(xcentre-xlength/2);
    topLefty=round(ycentre-ylength/2);
    handles.region=[topLeftx topLefty xlength ylength];
    %Define new images for cell fields and display
    set(handles.cellresultaxes.target,'XLim',[handles.region(1) handles.region(1)+handles.region(3)-1],'YLim',[handles.region(2) handles.region(2)+handles.region(4)-1]);
    set(handles.cellresultaxes.merged,'XLim',[handles.region(1) handles.region(1)+handles.region(3)-1],'YLim',[handles.region(2) handles.region(2)+handles.region(4)-1]);
    set(handles.cellresultaxes.binary,'XLim',[handles.region(1) handles.region(1)+handles.region(3)-1],'YLim',[handles.region(2) handles.region(2)+handles.region(4)-1]);

end