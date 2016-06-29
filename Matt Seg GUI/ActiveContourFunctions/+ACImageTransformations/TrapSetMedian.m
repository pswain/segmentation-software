function imageStack = TrapSetMedian(imageStack,parameters,varargin)
%imageStack = %TrapSetMedian(imageStack,TrapStack,parameters,varargin) sets
%trap pixels to be high for certain pixels and a fixed value for uncertain
%ones (the median of the image). Two parameters: 
%   MaxThresh which is a value for pixelyness above which the pixel value is
%             set to 2*max pixel value in image. default is 0.8. actual value
%   MedThresh trap pixel value above which to set the pixel to the median
%             of the image.
%parameters:

%MaxThresh = the threshold value above which 

if size(varargin,2)>0
    
    TrapStack = varargin{1};

if ~exist('parameters','var') || ~isfield(parameters,'MaxThresh')
    MaxThresh = 0.8;
else
    MaxThresh = parameters.MaxThresh;
end

if ~exist('parameters','var') || ~isfield(parameters,'MaxThresh')
    MedThresh = 0.4;
else
    MedThresh = parameters.MedThresh;
end
    
    

for i=1:size(imageStack,3)
    
    image = imageStack(:,:,i);

        trap_px = TrapStack(:,:,i);

 

   MAXimage = max(abs(image(:)));
   MEDimage = median(image(:));
   
   %trap points greater than MedThresh set to median
   image(trap_px>MedThresh) = MEDimage; 
   %trap points greater than 1 (largely certain) set to max)
   image(trap_px>MaxThresh) = 2*MAXimage; 

   imageStack(:,:,i) = image;
    
   
end

end

end