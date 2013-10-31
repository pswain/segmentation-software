function handles=defineCallbacks(handles)
    % defineCallbacks ---  defines GUI callbacks for editing segmentations
    %
    % Synopsis:        handles=defineCallbacks(handles)
    %
    % Input:           handles=structure, holds all gui information
    % 
    % Output:          handles=structure, holds all gui information
    
    % Notes:    Sets all the callbacks - needs to be done after all of the
    %           controls are created otherwise the handles structure
    %           doesn't have all of the handles in it. These callbacks are
    %           for editing segmentations. For setting up new segmentations
    %           the alternative function defineSetUpCallbacks is used.          

    set(handles.cellnumBox,'Callback',{@cellnumber_callback, handles});
    set(handles.timepoint,'Callback',{@timepoint_callback, handles});
    set(handles.run,'Callback',{@run_callback, handles});
    set(handles.restoreDefaults,'Callback',{@restoreDefaults_callback, handles});
    set(handles.restoreInitial,'Callback',{@restoreInitial_callback, handles});
    set(handles.shuffle,'Callback',{@shuffle_callback, handles});
    set(handles.workflowList,'Callback',{@workflowList_callback, handles});
    set(handles.runcomplete,'Callback',{@runcomplete_callback, handles});
    set(handles.runNewSeg,'Callback',{@runNewSeg_callback, handles});
    set(handles.accept,'Callback',{@accept_callback, handles});
    set(handles.reject,'Callback',{@reject_callback, handles});
    set(handles.parameterBox(1),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterBox(2),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterBox(3),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterBox(4),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterBox(5),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterBox(6),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterBox(7),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterBox(8),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterBox(9),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(1),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(2),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(3),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(4),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(5),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(6),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(7),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(8),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(9),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterCall(1),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterCall(2),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterCall(3),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterCall(4),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterCall(5),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterCall(6),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterCall(7),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterCall(8),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterCall(9),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(1),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(2),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(3),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(4),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(5),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(6),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(7),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(8),'Callback',{@parameterBox_callback,handles});
    set(handles.parameterDrop(9),'Callback',{@parameterBox_callback,handles});
    
    
    set(handles.proceed,'Callback',{@proceed_callback,handles});
    set(handles.selectGraph,'Callback',{@selectgraph_callback,handles});
    set(handles.save,'Callback',{@save_callback,handles});
    set(handles.load,'Callback',{@load_callback,handles});
    set(handles.exportdata,'Callback',{@exportdata_callback,handles});
    set(handles.exportjpeg,'Callback',{@exportjpeg_callback,handles});
    set(handles.schedule,'Callback',{@schedule_callback,handles});
    set(handles.segmentsingle,'Callback',{@segmentOne_callback,handles});
    set(handles.extractdata,'Callback',{@extractData_callback,handles});
    set(handles.extractDataMethod,'Callback',{@extractDataMethod_callback,handles});
    set(handles.deletethis,'Callback',{@deleteThis_callback,handles});
    set(handles.deleteall,'Callback',{@deleteAll_callback,handles});
    set(handles.initialize,'Callback',{@initialize_callback,handles});
    set(handles.tpresultaxes.channelselect,'Callback',{@chSelect_callback,handles});
    set(handles.cellresultaxes.zoomslider,'Callback',{@cellZoom_callback,handles});
%    handles.zoomListener = addlistener(handles.cellresultaxes.zoomslider,'Value','PostSet',@(src,event, handles)cellZoom_callback(handles));

    
    
    %Callback for slider mouse release
    set(handles.tpresultaxes.slider,'Callback', {@tpslider_callback,handles});
    %Callback for slider drag
    handles.dragListener = addlistener(handles.tpresultaxes.slider,'Value','PostSet',@(src,event)tpsliderdrag_callback(handles));
    %Callback for mouse click on the graph
    set(handles.plot,'ButtonDownFcn',{@plotclick_callback});
    set(get(handles.plot,'Children'),'ButtonDownFcn',{@plotclick_callback});

    
    
    guidata(handles.gui,handles);

  


end