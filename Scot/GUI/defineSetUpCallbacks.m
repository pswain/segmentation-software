function handles=defineSetUpCallbacks(handles)
    % defineSetUpCallbacks ---  defines GUI callbacks for initializing new segmentations
    %
    % Synopsis:        handles=defineSetupCallbacks(handles)
    %
    % Input:           handles=structure, holds all gui information
    % 
    % Output:          handles=structure, holds all gui information
    
    % Notes:    Sets all the callbacks - needs to be done after all of the
    %           controls are created otherwise the handles structure
    %           doesn't have all of the handles in it. These callbacks are
    %           for setting up new segmentations. For editing segmentations
    %           the alternative function defineCallbacks is used.
    %           
%    set(handles.packageMenu,'Callback',{@packageMenu_callback,handles});
 %   set(handles.methodsMenu,'Callback',{@methodsMenu_callback, handles});
    set(handles.cellnumBox,'Callback',{@cellnumber_callback, handles});
    set(handles.timepoint,'Callback',{@timepoint_callback, handles});
    set(handles.run,'Callback',{@run_callback, handles});
    set(handles.restoreDefaults,'Callback',{@restoreDefaults_callback, handles});
    set(handles.restoreInitial,'Callback',{@restoreInitial_callback, handles});
    set(handles.shuffle,'Callback',{@shuffle_callback, handles});
    set(handles.workflowList,'Callback',{@workflowList_callback, handles});
    set(handles.runcomplete,'Callback',{@runNewSeg_callback, handles});
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
    set(handles.proceed,'Callback',{@proceed_callback,handles});
    set(handles.save,'Callback',{@save_callback,handles});
    set(handles.load,'Callback',{@load_callback,handles});
    set(handles.schedule,'Callback',{@schedule_callback,handles});
    set(handles.segmentsingle,'Callback',{@segmentOne_callback,handles});
    set(handles.runNewSeg,'Callback',{@runNewSeg_callback, handles});
    set(handles.initialize,'Callback',{@initialize_callback,handles});

    
    %Add listeners to sliders
    %hhSlider=handle(handles.tpresultaxes.slider);
    %hProp=findprop(hhSlider,'Value');
    %handles.listeners.tpslider = addlistener(handles.tpresultaxes.slider,'Value','PostSet',@(src,event)tpslider_callback(handles));
    
       
    %Callback for slider mouse release
    set(handles.tpresultaxes.slider,'Callback', {@tpslider_callback,handles});
    %Callback for slider drag
    handles.hListener = addlistener(handles.tpresultaxes.slider,'Value','PostSet',@(src,event)tpsliderdrag_callback(handles));

    
    guidata(handles.gui,handles);



end