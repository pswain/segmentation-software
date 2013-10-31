classdef SplitRegionSuperClass <MethodsSuperClass
    properties
         resultImage='RequiredImages.Watershed';
    end
    methods (Abstract)
        regionObj=run(obj,regionObj);
        regionObj=initializeFields(obj, regionObj, timepointObj); 
    end
    methods 
        
    end
end