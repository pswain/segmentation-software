function obj=edgesegment(obj)
    % edgesegment --- segments cells in the timepoint using edge-based methods
    %
    % Synopsis:  obj = edgesegment(obj) 
    %
    % Input:     obj = an object of a timepoint class
    %
    % Output:    obj = an object of a timepoint class

    % Notes:     Populates the Bin, Segmented and TrackingData fields.
    %            Segmentation is performed by the methods specified in obj.
    %            Defaults. Can speed up segmentation by commenting the
    %            display lines. With superclass handles can write to the
    %            timepoint (or timelapse) object directly from region or
    %            cell objects - could then omit parts of this code - will
    %            need a seperate method then for editing segmentations.
    %    
    %Define regions by creating obj.Bin
    obj=calculatebin(obj);
    obj.TrackingData.threshmethod=obj.ThreshMethod;
    %Get properties of the connected objects defined by obj.Bin
    STATS=regionprops(obj.Bin,'Area','BoundingBox', 'Solidity','Image');
    areas=vertcat(STATS.Area);
    objects=areas>=200;%objects smaller than this are not cells
    STATS(objects==0)=[];
    boxes=vertcat(STATS.BoundingBox);
    numObjects=size(boxes,1);
    obj.Segmented=false(size(obj.InputImage,2),size(obj.InputImage,1),500);%initialise a segmentation result image. Preallocation for speed - reduce size of this after the loop. Within loop - expand only if necessary.
    numCells=0;
    for n=1:numObjects%loop through the objects finding the pixels that represent cell interiors
        if n==45
            disp('debug here');
        end
        ulx=ceil(boxes(n,1));
        uly=ceil(boxes(n,2));%x and y coordinates of upper left corner of this object
        xlength=round(boxes(n,3));
        ylength=round(boxes(n,4));
        %create a region object using the bounding box just
        %defined. Use the new segmentation version of the region
        %constructor method. 
        disp(strcat('segmenting region',num2str(n)));%comment for speed
        region=Region3(obj,obj.Timelapse,[ulx uly xlength ylength]);
        %Write result to timepoint object fields. May remove this if
        %writing data direct to timelapse through handle subclasses.
        if isempty (region.TrackingData)==0%make sure there is at least 1 segmented cell in the region
            slices=size(region.TrackingData.cells,2);%the number of cells detected in this region
            if slices>size(obj.Segmented,3)%need to expand the preallocated array
                obj.Segmented(:,:,slices+size(obj.Segmented,3))=false;            
            end
            obj.Segmented(region.TopLefty:region.TopLefty+region.yLength-1,region.TopLeftx:region.TopLeftx+region.xLength-1,numCells+1:numCells+slices)...
            =region.Result;
            for cell=1:size(region.TrackingData.cells,2)
                obj.TrackingData.cells(cell+numCells)=region.TrackingData.cells(cell);
                obj.TrackingData.cells(cell+numCells).trackingnumber=cell+numCells;
            end
            numCells=numCells+size(region.TrackingData.cells,2);
        end
        imrgb(sum(obj.Segmented(:,:,:),3),obj.InputImage);drawnow;%comment for speed
    end
    %Reduce the size of obj.Segmented if it is larger than the number of
    %cells
    if size(obj.Segmented,3)>numCells
        obj.Segmented(:,:,numCells+1:end)=[];
    end
end
