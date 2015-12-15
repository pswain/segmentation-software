function obj=saveLevelObject(obj,inputObj)
    % saveLevelObject ---  saves parameters from the input level object to the timelapse.LevelObjects array
    %
    % Synopsis:        obj=saveLevelObject(obj,inputObj)
    %
    % Input:           obj = an object of a Timelapse class.
    %                  inputObj = an object of a level class (Timepoint, Region or Cell)
    %
    % Output:          obj = an object of a Timelapse class.
    
    % Notes:           Copies properties from the input level object to the
    %                  Timelapse.LevelObjects property - a structure array
    %                  carrying the information required to reconstitute
    %                  the object.
    
    %All objects
    %LevelObjects.ObjectNumber
    %LevelObjects.Type - string - 'Timelapse', 'Timepoint', 'Region' or 'OneCell'
    %LevelObjects.RunMethod - object number of the run method
    %LevelObjects.SegMethod - object nubmer of the segmenation method
    %LevelObjects.Timelapse - object number of the Timelapse
    
    %All except Timelapse
    %LevelObjects.Frame - (not Timelapse objects) - frame number
    
    %Region and OneCell
    %LevelObjects.Position - coordinates of region bounding box
    
    %Region
    %LevelObjects.Timepoint - timepoint object number
       
    %OneCell
    %LevelObjects.Region - region object number
    %LevelObjects.TrackingNumber - (OneCell objects only) 0 for failed segmentation attempts
    %LevelObjects.CatchmentBasin - (OneCell objects only)
    
    obj.NumLevelObjects=obj.NumLevelObjects+1;
    %Find the lowest (preallocated) entry with a zero objectnumber
    nextIndex=find(obj.LevelObjects.ObjectNumber==0, 1, 'first');
    if isempty(nextIndex)
       %Should preallocate more space here
       nextIndex=size(obj.LevelObjects.ObjectNumber,2)+1;
    end
    
    %Properties for all level object types
    obj.LevelObjects.ObjectNumber(nextIndex)=inputObj.ObjectNumber;
    obj.LevelObjects.RunMethod(nextIndex)=inputObj.RunMethod.ObjectNumber;
    obj.LevelObjects.SegMethod(nextIndex)=inputObj.SegMethod.ObjectNumber;
    
    if isa (inputObj,'Timelapse')
        obj.LevelObjects.Type{nextIndex}='Timelapse';
        obj.LevelObjects.Timelapse(nextIndex)=inputObj.ObjectNumber;
        obj.LevelObjects.Frame(nextIndex)=0;
    else
        obj.LevelObjects.Timelapse(nextIndex)=inputObj.Timelapse.ObjectNumber;
        obj.LevelObjects.Frame(nextIndex)=obj.CurrentFrame;
        if ~isa(inputObj,'Timepoint')
            try
            obj.LevelObjects.Position(nextIndex,:)=[inputObj.TopLeftx inputObj.TopLefty inputObj.xLength inputObj.yLength];
            catch
                disp('debug point in saveLevelObject');
            end
            if isa(inputObj,'Region')
                obj.LevelObjects.Type{nextIndex}='Region';
                if ~isempty(inputObj.Timepoint)                    
                    obj.LevelObjects.Timepoint(nextIndex)=inputObj.Timepoint.ObjectNumber;
                end
                if ~isempty(inputObj.TrackingNumbers)
                numCells=size(inputObj.TrackingNumbers,2);
                obj.LevelObjects.TrackingNumbers(nextIndex,1:numCells)=inputObj.TrackingNumbers;
                end
            else%The input object is a OneCell object
                obj.LevelObjects.Type{nextIndex}='OneCell';
                obj.LevelObjects.TrackingNumber(nextIndex)=inputObj.TrackingNumber;
                obj.LevelObjects.CatchmentBasin(nextIndex)=inputObj.CatchmentBasin;
                try
                obj.LevelObjects.Centroid(nextIndex,:)=[inputObj.CentroidX inputObj.CentroidY];
                catch
                disp('debug point - save level object');    
                end
                if~isempty(inputObj.Region)
                    obj.LevelObjects.Region(nextIndex)=inputObj.Region.ObjectNumber;
                end
            end
        else
            obj.LevelObjects.Type{nextIndex}='Timepoint';
        end
    end
end