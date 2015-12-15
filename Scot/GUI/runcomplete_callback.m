function handles=runcomplete_callback(source, eventdata,handles)
    % runcomplete_callback --- runs the currently-defined method to the completion of timelapse segmentation
    % 
    %
    % Synopsis:  handles = runcomplete(handles)
    %
    % Input:     handles = structure carrying segmentation and gui data
    %                                               
    % Output:    handles = structure carrying segmentation and gui data
    %
    % Notes:     This function will complete the timelapse segmentation and
    %            tracking from the currently-selected level in the workflow
    %            onwards - eg if we are segmenting a region object it will
    %            only segment the cells in the current region with the new
    %            methods. If the currently-selected method is in the same
    %            package as the existing method at the selected level in
    %            the workflow then it replaces the existing method. If not,
    %            the behaviour will depend on the method types involved.
    
    handles=guidata(handles.gui);
    set(handles.gui,'CurrentAxes',handles.intResult);
    tic
    showMessage(handles,'Running method to completion of timelapse segmentation and tracking...');
    %Set the correct axes to show the intermediate images
    set(handles.gui,'CurrentAxes',handles.intResult);
    %Revert to the saved version of the current object - otherwise previously hitting the Run
    %button might have changed some of the RequiredFields or RequiredImages
    %and give you a false result.
    handles.currentObj=handles.savedObj.copy;%the saved version of the current object
    handles.currentObj.Timelapse=handles.timelapse;%This is essential so that the temp timelapse gets altered when you run methods on the temporary object   
    %Clear the result image of the current object - this will allow
    %progress to be shown during the run without previous results showing
    %up. Also need to clear the record of results at the timelapse level
    %that came from this object - the result image and the trackingdata. 
    handles.currentObj.Result=[];
    %Timelapse.Result (x,y,trackingnumber, timepoint)
    if isa(handles.currentObj,'Timelapse')
        handles.currentObj.Result=[];
        handles.timelapse.TrackingData=[];
    elseif isa(handles.currentObj,'Timepoint')
        %Clear all planes of the result image from the current timepoint.
        handles.currentObj.Timelapse.Result(:,:,:,handles.timelapse.CurrentFrame)=false;
        %set all the tracking data.cellnumber entries in the current
        %timepoint to NaN.
        for c=1:size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells,2)
            handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(c).cellnumber=NaN;
        end
    elseif isa(handles.currentObj,'Region')
        %Set the timelapse.Result image to false for the entries for the
        %tracking numbers in this region.
        ind=false(size(handles.timelapse.Result(handles.timelapse.CurrentFrame).timepoints,2),1);
        ind(handles.currentObj.TrackingNumbers)=true;
        handles.currentObj.Timelapse.Result(:,:,ind,handles.timelapse.CurrentFrame)=false;
        %get rid of the tracking data entries for those tracking numbers
        handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(ind).cellnumber=NaN;
    elseif isa(handles.currentObj,'OneCell')
    
    end
    
    
    %Determine if the current method is in the same package as the latest
    %method in the history
    if isempty(handles.currentMethod.Info)
        handles.currentMethod.Info=metaclass(handles.currentMethod);
    end
    savedMethod=getMethod(handles);
    if strcmp(savedMethod.Info.ContainingPackage.Name,handles.currentMethod.Info.ContainingPackage.Name)
        %They are in the same package - run, replacing the saved method in
        %the workflow.
        
        %initialize the history - taking the objects up to, but not
        %including the one at handles.Level (which is to be replaced)
        history=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).methodobj(1:handles.Level-1);
        %Initialize the fields - not applicable to run methods
        if ~strcmp(handles.currentMethod.Info.ContainingPackage.Name, 'runmethods')
            [handles.currentObj fieldHistory]=handles.currentMethod.initializeFields(handles.currentObj);
            %Add any objects created by the initializeFields call to the
            %history
            for n=1:size(fieldHistory.fieldnames,1)
                history=handles.currentMethod.insertFieldHistory(history, fieldHistory, n);
            end
        end
        %Determine if running the method will actually segment to
        %completion. If it's a level segmentation method or a runmethod 
        %then it will. In that case it's easy.
        switch handles.currentMethod.Info.ContainingPackage.Name
            case {'cellsegmethods', 'regionsegmethods', 'timepointsegmethods', 'timelapsesegmethods', 'runmethods'}                                
                %Run the method to segment
                showMessage(handles,['Running' ' ' handles.currentMethod.Info.Name]);
                handles.currentObj=handles.currentMethod.run(handles.currentObj, history);
            case {'findcentres', 'findregions', 'splitregion'}
                %In this case run this method, then proceed through the
                %workflow, running methods until you get to a runmethod or
                %level segmentation method. At that point you need to run
                %the level segmentation method for the current object (not
                %necessarily the next one in the workflow - that next one
                %might act at a different level)
                %First run the current method - these methods do not
                %take history as an input
                showMessage(handles,['Running' ' ' handles.currentMethod.Info.Name]);
                [handles.currentObj fieldHistory]=handles.currentMethod.run(handles.currentObj);
                %Add any objects created by the run call to the
                %history
                for n=1:size(fieldHistory.fieldnames,1)
                    history=handles.currentMethod.insertFieldHistory(history, fieldHistory, n);
                end
                %Initiaalize a while loop to run through remaining methods
                segmented=false;
                level=handles.Level+1;
                while segmented==false
                   method=getmethod(handles, level);
                   %Check which kind of method it is - will it segment to
                   %completion?
                   switch method.Info.ContainingPackage.Name
                       case {'findcentres', 'findregions', 'splitregion'}
                           %Initialize the fields
                           [handles.currentObj fieldHistory]=method.initializeFields(handles.currentObj);
                           %Add any objects created by the initializeFields call to the
                           %history
                           for n=1:size(fieldHistory.fieldnames,1)
                               history=method.insertFieldHistory(history, fieldHistory, n);
                           end
                           %Then run the method - methods in these packages
                           %don't take history as an input
                           showMessage(handles,['Running' ' ' method.Name]);
                           [handles.currentObj fieldHistory]=method.run(handles.currentObj);
                           %Add any objects created by the run call to the
                           %history
                           for n=1:size(fieldHistory.fieldnames,1)
                               history=method.insertFieldHistory(history, fieldHistory, n);
                           end
                           level=level+1;
                       case {'cellsegmethods', 'regionsegmethods', 'timepointsegmethods', 'timelapsesegmethods', 'runmethods'}                                
                           %The variable 'level' has reached a method that
                           %will run to completion of segmentation. Now run
                           %the segmentation method belonging to the
                           %current object and exit the while loop.
                           handles.currentObj=handles.currentObj.SegMethod.run(handles.currentObj, history);
                           segmented=true;
                   end
                end
        end
                       
                 
                                      
    else
    %The saved method and the current method are in different packages -
    %we can't simply replace one with the other - this is more complicated
    %to deal with - might be best to prevent this from happening - disable
    %the runcomplete button when this is the case
    
    end
    %Run tracking method
    showMessage(handles,'Tracking...');
    history=handles.timelapse.RunTrackMethod.run(handles.timelapse);%run the run method for that trackyeast object to track the cells
    %Activate the accept and reject buttons
    set(handles.accept,'Visible','On');
    set(handles.reject,'Visible','On');
    %Update the display - want to make sure that the result image of
    %segmentation is shown - not the result image of the current method
    handles=displayImages(handles);
    %Reset the workflow, based on the new segmentation
    handles=setUpWorkflow(handles);
    %Run the items in the post history and display results
    for n=1:size(handles.timelapse.PostHistory,2)
    handles.
    
    
    end
    
    time=toc;
    showMessage(handles,['Segmentation run took' ' ' num2str(time) 's']);
    guidata(handles.gui,handles);  
end