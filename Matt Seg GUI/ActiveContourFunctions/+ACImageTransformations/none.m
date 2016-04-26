function imageStack = none(imageStack,parameters,varargin)
%function image = none(imageStack,parameters,varargin)

%parameters.invert   -   boolean. Whether image should be inverted

%varargin{1} - image stack of trapiness of each pixel in the corresponding image in imageStack

%NOTES



for i=1:size(imageStack,3)
    
    image = imageStack(:,:,i);

    if isfield(parameters,'postprocessing')
        switch parameters.postprocessing
            case 'none'
                %do nothing
            case 'invert'
                %invert the image
                image = max(image(:))-image;
            case 'absolute'
                %take the absolute of the image
                image = abs(image - median(image(:)));
                image = max(image(:))-image;
            case 'absolute+'
                % negative of (absolute followed by addition of  half the original
                % image)
                image = abs(image - median(image(:))) + 0.5*(image - median(image(:)));
                image = max(image(:))-image;
            case 'absolute-'
                %absolute followed by subtraction of  half the original image
                image = abs(image - median(image(:))) - 0.5*(image - median(image(:)));
                image = max(image(:))-image;
        end
    end
    
    
    imageStack(:,:,i) = image;
    
end


if size(varargin,2)>=1
    
    TrapRemovealFunctionHandle = str2func(['ACImageTransformations.' parameters.TrapHandleFunction]);
    
    imageStack = TrapRemovealFunctionHandle(imageStack,parameters.TrapHandleFunctionParameters,varargin{1});
    

end

end



