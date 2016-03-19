function imageStack = all_one_value(imageStack,parameters,varargin)
%function imageStack = all_ones(imageStack,parameters,varargin)
%
% converts images to all one value (useful in some instances)
%
% parameters.value     -    the value to which to set the imageStack too.

imageStack = parameters.value*ones(size(imageStack));

if size(varargin,2)>=1
    
    TrapRemovealFunctionHandle = str2func(['ACImageTransformations.' parameters.TrapHandleFunction]);
    
    imageStack = TrapRemovealFunctionHandle(imageStack,parameters.TrapHandleFunctionParameters,varargin{1});
    

end

end



