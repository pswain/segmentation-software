function TrapPixels = makeTrapPixelsFromBinaryFunction(TrapPixels)

%function to make the trap pixel image (the gray scale image in which each
%pixel is assigned a 'trappiness' given that binary image of trap pixels,
%taken from cellVisionModel, has been found.

uncertainty_in_edge = 2; %parameters used in finding trap_px_cert. 
                         %Broadly the number of pixels from the edge of the
                         %'certain' (trap_px = 1) region at which pixels
                         %start to be given very high scores as
                         %trap_px_cert pixels.

%gaussian for smoothing hough accumulator
smoothing_gauss =fspecial('gaussian',3,0.5);

TrapPixels = sum(TrapPixels,3);

TrapPixelsCert = bwdist(TrapPixels~=1)-uncertainty_in_edge;
TrapPixelsCert(TrapPixelsCert<0)=0;

TrapPixels = conv2(TrapPixels,smoothing_gauss,'same');

TrapPixels = TrapPixels+TrapPixelsCert;

end