function run_callback(source, eventdata,handles)
    % run_callback --- runs the currently-defined method
    % 
    %
    % Synopsis:  handles = run_callback(source, event, handles)
    %
    % Input:     source = handle to the calling uicontrol
    %            event = structure (not used)
    %            handles = structure carrying segmentation and gui data
    %                                               
    % Output:    handles = structure carrying segmentation and gui data
    %
    % Notes:     This function runs only the current method. If the method
    %            does not itself complete segmentation then it will not
    %            proceed to completion, but display only the result of the
    %            current method. This is also used for running extractdata
    %            methods, in which case it plots the results in the data
    %            panel.
    
    
    
    handles=guidata(handles.gui);
    if isempty(handles.currentMethod.Info)
        handles.currentMethod.Info=metaclass(handles.currentMethod);
    end
    if strcmp(handles.currentMethod.Info.ContainingPackage.Name,'extractdata')
        showMessage(handles,'Extracting data...');
        %Run the method
        handles.currentObj=handles.currentMethod.run(handles.timelapse);
        handles.currentDataField=handles.currentMethod.datafield;
        handles.timelapse.addToPostHistory(handles.currentMethod);
        handles=setUpWorkflow(handles);
        handles.plottype=handles.currentMethod.plottype;
        %Plot the data
        showMessage(handles,'Plotting...');
        handles=plotSegmented(handles);
        set (handles.exportdata,'Enable','On');
        set (handles.exportjpeg,'Enable','On');
        showMessage(handles,'Data extraction and plotting complete.');
    else
        %Make sure any intermediate images are already made
        showMessage(handles,'Initializing intermediate images...');
        handles.currentObj=handles.currentMethod.initializeFields(handles.currentObj);                
        %Run the method
        showMessage(handles,'Running method...');
        handles.currentObj=handles.currentMethod.run(handles.currentObj);
        %If the method does not alter the obj.Result image then set the obj.Result
        %field to empty - segmentation method must then be run so that the
        %result reflects the intermediate image just created
        if ~strcmp(handles.currentMethod.resultImage, 'Result')
                handles.currentObj.Result=[];
                handles.currentObj.DisplayResult=[];
                showMessage(handles,'Run whole workflow to show the effect of this method on the final result');
        else
            %NEED TO RUN ALL EXTRACTDATA METHODS BEFORE RUNNING
            %PLOTSEGMENTED - TO SEE EFFECT OF THIS METHOD - OR JUST SHOW A
            %MESSAGE TO THE USER AND CLEAR THE GRAPH
            handles=plotSegmented(handles);
        end
        %Update the display.
        handles=displayImages(handles);
    end
    
    guidata(handles.gui,handles);
end