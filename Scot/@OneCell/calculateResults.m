function obj=calculateResults(obj,regionObj)
    % calculateResults --- attempts segmentation using a single, defined method
    %
    % Synopsis:  obj = calculateResults (obj, regionObj))
    %                        
    % Input:     obj = an object of a OneCell class
    %            regionObj = an object of a Region class
    %
    % Output:    obj= an object of a OneCell class

    % Notes:     For use during editing of segmentation. To see the effect
    %            of running a single segmentation method. The method used
    %            is defined in the string obj.Method.    The alternative
    %            method - segmentCell will run through a range of methods
    %            in a defined order until one works.
    
    obj.Success=0;
    classString=['cellsegmethods.' char(obj.Method)];%create name of the method class
    constrFunc=str2func(classString);%create a function handle to the class constructor
    method=constrFunc();%create an object of the method class - this will populate the requiredFields property
    obj.initialiseFields(method,regionObj);%populate the required fields of the OneCell object
    if any (ismember(method.requiredFields, 'Region'))
        obj.Result=method.run(obj,regionObj);
    else
        obj.Result=method.run(obj);
    end      
    obj.Success=method.testSuccess(obj.Result);    
    obj.FullSizeResult=false(obj.ImageSize);
    obj.FullSizeResult(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1)=obj.Result;              
 end
