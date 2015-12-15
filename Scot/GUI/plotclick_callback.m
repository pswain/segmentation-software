function handles = plotclick_callback(source, eventdata)
    % plotclick_callback --- Selects the cell represented by the point on the plot nearest to the position of a user click
    %
    % Synopsis:  handles = plotclick_callback (source, eventdata, handles)
    %
    % Input:     source = handle to the calling axis
    %            eventdata = structure, empty in this case
    %            handles = structure, carrying gui and timelapse information
    %
    % Output:    handles = structure, carrying gui and timelapse information


    % Notes:    This callback is executed when the user clicks on the
    %           graph. It allows users to select a cell by clicking on a
    %           data point on the graph.

    handles=guidata(source);
    point=get(gca,'CurrentPoint');
    x=point(1,1,1);
    y=point(1,2,1);
    
    
    switch handles.plottype
        case 'Scatter'
            %Find the nearest data point

            %Note: this may need to be edited to handle different time intervals/points for different data sets - that
            %information to be included in the .Data property of handles. For now
            %assuming evenly-spaced entries the same for all datasets with
            %interval=handles.timelapse.Interval.
            frame=round(x/handles.timelapse.Interval)+1;%See note above
            yValues=handles.timelapse.Data.(handles.currentDataField)(:,frame);%The values of y plotted at this timepoint
            %remove zero entries
            yValues(yValues==0)=nan;
            diffs=(yValues-y);%Subtraction to find the nearest point
            [diff index]=min(abs(diffs));
            %Index is now the cellnumber of the cell to be selected.
            if ~isnan(diff)%This takes care of the sitution where there are no cells segmented at the frame that was clicked
                handles=changeCell(handles, index, frame);
            end%Could have an else here to find the nearest timepoint at which there might be a cell.
        case'Histogram'
            x=round(x);
            points=get(gca,'Children');
            cellnumber=0;
            %Find the cell number of the selected cell
            for n=1:length(points)
                tag=get(points(n),'Tag');
                xdata=get(points(n),'Xdata');
                if xdata(1)==x
                   %This is the selected point
                   cellnumber=str2double(tag);
                end
            end
           
            if cellnumber>0
                handles=changeCell(handles, cellnumber, handles.timelapse.CurrentFrame);
            end           
            
    end
    guidata(handles.gui,handles);
end