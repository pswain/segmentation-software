function imageStack = radial_gradient_DICangle_and_radialaddition(imageStack,parameters,varargin)
%function image = radial_gradient_DICangle_and_radialaddition(imageStack,parameters,varargin)

%parameters.DICangle    - then angle(in degrees) relative to the x axis
%                         (with clockwise positive) at which edges of the
%                         cell go dark to light
%parameters.Rdiff       - area behind point searched for maximum value to
%                         add to point
%parameters.anglediff   - angle of 'rear area searched'

%varargin{1} - image stack of trapiness of each pixel in the corresponding image in imageStack

%% general setting up
error_message = checkparams(parameters,'DICangle');
error_message = checkparams(parameters,'Rdiff');
error_message = checkparams(parameters,'anglediff');

image_length = (size(imageStack,1)-1)/2;%half the length of the image

%assumes center is at the center of the image
center = ceil(image_length+[1 1]);

xcoord = repmat(-image_length:image_length,(2*image_length +1),1);

ycoord = repmat((-image_length:image_length)',1,(2*image_length +1));

xcoord((image_length +1),(image_length +1)) = 1;

ycoord((image_length +1),(image_length +1)) = 1;

[R,angle] = ACBackGroundFunctions.xy_to_radial(xcoord(:),ycoord(:));

R = reshape(R,(2*image_length+1),(2*image_length+1));

angle = reshape(angle,(2*image_length+1),(2*image_length+1));

for i=1:size(imageStack,3)

image = imageStack(:,:,i);
if size(varargin,2)>=1
    trap_px = varargin{1}(:,:,i);
end


[ximg,yimg] = gradient(image);

%% radial gradient
image = -ximg.*cos(angle) -yimg.*sin(angle);

%% DIC angle part
image = image.*tanh((cos(angle-(parameters.DICangle*2*pi/360))));

%% radial addition. suppose to take advantage of the fact that the edge of the cell should go from bright white to very dark in the transformed image

image2 = image;


min_addition = min(image(:));

for pixel = 1:size(image,1)*size(image,2)

    image2(pixel) = image(pixel)-max([image((angle>(angle(pixel)-(parameters.anglediff))) & (angle<(angle(pixel)+(parameters.anglediff))) & R<R(pixel) & R>(R(pixel)-parameters.Rdiff)); min_addition]);

end

image = image2;

if size(varargin,2)>=1
   MAXimage = max(abs(image(:)));
   image = image+((median(image(:))-image).*trap_px);
   image(trap_px>3) = MAXimage; 
   
   %just for easier image
   image(image>(2*MAXimage)) = 2*MAXimage;
   
   

end

imageStack(:,:,i) = image;

end
end


function error_message = checkparams(parameters,field)

if ~isfield(parameters,field)
error_message = [field ' must be a parameter of this function'];
error(['incorrect parameters passed to radial_gradient_DICangle_and_radialaddition.' field ' must be a parameter'])
end

if ~isnumeric(parameters.(field))
error_message = [field ' must be numeric'];
error(['incorrect parameters passed to radial_gradient_DICangle_and_radialaddition. ' field ' must be a single number'])
end

if any(~size((parameters.(field))==[1 1]))
error_message = [field ' must be a single number'];
error(['incorrect parameters passed to radial_gradient_DICangle_and_radialaddition. ' field ' must be a single number'])
end

error_message = [];
end



