function TrapPixels = makeTrapPixelsFromBinaryFunction(TrapPixels,varargin)

%function to make the trap pixel image (the gray scale image in which each
%pixel is assigned a 'trappiness' given that binary image of trap pixels,
%taken from cellVisionModel, has been found.

if nargin>1 && ~isempty(varargin{1})
    uncertainty_in_edge = varargin{1};
else
    uncertainty_in_edge = 2; %parameters used in finding trap_px_cert. 
                         %Broadly the number of pixels from the edge of the
end                   %'certain' (trap_px = 1) region at which pixels
                         %start to be given very high scores as
                         %trap_px_cert pixels.

                         
if nargin>1 && ~isempty(varargin{2})
    gaussian_h_size = varargin{2};
else
    gaussian_h_size = 3; 
end

if nargin>1 && ~isempty(varargin{3})
    gaussian_sd = varargin{3};
else
    gaussian_sd = 0.5; 
end
                  
%gaussian for smoothing hough accumulator
smoothing_gauss =fspecial('gaussian',gaussian_h_size,gaussian_sd);

TrapPixels = sum(TrapPixels,3);

TrapPixelsCert = bwdist(TrapPixels~=1)-uncertainty_in_edge;
% TrapPixelsCert(TrapPixelsCert<=0)=0;
% TrapPixelsCert(TrapPixelsCert>0) = 1;

TrapPixels = conv2(TrapPixels,smoothing_gauss,'same');

TrapPixels(TrapPixelsCert>0) = 1;

end