function imageStack = none(imageStack,parameters,varargin)
%function image = none(imageStack,parameters,varargin)

%parameters.invert   -   boolean. Whether image should be inverted

%varargin{1} - image stack of trapiness of each pixel in the corresponding image in imageStack

%NOTES



for i=1:size(imageStack,3)

image = imageStack(:,:,i);
if size(varargin,2)>=1
    trap_px = varargin{1}(:,:,i);
end


if parameters.invert
        %invert the image
        image = max(image(:))-image;
    
end


if size(varargin,2)>=1
   MAXimage = max(abs(image(:)));
   %trap points between 0 and 1 scaled as per trapiness
   image = image+((median(image(:))-image).*mod(trap_px,1));
   %trap points greater than 1 (largely certain) set to max)
   image(trap_px>4) = MAXimage; 
   
   %just for easier image
   image(image>(2*MAXimage)) = 2*MAXimage;
   
   

end

imageStack(:,:,i) = image;

end

end



