function [handles]=tpsliderdrag_callback(source, event, handles)
% tpsliderdrag_callback ---  updates target and result images as timepoint slider is dragged
%
% Synopsis:        handles = tpsliderdrag_callback(source, event, handles)
%                 
% Input:           source = handle to the slider
%                  event = structure, not used
%                  handles = structure, carries timelapse and gui information
%
% Output:          handles = structure, carries timelapse and gui information

% Notes: 

handles=guidata(source.gui);
position=get(source.tpresultaxes.slider,'Value');
position=round(position);
set(handles.timepoint,'String',num2str(position));

%Update the target image
highlighted=handles.rawImages.(handles.rawDisplay)(:,:,:,position);
targetImage=highlighted;
if isfield(handles,'region')%handles.region will not exist if no cell has yet been segmented
    highlighted(handles.region(2):handles.region(2)+handles.region(4)-1,handles.region(1):handles.region(1)+handles.region(3)-1,:)=highlighted(handles.region(2):handles.region(2)+handles.region(4)-1,handles.region(1):handles.region(1)+handles.region(3)-1,:).*2;
end
if isfield(handles.tpresultaxes,'targetimage')
    set(handles.tpresultaxes.targetimage,'CData',highlighted);
else
   axes(handles.tpresultaxes.target);handles.tpresultaxes.targetimage=imshow(highlighted);
end

%If a timelapse is segmented then also update the merged and binary result
%images.
segmented=false;
if ~isempty(handles.timelapse.DisplayResult)  
    if ~isempty(handles.timelapse.DisplayResult(position).timepoints)
        if size(handles.timelapse.TrackingData,2)>=position
            segmented=true;
            result=full(handles.timelapse.DisplayResult(position).timepoints);
            set(handles.tpresultaxes.binaryimage,'CData',result);
            %Make the segmented cells magenta
            magCells=result;
            %Get an image for the current cell
            %Get the trackingnumber (if any) of the current cell
            if ~isempty(handles.timelapse.TrackingData(position).cells)
                trackNos=[handles.timelapse.TrackingData(position).cells.trackingnumber];
                trackingNumber=trackNos([handles.timelapse.TrackingData(position).cells.cellnumber]==handles.cellnumber);
            else
                trackingNumber=0;
            end
                if trackingNumber>0
                    thisCellResult=handles.timelapse.Result(position).timepoints(trackingNumber).slices;
                    thisCellResult=thisCellResult(1:handles.timelapse.ImageSize(2), 1:handles.timelapse.ImageSize(1));

                else
                    thisCellResult=false(size(result));
                end    
            %Remove the selected cell
            magCells(thisCellResult)=false;
            %Add magenta cells to merged image
            mainImage=double(handles.rawImages.(handles.rawDisplay)(:,:,1,position));
            mainImage=mainImage./255;
            mainImage=mainImage(1:handles.timelapse.ImageSize(2), 1:handles.timelapse.ImageSize(1));
            merged(:,:,1)=mainImage+magCells./3;%3 is a transparency factor - could make that controllable by the user
            merged(:,:,3)=mainImage+magCells./3;%3 is a transparency factor - could make that controllable by the user
            %Make the selected cell green
            merged(:,:,2)=mainImage+thisCellResult./3;%3 is a transparency factor - could make that controllable by the user       
            merged(merged>1)=1;
            set(handles.tpresultaxes.mergedimage,'CData',merged);
            %Update the region image displays too - imshow is too slow here so just
            %display the region covered by the current handles.region
            x=handles.region(1);
            y=handles.region(2);
            xl=handles.region(3);
            yl=handles.region(4);
            %set(handles.cellresultaxes.mergedimage,'CData',merged(y:y+yl-1,x:x+xl-1,:));   
            %set(handles.cellresultaxes.binaryimage,'CData',result(y:y+yl-1,x:x+xl-1));
            %set(handles.cellresultaxes.targetimage,'CData',repmat(mainImage(y:y+yl-1,x:x+xl-1,:),[1 1 3]));
            set(handles.cellresultaxes.mergedimage,'CData',merged);   
            set(handles.cellresultaxes.binaryimage,'CData',result);
            set(handles.cellresultaxes.targetimage,'CData',targetImage);
            
        end
    end
    if segmented==false
    	set(handles.tpresultaxes.binaryimage,'CData',[]);
        set(handles.tpresultaxes.mergedimage,'CData',[]);
        set(handles.cellresultaxes.binaryimage,'CData',[]);
        set(handles.cellresultaxes.mergedimage,'CData',[]);  
        set(handles.cellresultaxes.targetimage,'CData',[]);  



    end

    %Update the highlighting of the currently-selected cell in the data
    %graph.
    %COMMENTED THIS - MIGHT BE BETTER TO LEAVE THAT UNTIL SLIDER IS
    %RELEASED FOR SPEED
%     if handles.currentDataField ~=0
%         
%         %Highlight the new cell point
%         data=handles.timelapse.Data.(handles.currentDataField);
%         data(data==0)=nan;
%         interval=handles.timelapse.Interval;%Make this more sophisticated - to allow plotting of data with skipped timepoints
%         x=0:interval:interval*(size(data,2)-1);
%         thisx=x(position);
%         thisy=data(handles.cellnumber,position);
%         if ~isnan(thisy)
%             %Dehighlight the old point
%             delete(handles.currentPoint);
%             axes(handles.plot);
%             handles.currentPoint=plot(thisx,thisy, 'Marker','o', 'MarkerSize', 15,'LineWidth',4,'color',[0 0 0]);
%         else
%             set(handles.currentPoint,'Visible','Off');%Retain the handle to the old point - this avoids an error when you try to delete it next time a valid current point is plotted
%         end
%     end    
end
guidata(handles.gui,handles);
drawnow;
end