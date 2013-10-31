function handles=initializeCurrentObj(handles)    
    % initializeCurrentObj ---  Runs the initializeFields method of the current object
    %
    % Synopsis:        handles=initializeCurrentObj(handles)
    %
    % Input:           handles=structure, holds all gui information
    % 
    % Output:          handles=structure, holds all gui information
    
    % Notes:    This will generate intermediate images for display. Also
    %           will create the result of running the current method if the
    %           method doesn't complete segmentation.

    showMessage('initializing required fields...');
    %First create the target, result and DisplayResult fields of the
    %current object (if possible)
    if ismethod(handles.currentObj, 'initializeFields')
        handles.currentObj=initializeFields(handles.currentObj);
    end
    %Then run initializeFields method of the current method object to
    %create any intermediate images.
    %Initializefields method is only relevant if currentMethod isn't a run
    %method
    if isempty(handles.currentMethod.Info)
        handles.currentMethod.Info=metaclass(handles.currentMethod);
    end
    if isempty(handles.currentMethod.Info.ContainingPackage)
    	handles.currentMethod.Info=metaclass(handles.currentMethod);
    end
    if ~strcmp(handles.currentMethod.Info.ContainingPackage.Name,'runmethods') && ~strcmp(handles.currentMethod.Info.ContainingPackage.Name,'trackmethods')
        [handles.currentObj fieldHistory]=handles.currentMethod.initializeFields(handles.currentObj);
    end
    
    showMessage('Required fields initialized');
    
    
    
end