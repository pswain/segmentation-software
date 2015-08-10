function handles=deleteAll_callback(source, event, handles)
    % Synopsis:        handles=deleteAll_callback(source, event, handles)
    %
    % Input:           source = handle to the extractData button
    %                  event = structure, not used
    %                  handles = structure, carries timelapse and gui information
    % 
    % Output:          handles=structure, holds all gui information
    
    % Notes:    Called by clicking on the delete all button. Removes the
    %           currently-selected cell from all timepoints of a segmented
    %           dataset.
    
    handles=guidata(source);
    showMessage('Deleting cell from all timepoints');
    %Get or create a deleteCellAtAllTps object
    method=handles.timelapse.getobj('edittimelapse','deleteCellAtAllTps');
    %redefine the cellnumber that this object will work on - we
    %don't save methods with these different parameters - to save memory
    method.cellnumber=handles.cellnumber;
    %Run the method (there is no initializeFields method)
    handles.timelapse=method.run(handles.timelapse);
    %Record that a cell has been deleted from all timepoints in the post-history
    handles.timelapse.addToPostHistory(method);
    %Redefine the workflow to reflect the new post-History
    handles=setUpWorkflow(handles);    
    %Replot the data    
    handles=plotSegmented(handles);
    
    %Redefine the currently-selected cell - handles.cellnumber and
    %handles.trackingnumber
    done=false;
    startFrame=handles.timelapse.CurrentFrame;
    tooHigh=false;
    while ~done
        trackingnumbers=[handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells.trackingnumber];
        [minValue index]=nanmin(abs(handles.trackingnumber-trackingnumbers));%The nearest trackingnumber to the one just deleted
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
    showMessage('Cell deleted from all timepoints.');
    handles=changeCell(handles, handles.cellnumber, handles.timelapse.CurrentFrame);
    guidata(handles.gui,handles);