function handles = changeCell(handles, cellnumber, frame)
    % changeCell --- updates GUI and handles structure after a change of cellnumber or frame
    %
    % Synopsis:  handles=changeCell (handles, cellnumber, frame)
    %
    % Input:     handles = structure carrying all the information used by the GUI
    %            cellnumber = integer, identifier of the new cell
    %            frame = integer, the new timepoint
    %
    % Output:    handles = structure carrying all the information used by the GUI

    % Notes:     In SetUp mode (pre-tracking), the cellnumber is actually
    %            the current trackingnumber. Sets the correct
    %            trackingnumber (depending on the mode). Then identifies
    %            whether or not the selected cell is segmented at the
    %            selected timepoint.
    
    %Update frame
    oldFrame=handles.timelapse.CurrentFrame;
    handles.timelapse.CurrentFrame=frame;
    %Generate tracking number - and if in 'SetUp' mode determine if the
    %timepoint or the tracking number has changed
    switch handles.mode
        case 'SetUp'
            %The input cellnumber represents the tracking number
            oldcellno=handles.trackingnumber;
            handles.trackingnumber=cellnumber;
            %Record what has changed - this is necessary for defining the
            %current object later
            %If the cell number has changed - delete the trackdata entry in
            %handles - no longer relevant
            if oldFrame==frame
                changed='trackingnumber';
                handles.trackdata=[];
            else
                changed='frame';
            end
            
        case 'Edit'
            %The input number is a true cellnumber - timelapse has been
            %tracked
            oldcellno=handles.cellnumber;%recorded to get the handle for deselecting the point in the graph if plotted
            oldtrackno=handles.trackingnumber;
            handles.cellnumber=cellnumber;
            trackNos=[handles.timelapse.TrackingData(frame).cells.trackingnumber];
            handles.trackingnumber=trackNos([handles.timelapse.TrackingData(frame).cells.cellnumber]==handles.cellnumber);  
            if isempty(handles.trackingnumber)
                handles.trackingnumber=0;
            end
            %Note: handles.trackingnumber may be zero if the cell was not
            %segmented at this timepoint.            
    end
    
    %Now - establish if the cell has been segmented and has not been
    %deleted
    segmented=false;
    if handles.trackingnumber>0
        if ~isempty(handles.timelapse.TrackingData)
            if size(handles.timelapse.TrackingData,2)>=handles.timelapse.CurrentFrame
                if handles.trackingnumber<=size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells,2);
                    if ~isempty (handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber))
                        if ~isnan (handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).cellnumber)
                            segmented=true;
                        end
                    end
                end
            end
        end
    end
    
    %Now define the current method and current and saved objects, set up
    %the workflow
    if segmented
        handles.currentMethod=getMethod(handles, handles.trackingnumber);
        handles.historySize=size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(1).methodobj,2);
        handles=setUpWorkflow(handles);
        handles.savedObj=handles.levelObjects(handles.Level).objects;
        handles.currentObj=handles.savedObj.copy;%the saved version of the current object
        %Create the target image, etc. of the current object
        handles.currentObj.initializeFields;
        handles.currentObj.Timelapse=handles.timelapse;%This is essential so that the temp timelapse gets altered when you run methods on the temporary object
        set(handles.initialize,'Enable','On');
        handles.region=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).region;           
    else %Cell has not been segmented
           
        %Need to identify the objects (if any were made) which attempted to
        %segment the cell at this timepoint. This will allow the current
        %object to be defined and the workflow to be established.

        %Initialize variables to take the object numbers to
        %initialize
        foundCellObject=0;
        foundRegionObject=0;
        if ~isempty(handles.timelapse.LevelObjects)
            types=[handles.timelapse.LevelObjects.Type];
        else
            types='';
        end
        
        %Define the 'trackdata' - entry in the TrackingData for a similar
        %cell that has been segmented - this is used to create the
        %handles.region and current object. When in 'Edit' mode this will
        %be based on the details from the nearest timepoint at which the
        %input cellnumber was segmented.
        switch handles.mode
            case 'Edit'        
                %Find the nearest timepoint at which this cell was segmented
                [nearestFrame trackdata]=handles.timelapse.findnearest(cellnumber,handles.timelapse.CurrentFrame);
            case 'SetUp'
                %In setup mode the input cellnumber is actually a tracking
                %number because the cells have not been tracked. In this
                %case we can use the details from the previously-selected
                %cell - if it has been segmented. But this only makes sense if the timepoint, not the
                %trackingnumber has changed.
                trackdata=[];%default value - for no trackdata found
                if strcmp(changed,'frame')
                    if ~isempty(handles.timelapse.TrackingData)
                        if size(handles.timelapse.TrackingData,2)>=oldFrame;
                            if oldcellno<=size(handles.timelapse.TrackingData(oldFrame).cells,2);
                                if ~isempty (handles.timelapse.TrackingData(oldFrame).cells(oldcellno).trackingnumber)
                                    trackdata=handles.timelapse.TrackingData(oldFrame).cells(oldcellno);
                                    nearestFrame=oldFrame;
                                    %record trackdata in handles - will
                                    %be used if there is a further
                                    %change in the frame, without
                                    %changing the trackingnumber. Need to
                                    %record the old frame too
                                    handles.trackdata=trackdata;
                                    handles.trackdata.frame=oldFrame;
                                end
                            end
                        end
                    end
                    %If no trackingdata entry has been found for the
                    %previously-selected frame - use the trackdata stored
                    %in handles
                    if isempty(trackdata)
                        trackdata=handles.trackdata;
                        if ~isempty(trackdata)
                            nearestFrame=handles.trackdata.frame;
                        end
                    end
                end
        end

        %If the cell number exists in the timelapse - ie if a
        %nearest timepoint has been found - or in setup mode if only the
        %frame has been changed
        if ~isempty(trackdata)
           %Determine if a cell was considered in this region - ie 
           %if any cell or region objects at this timepoint overlap
           %with with the centroid of the cell at the nearest
           %timepoint.
           thisFrame=handles.timelapse.LevelObjects.Frame==frame;%Logical index to all level object details stored for this frame
           positions=handles.timelapse.LevelObjects.Position(:,:);
           rightPosition=positions(:,1)<=trackdata.centroidx & positions(:,2)<=trackdata.centroidy & positions(:,3)+positions(:,1)>=trackdata.centroidx & positions(:,4)+positions(:,2)>=trackdata.centroidy;
           %The following line generates a logical index to the
           %objects that have regions that include the centroid of
           %the cell at the nearest timepoint at which it is
           %segmented.
           usableObjects=rightPosition&thisFrame';

           if any(usableObjects)
               %There are objects that can be used - that cover the
               %area in which the centroid occurs.

               %First attempt to identify a usable OneCell object
               objIndices=find(usableObjects);
               oneCellIndices=strcmp(types,'OneCell');%all one cell objects
               usableCells=oneCellIndices&usableObjects;%Cell objects at the right frame and with regions that include the centroid
               if any(usableCells)
                    %There is at least one saved OneCell object
                    %that considered a region including the nearest
                    %centroid position.

                    cellObjects=find(usableCells);
                    if size(cellObjects,1)>1
                        %There is more than one OneCell object. Need to
                        %identify which is the appropriate one to use. This
                        %will depend on the catchment basin. Use the centroid
                        %field to identify the closest, non-segmented OneCell
                        %object (if any)

                        notSegmented=handles.timelapse.LevelObjects.TrackingNumber==0;
                        candidates=notSegmented&usableCells';
                        if nnz(candidates>1)
                            centroids=handles.timelapse.LevelObjects.Centroid(candidates,:);
                            objNums=handles.timelapse.LevelObjects.ObjectNumber(candidates);
                            distsqd=([centroids(1)-trackdata.centroidx centroids(2)-trackdata.centroidy].^2);
                            distsqd=sum(distsqd);
                            [value index]=min(distsqd);
                            foundCellObject=objNums(index);
                        else
                            %There is only one OneCell object that failed to
                            %segment and whos region includes the centroid.

                            foundCellObject=handles.timelapse.LevelObjects.ObjectNumber(candidates);
                        end%The single OneCell object has been segmented - this cannot be the appropriate object to initialize

                    else
                        %There is only one OneCell object with a region that
                        %includes the centroid. Check that it failed to segment

                        if handles.timelapse.LevelObjects.trackingnumbers(objIndices(cellObjects))==0
                           %This is a failed segmentation - use this object to
                           %initialize currentObj and other handles variables.

                           foundCellObject=handles.timelapse.LevelObjects.ObjectNumber(objIndices(cellObjects));
                           %Otherwise - there are only segmented cell objects
                           %in the region that includes the centroid - leave
                           %foundCellObject as zero.
                        end
                    end                          
               end


               %Have now attempted to define a usable cell. This
               %can be used (if it exists) to set handles.region.
               if foundCellObject>0
                  logindex=handles.timelapse.LevelObjects.ObjectNumber==foundCellObject;
                  handles.region=handles.timelapse.LevelObjects.Position(logindex,:);
               else
                   %No usable cell object has been found - set handles.region
                   %based on a region object if a suitable one exists.

                   regionIndices=strcmp(types,'Region');%all region objects
                   usableRegions=regionIndices&usableObjects;%Region objects at the right frame and with regions that include the centroid
                   if any(usableRegions)
                       %There is at least one usable region object. If there
                       %are more than one then it is impossible to define which
                       %is the 'correct' one for the cell we're attempting to
                       %segment. Use the first.

                       regIndices=find(usableRegions);
                       handles.region=handles.timelapse.LevelObjects.Position(regIndices(1),:);                                    
                       foundRegionObject=handles.timelapse.LevelObjects.ObjectNumber(regIndices(1));
                   end
               end           

           else
               %There are no cells or regions that include the area defined by
               %the centroid. Define handles.region based on the information
               %from the nearest timepoint at which this cell was segmented.

               handles.region=trackdata.region;                         
           end

        else
            %No time point has been found at which the input cell number was
            %segmented (or we are in SetUp mode and the cellnumber has been
            %changed. Revert to previous entry in cell number box and exit
            %this function;

            showMessage(handles,'Entered cell number is not segmented in this dataset');
            set(handles.cellnumBox,'String',num2str(oldcellno));
            switch handles.mode
                case 'SetUp'
                    handles.trackingnumber=oldcellno;
                case 'Edit'
                    handles.cellnumber=oldcellno;
                    handles.trackingnumber=oldtrackno;                
            end
            return;
        end

        %Have defined handles.region.
        %Now define the current object.
        switch handles.workflowLevels{handles.Level}
            case {'OneCell', 'onecell'}
                if foundCellObject>1
                    handles.currentObj = findObject (handles.timelapse, foundCellObject, handles.levelObjects);
                else
                    %Create a new OneCell object based on the region
                    %information in handles.region
                    handles.currentObj = OneCell4 (handles.timelapse, frame, nearestFrame, trackdata.trackingnumber);
                end

            case {'Region', 'region'}
                if foundRegionObject==0
                   %If no region has yet been identified try to find one - this
                   %code is identical to the code above that looks for a region
                   %only if no cell object has been found

                   if any(usableObjects)
                       regionIndices=strcmp(types,'Region');%all region objects
                       usableRegions=regionIndices&usableObjects;%Region objects at the right frame and with regions that include the centroid
                       if any(usableRegions)
                           %There is at least one usable region object. If
                           %there are more than one then it is impossible to
                           %define which is the 'correct' one for the cell
                           %we're attempting to segment. Use the first.

                           regIndices=find(usableRegions);
                           handles.region=handles.timelapse.LevelObjects.Position(regIndices(1),:);                                    
                           foundRegionObject=handles.timelapse.LevelObjects.ObjectNumber(regIndices(1));
                       end
                   end
                end

                if foundRegionObject>0
                    handles.currentObj = findObject (handles.timelapse, foundRegionObject, handles.levelObjects);
                else
                    %No region has been found that incorporates the position of
                    %the centroid. Make a new region object using the Region4
                    %constructor.

                    handles.currentObj=Region4(handles.timelapse, frame, trackdata.trackingnumber, nearestFrame);
                end

            case {'Timepoint','timepoint'}
                %Try to identify a Timepoint object that represents the current
                %frame.

                timepointIndices=strcmp(types,'Timepoint');%all timepoint objects
                possTimepoints=find(timepointIndices&thisFrame');%Index(ices) to timepoint objects that represent the current frame
                %No way to distinguish between timepoint objects if there is
                %more than one so just use the first.
                if ~isempty(possTimepoints)
                    handles.currentObj=findObject(handles.timelapse, possTimepoints(1), handles.levelObjects);
                    %If the required timepoint object isn't in the
                    %handles.levelObjects array - use levelObjFromNumber to get it
                    %from the timelapse data.
                    if isempty(handles.currentObj)
                       handles.currentObj=handles.timelapse.levelObjFromNumber(handles.timelapse.LevelObjects.ObjectNumber(possTimepoints(1))); 
                    end
                else
                    %No timepoint object corresponding to the current frame
                    %has been found. Create one using the Timepoint4
                    %constructor
                    handles.currentObj=Timepoint4(handles.timelapse,frame);
                end
                

            case {'Timelapse','timelapse'}
                handles.currentObj=handles.timelapse;

        end

        %Now need to initialize the created object. First check if it has a
        %Region or Timepoint field defined as an object or if that property
        %is just an object number.

        if isa(handles.currentObj,'OneCell')
            if ~isa (handles.currentObj.Region,'Region')
               handles.currentObj.Region=findObject(handles.currentObj.Region, handles.levelObjects);
               %This region may in turn not have its timepoint field property
               %initalized
               if ~isa(handles.currentObj.Region.Timepoint, 'Timepoint')
                    handles.currentObj.Region.Timepoint=findObject(handles.currentObj.Region.Timepoint, handles.levelObjects);
               end
            end

        elseif isa(handles.currentObj,'Region')
            if ~isa(handles.currentObj.Timepoint, 'Timepoint')
                handles.currentObj.Timepoint=findObject(handles.currentObj.Timepoint, handles.levelObjects);
            end
        end

        if ~isa(handles.currentObj,'Timelapse')
            handles.savedObj=handles.currentObj.copy;%the stored version of the current object
            handles.savedObj.Timelapse=handles.timelapse;
        end

        %Now define the correct workflow for the new object. As the current
        %cell has not been segmented this is done using setUpNewWorkflow, 
        %rather than setUpWorkflow.
        packageName=handles.currentMethod.Info.ContainingPackage.Name;
        className=handles.currentMethod.Info.Name;
        k=strfind(className,'.');
        className=className(k+1:end);
        if length(handles.workflowTree)>handles.Level
        callingObjIndex=handles.workflowTree(handles.Level).callingObjIndex;
        usedClassIndex=handles.workflowTree(handles.Level).usedClassIndex;       
        handles=followWorkflow(handles, packageName, className, callingObjIndex, usedClassIndex);
        end
    end
    
    
    
    
    
    
    
    
    
    

            
    
    %Handles variables are now updated.
    
    %Move the timepoint slider to the correct position    
    guidata(handles.gui, handles);
    set(handles.tpresultaxes.slider,'Value',handles.timelapse.CurrentFrame);
    
    %Redefine the min of the zoom slider - depends on
    %handles.region
    xZoom=handles.region(3)/handles.timelapse.ImageSize(1);
    yZoom=handles.region(4)/handles.timelapse.ImageSize(2);
    maxValue=min(xZoom,yZoom);
    set(handles.cellresultaxes.zoomslider,'Min',maxValue,'Value',maxValue);
    
    
    
    
    %Update the highlighting of the currently-selected cell in the data
    %graph - only if an extractdata method has been run.
    
    if handles.currentDataField ~=0
        oldcellhandle=handles.cellhandles(oldcellno);
        switch handles.plottype
            case 'Scatter'
                %Dehighlight the old line
                if ishandle(oldcellhandle)
                    set(oldcellhandle,'Marker','.', 'MarkerSize',6, 'LineWidth', 0.5);
                end
                %Highlight the line of the newly-selected cell
                set(handles.cellhandles(handles.cellnumber),'Marker','x', 'MarkerSize',10, 'LineWidth', 3);
                %Highlight the new cell point
                data=handles.timelapse.Data.(handles.currentDataField);
                data(data==0)=nan;
                interval=handles.timelapse.Interval;%Make this more sophisticated - to allow plotting of data with skipped timepoints
                x=0:interval:interval*(size(data,2)-1);
                thisx=x(handles.timelapse.CurrentFrame);
                thisy=data(handles.cellnumber,handles.timelapse.CurrentFrame);
                if ~isnan(thisy)
                    axes(handles.plot);
                    if ishandle(handles.currentPoint)
                        %Delete the old point - will be replaced
                        delete(handles.currentPoint);
                    end            
                    handles.currentPoint=plot(thisx,thisy, 'Marker','o', 'MarkerSize', 15,'LineWidth',4,'color',[0 0 0]);
                else
                    if ishandle(handles.currentPoint)
                        set(handles.currentPoint,'Visible','Off');%Retain the handle to the old point - this avoids an error when you try to delete it next time a valid current point is plotted
                    end
                end
            case 'Histogram'
                axes(handles.plot);
                if ishandle(handles.currentPoint)
                    %Delete the old point - will be replaced
                    delete(handles.currentPoint);
                end
                data=handles.timelapse.Data.(handles.currentDataField);
                [data cellnumbers]=sort(data);
                index=cellnumbers==cellnumber;
                thisx=find(index);
                thisy=data(index);
                handles.currentPoint=plot(thisx,thisy, 'Marker','o', 'MarkerSize', 15,'LineWidth',4,'color',[0 0 0]);               
                
        end
    end
    %Activate the button for running the initialize fields method
    set(handles.initialize,'Enable','On');
    %Change the numbers in the cell number and timepoint boxes
    set (handles.cellnumBox,'String',num2str(cellnumber));
    set (handles.timepoint,'String',num2str(frame));
    %Update image display
    handles=displayImages(handles);
                       
end
                  
       
