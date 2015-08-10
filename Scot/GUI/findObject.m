function [obj] = findObject (timelapseObj, objectNumber, objectArray)
    % findObjects ---  Searches an input structure array of level objects for any that match the input objectnumber
    %
    % Synopsis:        obj = findObjects(timelapseObj, objectNumber, objectArray)
    %
    % Input:           timelapseObj = an object of a Timelapse class
    %                  objectNumber = integer, ObjectNumber of the required level object
    %                  objectArray = structure, has a field, .objects containing the level objects to be searched
    %
    % Output:          obj = an object of a level class
    
    % Notes:    Returns a level object corresponding to the input object
    %           number. 
    %           This should be called instead of
    %           timelapseObj.LevelObjFromNumber where arrays of level
    %           objects are already present (ie when you have
    %           handles.levelObjects in the GUI). It searches
    %           the input objectArray structure for any objects with the
    %           input object number. For OneCell and Region objects it
    %           also searches for objects that might be contained in the
    %           OneCell.Region or Region.Timepoint fields. This function
    %           avoids recreating many objects with the same object numbers
    %           by multiple calls to timelapse.levelObjFromNumber and
    %           having to initialize the fields of each one when they
    %           are used.
    if objectNumber==0
        obj=[];
        return
    end
     
    obj=[];
    m=1;
    found=false;
    while found==false && m<=size(objectArray,2)
        if ~isempty(objectArray(m).objects)                            
            if objectArray(m).objects.ObjectNumber==objectNumber;
                obj=objectArray(m).objects;
                found=true;
            elseif isa(objectArray(m).objects,'OneCell')
                if ~isempty(objectArray(m).objects.Region)
                    if objectArray(m).objects.Region.ObjectNumber==objectNumber;
                        obj=objectArray(m).objects.Region.ObjectNumber;
                        found=true;
                    end
                end
            elseif isa(objectArray(m).objects,'Region')
                if ~isempty(objectArray(m).objects.Timepoint)
                    if objectArray(m).objects.Timepoint.ObjectNumber==objectNumber;
                        obj=objectArray(m).objects.Timepoint.ObjectNumber;
                        found=true;
                    end
                end
            end                            
        end
        m=m+1;
    end
  
    
    
    if ~found
        %No stored object has been found in the input array. Look for one
        %in the timelapse object.
        obj=timelapseObj.levelObjFromNumber(objectNumber);
    end
     
    %Now call this function to get or create any objects that might be part of the
    %objects that have been obtained already.    
    if isa (obj, 'Region')
       if ~isempty (obj.Timepoint)
           if isa(obj.Timepoint,'Timepoint')
               objectNumber=obj.Timepoint.ObjectNumber;
           else%The timepoint has been stored only as its object number
               objectNumber=obj.Timepoint;
           end
           [obj2] = findObject (timelapseObj, objectNumber, objectArray);
           obj.Timepoint=obj2;
       end

    elseif isa (obj, 'OneCell')
        if ~isempty (obj.Region)
           if isa(obj.Region,'Region')
               objectNumber=obj.Region.ObjectNumber;
           else%The timepoint has been stored only as its object number
               objectNumber=obj.Region;
           end
           [obj2] = findObject (timelapseObj, objectNumber, objectArray);
           obj.Region=obj2;
        end
    end  
end