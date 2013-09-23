function handles = redefineWorkflow(handles)
    % redefineWorkflow ---  (re)populates the handles.levelObjects array on the basis of the currently-selected cell
    %
    % Synopsis:        handles = redefineWorkflow (handles)
    %
    % Input:           handles = structure, carrying all timelapse and GUI information
    %
    % Output:          handles = structure, carrying all timelapse and GUI information
    
    %Notes: This function is called only when in setup mode where some cells
    %       may have been segmented but not the whole timelapse. If the
    %       currently-selected cell has been segmented then it will populate
    %       the various handles entries relating to the workflow to allow them
    %       to be retrieved when the user navigates through the workflow. If
    %       not they are left blank. This function should be run after
    %       segmenting a single timepoint or changing cell or timepoint in
    %       SetUp mode.
    
    %   handles.workflowNames = the names of each object in the workflow
    %   handles.workflowLevels = the type of level object ('OneCell', 'Region', 'Timepoint' or 'Timelapse') that each object either is or has worked on.
    %   handles.workflowResultImageNames = the name of the image or other field that each method has written its result to.
    %   handles.levelObjects = the handles to the level objects worked on at each stage of the workflow
    %   handles.methodObjects = method objects at each level in the workflow
    
    %First determine if the currently-selected cell has been segmented or
    %not.
    oldLevelObjects=handles.levelObjects;
    if ~isempty(handles.timelapse.TrackingData)
        if ~isempty(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells)
            if size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells,2)>handles.trackingnumber
                alternative=0;
                index=1;%This is the index to the entries in TrackingData.methodobj and levelobj for the current workflow level being considered
                for n=1:handles.historySize
                    objectNumber=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).levelobj(index);
                    [obj] = findObject(handles.timelapse, objectNumber, oldLevelObjects);
                    if isempty(obj)
                        [obj] = findObject(handles.timelapse, objectNumber, handles.levelObjects);
                    end

                    handles.levelObjects(n).objects=obj;
                    %Record the index in handles - will allow
                    %cross-referencing between the history in trackingdata
                    %and the workflow in the GUI
                    handles.tdIndex(n)=index;
                    %Increment index unless this is one of several
                    %alternative methods
                    if handles.workflowAlternatives(n)==0 || handles.workflowAlternatives(n)==alternative
                        index=index+1;
                        alternative=handles.workflowAlternatives(n);
                    end                        
                end
            end                        
        end                   
    end
end

    
