
function [obj history] = preallocate (obj)
    
    showMessage('Preallocating memory for timelapse segmentation...');
    %set default numbers of objects and cells
    numObjects=obj.RunMethod.numObjects;%(over)estimate of the number of method objects used in segmentation of each cell
    numcells=obj.RunMethod.numCells*1.5;%estimate of the number of cells per timepoint    
    %Redefine these if data exists 
    if ~isempty(obj.TrackingData)%No cell has yet been segmented
        if ~isempty(obj.TrackingData(obj.CurrentFrame).cells)
            numObjects=size(obj.TrackingData(obj.CurrentFrame).cells(1).methodobj,2)*2;%when expanding the history - make the preallocation twice the size
            numcells=size(obj.TrackingData(obj.CurrentFrame).cells,2);          
        end
    end
    initialcells=struct;
    initialcells.cellnumber=uint16(0);
    initialcells.trackingnumber=uint16(0);
    initialcells.methodobj(numObjects)=uint16(0);
    initialcells.levelobj(numObjects)=uint16(0);
    history=struct;
    history.methodobj=initialcells.methodobj;
    history.levelobj=initialcells.levelobj;
    initialcells.centroidx=0;
    initialcells.centroidy=0;
    initialcells.region=[0 0 0 0];
    initialcells.segobject=uint16(0);

    obj.Result=struct;
    obj.TrackingData=struct;
    for t=1:obj.TimePoints
        for n=1:numcells
           obj.TrackingData(t).cells(n)=initialcells;
           obj.Result(t).timepoints(n).slices=sparse(false(obj.ImageSize(2),obj.ImageSize(1)));
        end
    end
    tic
    numLevelObjects=obj.TimePoints * obj.RunMethod.numObjects;
    a=int16(0);
    a(1:numLevelObjects)=a;
    type='Preallocated';
    Type=cell(numLevelObjects,1);
    Type(:)={type};
    b=double([0 0 0 0]);
    b=repmat(b,[numLevelObjects 1]);
    c=int8(0);
    c(1:numLevelObjects)=c;
    obj.LevelObjects=[];
    obj.NumLevelObjects=0;
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
    showMessage(['Preallocation took ' num2str(toc) ' s']);

end