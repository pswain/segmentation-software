function handles=highlightWorkflow(handles)
    % highlightWorkflow --- highlights the names on the workflow list to indicate alternatives and also which alternative has been used
    %
    % Synopsis:  handles=highlightWorkflow (handles)
    %
    % Input:     handles = structure carrying all the information used by the GUI
    %
    % Output:    handles = structure carrying all the information used by the GUI

    % Notes:
    
    %Define a look up table of pairs of html colours
    LUT={'green' , '99FF66' ; '3333FF' , '99FFFF' ; 'FF3366' , 'FF9966'};
    
    %Build an array of the level that each entry in
    %workflowalternatives corresponds to
    methodListIndex=1;
    workflowListIndices=zeros(size(handles.workflowAlternatives,2),1);
    for m=1:size(handles.workflowAlternatives,2)
        workflowListIndices(m)=methodListIndex;                   
        if handles.workflowAlternatives(m)==0 || ~any(handles.workflowAlternatives(m+1:end)==handles.workflowAlternatives(m))
           %Increment the methodListIndex if there are no
           %alternatives. Also increment it if you've got to
           %the end of a group of alternatives.
            methodListIndex=methodListIndex+1;                    
        end
    end
    
    %Loop through the workflow list highlighting alternative methods in the
    %appropriate way
    for n=1:size(handles.workflowNames,2)
        
        if handles.workflowAlternatives(n)>0
            %There are alternative methods at this level
            %Get the name of the method and define 'colour' as the darker of the two colour alternatives
            if isempty(handles.methodObjects(n).objects.Info)
                handles.methodObjects(n).objects.Info=metaclass(handles.methodObjects(n).objects);
            end
            name=handles.methodObjects(n).objects.Info.Name;
            k=strfind(name,'.');
            name=name(k+1:end);
            colour=LUT(handles.workflowAlternatives(n),1);     
            colour=colour{:};
            %Is this method used by the currently-selected cell?
            %First check if the current cell is segmented (if there is one)
            if ~isempty(handles.timelapse.TrackingData)
                if ~isempty(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame))
                    if ~isempty(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber))
                        methodList=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).methodobj;
                        listNumber=handles.methodObjects(n).objects.ObjectNumber;
                        if any(methodList==listNumber)
                            %The method is used by the currently-selected cell - check
                            %if it's used at the appropriate level                
                            usedMethodIndex=find(methodList==listNumber);
                            for o=1:size(usedMethodIndex,2)
                                if usedMethodIndex(o)==workflowListIndices(n)
                                   %This method is used at the appropriate level
                                   %Redefine 'colour' as the lighter colour of the pair in
                                   %the LUT                       
                                   colour=LUT(handles.workflowAlternatives(n),2);
                                   colour=colour{:};
                                end
                            end
                        end
                    end
                end
            end
            % Reset the name in the handles.workflowNames array - this will
            % now be displayed in the correct colour.
            handles.workflowNames(n)={['<HTML><BODY bgcolor="' colour '">' name '</Body</html>']};
       end     
    end
    set(handles.workflowList, 'String', handles.workflowNames); 
end