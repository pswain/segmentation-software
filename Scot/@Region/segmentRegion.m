function obj=segmentRegion(obj)
    % segmentregion --- attempts segmentation of a cell in each catchment basin of a region
    %
    % Synopsis:  obj = segmentregion (obj)
    %
    % Input:     obj = an object of a region class
    %            Timelapse = an object of the Timelapse class
    %            
    % Output:    obj = an object of a region class

    % Notes:     Attempts segmentation in each catchment basin. Populates
    %            obj.Result and obj.TrackingData. Display line should be
    %            commented for faster execution.
    if max(obj.Watershed(:))>1%the region has been split by the watershed
        obj.Result=false(size(obj.Target,1),size(obj.Target,2),obj.NumBasins);%initialise result stack - initially one slice for each catchment basin
        numCells=0;
        for n=1:obj.NumBasins%loop through the catchment basins
            disp(strcat('catchment',num2str(n)));%comment for speed
            newCell=OneCell3(obj,n);
            %Following code may be redundant for initial segmentations if we are writing data directly to timelapse object from onecell3 class.
            if newCell.Success==1
                numCells=numCells+1;
                obj.Result(:,:, numCells)=newCell.Result;%writes the result image to the plane determined by numCells (will be the trackingnumber of this cell)
                %record the segmentation information in the trackingdata structure
                obj.TrackingData.cells(numCells).cellnumber=0;%cell is not yet tracked - cellnumber of zero reflects that
                obj.TrackingData.cells(numCells).trackingnumber=numCells;%a unique number for each cell in the region. Helps identify the cell when tracked.
                obj.TrackingData.cells(numCells).method=newCell.Method;%the method that succeeded in segmenting this cell
                obj.TrackingData.cells(numCells).catchmentbasin=n;
                obj.TrackingData.cells(numCells).disksize=2;%the default size used in segmentation
                obj.TrackingData.cells(numCells).erodetarget=.5;%this is a fudge - rewrite onecell to record a 'method' property that can be stored instead of these details
                obj.TrackingData.cells(numCells).centroidx=newCell.CentroidX;
                obj.TrackingData.cells(numCells).centroidy=newCell.CentroidY;
                obj.TrackingData.cells(numCells).region=[obj.TopLeftx obj.TopLefty obj.xLength obj.yLength obj.Depth];
                obj.TrackingData.cells(numCells).contours=obj.Defaults.contours;
                if newCell.Method==7
                    obj.TrackingData.cells(numCells).deleteoutermethod=1;
                else
                    obj.TrackingData.cells(numCells).deleteoutermethod=0;
                end
            end            
        end
        obj.Result(:,:,numCells+1:end)=[];%remove empty slices (where segmentation has failed)
    else%there is only one cell in this region. Has not been split.
        newCell=OneCell3(obj,0);
        %Following code is redundant for initial segmentations if we are writing data directly to timelapse object from onecell3 class.
        if newCell.Success==1
            obj.Result=newCell.Result;
            %record the segmentation information in the trackingdata structure
            obj.TrackingData.cells(1).cellnumber=0;%cell is not yet tracked - cellnumber of zero reflects that
            obj.TrackingData.cells(1).trackingnumber=1;%there is only one cell in the region so the trackingnumber is 1.
            obj.TrackingData.cells(1).method=newCell.Method;%the method that succeeded in segmenting this cell
            obj.TrackingData.cells(1).catchmentbasin=[];
            obj.TrackingData.cells(1).disksize=2;%the default size used in segmentation
            obj.TrackingData.cells(1).erodetarget=.5;
            obj.TrackingData.cells(1).centroidx=newCell.CentroidX;
            obj.TrackingData.cells(1).centroidy=newCell.CentroidY;
            obj.TrackingData.cells(1).region=[obj.TopLeftx obj.TopLefty obj.xLength obj.yLength obj.Depth];
            obj.TrackingData.cells(1).contours=obj.Defaults.contours;
            obj.TrackingData.cells(1).deleteoutermethod=0;
            obj.TrackingData.cells(1).contours=obj.Defaults.contours;
        end
    end
end