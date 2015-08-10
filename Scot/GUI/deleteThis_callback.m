function handles=deleteThis_callback(source, event, handles)
    % Synopsis:        handles=deleteThis_callback(source, event, handles)
    %
    % Input:           source = handle to the extractData button
    %                  event = structure, not used
    %                  handles = structure, carries timelapse and gui information
    % 
    % Output:          handles=structure, holds all gui information
    
    % Notes:    Called by clicking on the delete this button. Removes the
    %           currently-selected cell from a segmented timelapse dataset.
    %           A deleteCell method is added to the post history but there
    %           is no direct record of this deletion event (the cellnumber
    %           and frame of all deleted cells are not stored in the
    %           history - to save memory). Instead, cells that have been
    %           deleted may be identified by their nan entries for
    %           cellnumber and trackingnumber in the
    %           handles.timelapse.TrackinData array and their nan values in
    %           the handles.timelapse.Result images.
    
    handles=guidata(source);
    %get or create a deleteCell object
    method=handles.timelapse.getobj('edittimelapse','deleteCell');
    %redefine the cellnumber and frame that this object will work on - we
    %don't save methods with these different parameters - to save memory
    method.frame=handles.timelapse.CurrentFrame;
    method.cellnumber=handles.cellnumber;
    %Run the method
    handles.timelapse=method.run(handles.timelapse);
    %Record that a cell has been deleted in the post-history
    handles.timelapse.addToPostHistory(method);
    %Redefine the workflow to reflect the new post-History
    handles=setUpWorkflow(handles);
    %Replot the current data set (if any)
    handles=plotSegmented(handles);
    %Redefine the currently-selected cell - handles.cellnumber and
    %handles.trackingnumber
    done=false;
    startFrame=handles.timelapse.CurrentFrame;
    tooHigh=false;
    while ~done
        trackingnumbers=[handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells.trackingnumber];
        %nanmin is in the statistic toolbox for some reason so avoid having
        %to use this by making any nan entries (deleted cells) very large
        trackingnumbers(isnan(trackingnumbers))=240000000;
        [minValue index]=min(abs(handles.trackingnumber-trackingnumbers));%The nearest trackingnumber to the one just deleted
        if ~isnan(minValue)%ie if there are any segmented cells left at this timepoint
            handles.trackingnumber=index;
            handles.cellnumber=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(index).cellnumber;
            done=true;
            break;
        end
        if handles.timelapse.CurrentFrame<size(handles.timelapse.TrackingData,2) && ~tooHigh
            handles.timelapse.CurrentFrame=handles.timelapse.CurrentFrame+1;
        else
            if handles.timelapse.CurrentFrame==size(handles.timelapse.TrackingData,2)
                tooHigh=true;
                handles.timelapse.CurrentFrame=startFrame;
            else %tooHigh must already be true - reduce currentFrame
                handles.timelapse.CurrentFrame=handles.timelapse.CurrentFrame-1;
                %This will lead to an error if
                %handles.timelapse.CurrentFrame==0 here, but that can only
                %happen if there are no segmented cells in the timelapse.
            end
        end
    end
    %Reset gui for the new cell
    handles=changeCell(handles, handles.cellnumber, handles.timelapse.CurrentFrame);    
    guidata(handles.gui,handles);
