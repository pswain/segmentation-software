function imageStack = tanh_of_another(imageStack,parameters,varargin)
%function image = tanh_of_another(imageStack,parameters,varargin)
%Intended to smooth out ferocious transforms by tanhing them to between -1
%amd 1
% parameters.other_function              -   name of the function to apply to the
%                                            image.
% parameters.other_function_parameters   -   parameters for the other
%                                            function.
% parameters.normalisation_method        -   string. normalisation to perform
%                                            either 'auto' or 'manual'
% parameters.normalisation_parameters    -   parameters for normalisation.
%                                            If the method is 'auto' these are [to_subtract to_divide] in units 
%                                            of standard deviation around the median.
%                                            If the method is 'manual' these are the raw [to_subtract to_divide] 
%
%
% varargin{1} - image stack of trapiness of each pixel in the corresponding image in imageStack
%
% NOTES
% trap processing applied after tanhing.



TransformFunctionHandle = str2func(['ACImageTransformations.' parameters.other_function]);
imageStack = TransformFunctionHandle(imageStack,parameters.other_function_parameters);

switch parameters.normalisation_method
    case 'manual'
        imageStack = imageStack - parameters.normalisation_parameters(1);
        imageStack = imageStack/parameters.normalisation_parameters(2);

    case 'auto'
        image_median = median(imageStack(:));
        image_iqr = std(imageStack(:));
        imageStack = imageStack - (image_median + image_iqr*parameters.normalisation_parameters(1));
        imageStack = imageStack/(image_iqr*parameters.normalisation_parameters(2));

end

imageStack = tanh(imageStack);

if size(varargin,2)>=1
    
    TrapRemovealFunctionHandle = str2func(['ACImageTransformations.' parameters.TrapHandleFunction]);
    
    imageStack = TrapRemovealFunctionHandle(imageStack,parameters.TrapHandleFunctionParameters,varargin{1});
    

end

end



