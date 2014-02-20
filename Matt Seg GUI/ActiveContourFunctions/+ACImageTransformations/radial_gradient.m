function imageStack = radial_gradient(imageStack,parameters,varargin)
%function image = radial_gradient_DICangle_and_radialaddition(imageStack,parameters,varargin)

%parameters.invert    - whether to invert the final cost function image or
%                       not (before adding trappiness)

%varargin{1} - image stack of trapiness of each pixel in the corresponding image in imageStack

%NOTES

%With 'invert' false this transformation will give low scores for pixels at
%which radial change in intensity is positive (from black to white) 
%With'invert' true it will give low scores for pixels at which radial change in
%intensity is negative (from white to black)

%% general setting up

image_length = (size(imageStack,1)-1)/2;%half the length of the image

xcoord = repmat(-image_length:image_length,(2*image_length +1),1);

ycoord = repmat((-image_length:image_length)',1,(2*image_length +1));

xcoord((image_length +1),(image_length +1)) = 1;

ycoord((image_length +1),(image_length +1)) = 1;

[R,angle] = ACBackGroundFunctions.xy_to_radial(xcoord(:),ycoord(:));

R = reshape(R,(2*image_length+1),(2*image_length+1));

angle = reshape(angle,(2*image_length+1),(2*image_length+1));

for i=1:size(imageStack,3)

image = imageStack(:,:,i);

[ximg,yimg] = gradient(image);

%% radial gradient
image = -ximg.*cos(angle) -yimg.*sin(angle);

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
% checkparams - nobody got time for that.
% 
% function error_message = checkparams(parameters)
% 
% if ~islogical(parameters,'invert')
% error_message = [field ' must be a parameter of this function'];
% error(['incorrect parameters passed to radial_gradient_DICangle_and_radialaddition.' field ' must be a parameter'])
% end
% 
% if ~islogical(parameters.invert)
% error_message = ['invert must be logical'];
% error(['incorrect parameters passed to radial_gradient_DICangle_and_radialaddition. invert must be a single logical'])
% end
% 
% if any(~size((parameters.invert)==[1 1]))
% error_message = [field ' must be a single number'];
% error(['incorrect parameters passed to radial_gradient_DICangle_and_radialaddition. invert must be a single number'])
% end
% 
% error_message = [];
% end



