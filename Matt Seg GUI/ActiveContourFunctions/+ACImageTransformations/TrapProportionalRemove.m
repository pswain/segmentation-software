function imageStack = TrapProportionalRemove(imageStack,parameters,varargin)
%imageStack = %TrapProportionalRemove(imageStack,TrapStack,parameters,varargin)     
%sets trap pixels to be high in proportion to their trap pixel ness. Sets
%the valuefor each pixel using a linear scale between the median of the
%image and the pixels own value with the position along the scale set by
%the trap pixel value. So trap pixel values should be 1 or higher for
%certain pixels and less than one for uncertain pixels. the only parameter
%is MaxThresh which is a value for pixelyness above which the pixel value
%is set to 2*max pixel value in image. default is 0.8.
%actual value

%parameters:

%MaxThresh = the threshold value above which 

if size(varargin,2)>0
    
    TrapStack = varargin{1};

if ~exist('parameters','var') || ~isfield(parameters,'MaxThresh')
    MaxThresh = 0.8;
else
    MaxThresh = parameters.MaxThresh;
end
    

for i=1:size(imageStack,3)
    
    image = imageStack(:,:,i);

        trap_px = TrapStack(:,:,i);

 

   MAXimage = max(abs(image(:)));
   %trap points between 0 and 1 scaled as per trapiness
   image = image+((median(image(:))-image).*mod(trap_px,1));
   %trap points greater than 1 (largely certain) set to max)
   image(trap_px>MaxThresh) = 2*MAXimage; 
   
   %just for easier image
   image(image>(2*MAXimage)) = 2*MAXimage;
   
   
   imageStack(:,:,i) = image;
    
   
end

end

end