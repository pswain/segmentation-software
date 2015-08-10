function timepointObj=getTimepoint(obj, frame)
        % getTimepoint --- Returns the stored timepoint object corresponding to the input frame from a segmented timelapse
        %
        % Synopsis:  timepointObj = getTimepoint(obj, frame)   
        %                        
        % Input:     obj = an object of a timelapse class
        %            frame = integer, the frame for which the timepoint object is required
        %
        % Output:    timepointObj = an object of class Timepoint2
        
        % Notes: This method is used to recover a Timepoint object for a
        %        given frame.

        thisFrame=obj.LevelObjects.Frame==frame;%Logical index to all level object details stored for this frame
        tps=strcmp(obj.LevelObjects.Type,'Timepoint');
        thisTp=thisFrame'&tps;
        objNumber=obj.LevelObjects.ObjectNumber(thisTp);
        timepointObj=obj.levelObjFromNumber(objNumber(1));
        %If no timepoint was found, create one using the Timepoint4
        %constructor
        if isempty(timepointObj)
            timepointObj=Timepoint4(obj, frame);
        end
        
end