function [TrapPixels] = makeTrapPixelsFunction(TrapPixelsLogical)


uncertainty_in_edge = 2; %parameters used in finding trap_px_cert. 
                         %Broadly the number of pixels from the edge of the
                         %'certain' (trap_px = 1) region at which pixels
                         %start to be given very high scores as
                         %trap_px_cert pixels.
smoothing_gauss = fspecial('gaussian',5,1);

TrapPixels = TrapPixelsLogical;

TrapPixelsCert = (bwdist(TrapPixels~=1)-uncertainty_in_edge) > 0;

%TrapPixels = imdilate(TrapPixels,strel('disk',1),'same');

TrapPixels = conv2(1*TrapPixels,smoothing_gauss,'same');

TrapPixels(TrapPixelsCert>0) = 1;

end