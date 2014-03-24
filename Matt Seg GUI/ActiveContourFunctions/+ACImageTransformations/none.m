function imageStack = none(imageStack,parameters,varargin)
%function image = none(imageStack,parameters,varargin)

%parameters.invert   -   boolean. Whether image should be inverted

%varargin{1} - image stack of trapiness of each pixel in the corresponding image in imageStack

%NOTES



for i=1:size(imageStack,3)
    
    image = imageStack(:,:,i);

    if parameters.invert
        %invert the image
        image = max(image(:))-image;
        
    end
    
    
    imageStack(:,:,i) = image;
    
end


if size(varargin,2)>=1
    
    TrapRemovealFunctionHandle = str2func(['ACImageTransformations.' parameters.TrapHandleFunction]);
    
    imageStack = TrapRemovealFunctionHandle(imageStack,parameters.TrapHandleFunctionParameters,varargin{1});
    

end

end



