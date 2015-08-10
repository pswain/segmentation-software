function methodObj=getSegMethod(levelObj)
    % getSegMethod --- returns the method object that was used in segmenting the input level object
    %
    % Synopsis:  methodObj = getSegMethod(levelObj)
    %
    % Input:     levelObj = an object of a level class (superclass LevelObject)
    %                                               
    % Output:    methodObj = an object of a method class (superclass MethodsSuperClass)

    % Notes:     This method is used to get the method object that
    %            was used to segment a given level object.
    frame=obj.Timelapse.CurrentFrame;
    for n=1:size(obj.Timelapse.TrackingData(frame).cells,2)
        levelObjects=[obj.Timelapse.TrackingData(frame).cells(n).methodobj.numbers];
        
        
    
    
    
    
    for n=1:size(obj.TrackingData(frame).cells(trackingnumber).methodobj,2)
        objectInfo=metaclass(obj.TrackingData(frame).cells(trackingnumber).methodobj(n).objects);
        if ~isempty(objectInfo.ContainingPackage)
            if strcmp(objectInfo.ContainingPackage.Name, type)==1
                returnObject=obj.TrackingData(frame).cells(trackingnumber).methodobj(n).objects;
            end
        end
        
    end
end