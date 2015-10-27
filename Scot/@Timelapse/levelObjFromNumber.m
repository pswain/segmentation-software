function levelObj=levelObjFromNumber(obj, number)
    % levelObjFromNumber ---  returns the level object saved in obj.LevelObjects having the input ObjectNumber
    %
    % Synopsis:        levelObj = levelObjFromNumber(obj, number)
    %
    % Input:           obj = an object of a Timelapse class.
    %                  number = integer, ObjectNumber of the required level object.
    %
    % Output:          method = an object of a method class (subclass of MethodsSuperClass)
    
    % Notes:
    index=find(obj.LevelObjects.ObjectNumber==number);
    levelObj=[];
    if ~isempty(index)        
        switch obj.LevelObjects.Type{index}
            case 'Timelapse'
                levelObj=obj;
            case 'Timepoint'
                levelObj=Timepoint2(obj, index);
            case 'Region'
                levelObj=Region2(obj, index);
            case 'OneCell'
                levelObj=OneCell2(obj, index);
        end
    end    
end