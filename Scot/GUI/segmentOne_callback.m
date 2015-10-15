function handles=segmentOne_callback(source, eventdata,handles)
    % segmentOne --- runs segmentation of a single timepoint to allow evaluation of results
    %
    % Synopsis: 	segmentOne (source, eventdata, handles)
    %
    % Input:	source = handle to the calling uicontrol
    %           eventdata = structure, details of event that called this function
    %           handles = structure, contains all GUI and timelapse information
    %
    % Output: 	handles = structure, contains all GUI and timelapse information
    
    % Notes: 	This function is used when setting up new segmentations. It
    %           will do nothing but display an error message if the
    %           timelapse segmentation method class has no method called
    %           segmentOneTimepoint.
        
    %Retrieve handles structure
    handles=guidata(handles.gui);    
    %Set display pane
    set(handles.gui,'CurrentAxes',handles.intResult);
    %Prepare the timelapse for segmentation
    [handles.timelapse history] =  handles.timelapse.RunMethod.prepareSegmentation(handles.timelapse,'SingleTimepoint');
       
    if ismethod(handles.timelapse.SegMethod, 'segmentOneTimepoint')
        %Make sure any intermediate images are already made
        if size(handles.timelapse.SegMethod.requiredFields,1)>0 || size(handles.timelapse.SegMethod.requiredImages,1)>0
            showMessage(handles,'Initializing intermediate images and fields...');
            handles.timelapse=handles.timelapse.SegMethod.initializeFields(handles.timelapse, struct('objects', {},'fieldnames',{}));
        end
        %Run the method
        showMessage(handles,'Running single timepoint segmentation...');
        handles.currentObj=handles.timelapse.SegMethod.segmentOneTimepoint(handles.timelapse, history);%
        %Redefine the number of cells - used in preallocation
        handles.timelapse.RunMethod=handles.timelapse.RunMethod.setNumCells(handles.timelapse.RunMethod,handles.timelapse);
        %Create empty TrackingData and Result entries for the remainder of
        %the timepoints - in order to show blank images when timepoint is
        %chnged up
        handles.timelapse.TrackingData(handles.timelapse.TimePoints).cells=[];
        handles.timelapse.Result(handles.timelapse.TimePoints).timepoints=[];
        %handles.currentObj is now a timepoint object - initialize it for
        %display and reset handles.Level to its run method.
        handles.timelapse.makeDisplayResult;
        findLevel=find(strcmp(handles.workflowNames,'RunTpSegMethod'));
        handles.levelObjects(findLevel(1)).objects=handles.currentObj;
        handles.Level=findLevel(1);
        set(handles.workflowList,'Value', handles.Level);
        handles.currentMethod=handles.currentObj.RunMethod;
        %Set the trackingnumber to the first found cell in the timepoint
        if size(handles.timelapse.TrackingData(handles.currentObj.Frame).cells,2)>0
            handles.trackingnumber=1;
            set(handles.panels.requiredimages,'Visible','On');
            set(handles.panels.cellResult,'Visible','On');
            set(handles.cellnumBox,'Enable','On');
            handles.region=handles.timelapse.TrackingData(handles.currentObj.Frame).cells(handles.trackingnumber).region;
            handles.trackdata=handles.timelapse.TrackingData(handles.currentObj.Frame).cells(handles.trackingnumber);
            handles.trackdata.frame=handles.currentObj.Frame;
            set(handles.initialize,'Enable','On');
            %Update the display.
            handles=displayImages(handles);
        else
            showMessage (handles,'No cells were successfully segmented during single timepoint segmentation');
        end
        %If in Edit mode - ie if the whole timelapse has already been
        %segmented - need to retrack - cells need to have cellnumbers.
        if strcmp(handles.mode,'Edit')
           %Determine if the tracking method has a tracktimepoint method - if not, run the whole method
           
            
        end
        
    else
        showMessage(handles,'Timelapse segmentation method does not have a method to segment a single timepoint.');
    end
    handles=highlightWorkflow(handles);
    handles=redefineWorkflow(handles);
    guidata(handles.gui,handles);
end