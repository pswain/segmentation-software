classdef Segmethods<MethodsSuperClass
    properties
         resultImage='Result';%The field of the input object to which the result will be written by the run method
    end
    methods (Abstract)
        oneCellObj=run(obj,oneCellObj);
        oneCellObj=initializeFields(obj, oneCellObj);
    end
    methods (Static)
        [success centroid]=testSuccess(result,minpixels,maxpixels)
        result=largestOnly(input);
    end
end