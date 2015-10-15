function handles = makeSingleCellStack (handles)
    % makeSingleCellStack --- Creates displayable stacks of result images for the currently-selected cell
    %
    % Synopsis:  handles = makeSingleCellStack (handles)
    %
    % Input:     handles = structure, has all gui and timelapse data
    %
    % Output:    handles = structure, has all gui and timelapse data

    % Notes: This should be run after any change in the result images or
    %        currently-selected cell number. Populates the handles fields
    %        .cellResultStack (binary, full sized, showing individual cell)
    %        .regionResultStack (bindary, region sized, showing all cells
    %        in region)
    %        .fullSizeMerged (rgb, shows current cell in green, other cells
    %        in magenta)
    %        .regionMerged (rgb, as fullSizeMerged but only shows region)
       
    trackingnumbers=handles.timelapse.gettrackingnumbers(handles.cellnumber);
    handles.cellResultStack=false(handles.timelapse.ImageSize(2), handles.timelapse.ImageSize(1),size(trackingnumbers,2));
    for t=1:size(trackingnumbers,2)
        if trackingnumbers(t)>0
            handles.cellResultStack(:,:,t)=handles.timelapse.Result(t).timepoints(trackingnumbers(t)).slices;
        end
    end
    
    
    %Copy the main target images
    handles.fullSizeMerged=handles.mainImages;
    %Make the segmented cells magenta
    fourDResult(:,:,1,:)=handles.timelapse.DisplayResult(:,:,:);
    %Remove the selected cell
    fourDCellResult(:,:,1,:)=handles.cellResultStack(:,:,:);
    fourDResult(fourDCellResult)=0;
    handles.fullSizeMerged(:,:,1,:)=fourDResult./3+handles.fullSizeMerged(:,:,1,:);
    handles.fullSizeMerged(:,:,3,:)=fourDResult./3+handles.fullSizeMerged(:,:,3,:);
    %Make this cell green.
    handles.fullSizeMerged(:,:,2,:)=fourDCellResult./3+handles.fullSizeMerged(:,:,2,:);
    %Calculate stacks for region display
    handles=makeRegionStacks(handles);
   
    
end