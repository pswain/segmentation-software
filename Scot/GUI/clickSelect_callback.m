function handles=clickSelect_callback(source, event, handles)

handles=guidata(handles.gui);
%Get the x and y positions of the click
ax=get(source,'Parent');
point=get(ax,'CurrentPoint');
x=round(point(1,1));
y=round(point(1,2));
result=get(handles.tpresultaxes.binaryimage,'CData');
%Is there a cell at this position?
isACell=result(y,x);
if isACell
    %Get region information - which cells have regions that cover this
    %point - define trackNo - the tracking number of the cell
    regions=[handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells.region];
    regions=(reshape(regions',4,size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells,2)))';
    possibleCells=regions(:,1)<=x & regions(:,1)+regions(:,3)>=x & regions (:,2)<=y & regions (:,2)+regions(:,4)>=y;
    trackNos=find(possibleCells);
    if size(trackNos,1)>1%more than one cell has a region covering the pixel
        %Loop through the result images to find the one(s) that are white
        %at that pixel
        stillPossible=false(size(trackNos,1),1);
        for n=1:size(trackNos,1)
            if handles.timelapse.Result(handles.timelapse.CurrentFrame).timepoints(trackNos(n)).slices(y,x)
                stillPossible(n)=true;
            end
        end
        stillPossible=trackNos(stillPossible);
        if size(stillPossible,1)>1%have still failed to find a single cell
            %There are two or more overlapping cells at the point that was
            %clicked. Pick the one whose centroid is closest to the clicked
            %point.
            centroids=[handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(stillPossible).centroidx; handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(stillPossible).centroidy];
            minDist(:,1)=centroids(:,1)-x;
            minDist(:,2)=centroids(:,2)-y;
            minDist=minDist.^2;
            [lowest k]=min(sum(minDist,2));%k is the index to the nearest centroid
            trackNo=stillPossible(k);           
        else
            trackNo=stillPossible;
        end
    else
        trackNo=trackNos;
    end
    %Change to the selected cell
    switch handles.mode
        case 'Edit'
            cellNo=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(trackNo).cellnumber;
        case 'SetUp'
            cellNo=trackNo;
    end
    handles=changeCell(handles,cellNo, handles.timelapse.CurrentFrame);
else%The user has clicked in a position where there is no segmented cell.
    disp('stop');
end


guidata(handles.gui,handles);