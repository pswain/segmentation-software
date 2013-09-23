function obj=clearFrame(obj,frame)
    % clearFrame --- Deletes all references to segmented cells in the input timelapse frame
    %
    % Synopsis:  obj = deleteFrame (obj)
    %                        
    % Input:     obj = an object of a Timelapse class
    %            frame = integer, the frame to clear
    %            
    %
    % Output:    obj = an object of a Timelapse class

    % Notes:     Called before segmentation of a single timepoint. Performs
    %            actions similar to the preallocate function but for a
    %            single frame.
       
    %Initialize a preallocated TrackingData entry for a single cell.
    initialcells=struct;
    initialcells.cellnumber=uint16(0);
    initialcells.trackingnumber=uint16(0);
    initialcells.methodobj(obj.RunMethod.numObjects)=uint16(0);
    initialcells.levelobj(obj.RunMethod.numObjects)=uint16(0);
    initialcells.centroidx=0;
    initialcells.centroidy=0;
    initialcells.region=[0 0 0 0];
    %Clear + preallocate trackingdata and result images   
    numCells=round(obj.RunMethod.numCells*1.5);
    if isempty(obj.Result)
        obj.Result=struct;
    end
    for n=1:numCells
       obj.TrackingData(frame).cells(n)=initialcells;
       obj.Result(frame).timepoints(n).slices=false(obj.ImageSize(2),obj.ImageSize(1));
    end
    %Now deal with the levelobjects arrays
    %Initialize preallocated data entries
    a=int16(0);
    type='Preallocated';   
    b=double([0 0 0 0]);
    c=int8(0);
       
    %Clear or preallocate
    if ~isempty(obj.LevelObjects)
        toClear=obj.LevelObjects.Frame==frame;
        numToClear=nnz(toClear);
        b=repmat(b,[numToClear 1]);
                
        obj.LevelObjects.ObjectNumber(toClear)=a;
        obj.LevelObjects.Type(toClear)={type};
        obj.LevelObjects.RunMethod(toClear)=a;
        obj.LevelObjects.SegMethod(toClear)=a;
        obj.LevelObjects.Timelapse(toClear)=a;
        obj.LevelObjects.Frame(toClear)=a;
        obj.LevelObjects.Position(toClear,:)=b;
        obj.LevelObjects.Timepoint(toClear)=a;
        obj.LevelObjects.Region(toClear)=a;
        obj.LevelObjects.TrackingNumber(toClear)=c;
        obj.LevelObjects.CatchmentBasin(toClear)=c;
        obj.LevelObjects.Centroid(toClear,:)=b(:,1:2); 
    else%obj.LevelObjects is not intialized - make a true vector to preallocate   
        a(1:numCells)=a;
        Type=cell(numCells,1);
        Type(:)={type};
        b=repmat(b,[numCells 1]);
        c(1:numCells)=c;
        obj.LevelObjects.ObjectNumber=a;
        obj.LevelObjects.Type=Type;
        obj.LevelObjects.RunMethod=a;
        obj.LevelObjects.SegMethod=a;
        obj.LevelObjects.Timelapse=a;
        obj.LevelObjects.Frame=a;
        obj.LevelObjects.Position=b;
        obj.LevelObjects.Timepoint=a;
        obj.LevelObjects.Region=a;
        obj.LevelObjects.TrackingNumber=c;
        obj.LevelObjects.CatchmentBasin=c;
        obj.LevelObjects.Centroid=b(:,1:2);
    end
   
    
     

end