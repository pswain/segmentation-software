function TrapPixels = makeTrapPixelsFunction(TrapIm)

%function to make the trap pixel image (the gray scale image in which each
%pixel is assigned a 'trappiness' given that the trap image has been
%submitted.
%Largely taken from the make_trap_score_image function
%Uses CircularHough_Grd from the file exchange

minrad = 3;%min radius of circles for hough transform
maxrad = 10;%max radius of circles for hough transform
uncertainty_in_edge = 2; %parameters used in finding trap_px_cert. 
                         %Broadly the number of pixels from the edge of the
                         %'certain' (trap_px = 1) region at which pixels
                         %start to be given very high scores as
                         %trap_px_cert pixels.

centers = zeros(2,2);

%gaussian for smoothing hough accumulator
gauss = fspecial('gaussian',maxrad,1);
smoothing_gauss =fspecial('gaussian',3,0.5);

TrapIm = (TrapIm-min(TrapIm(:)));
TrapIm = TrapIm/max(TrapIm(:));

%% finding centers

[accum,~,~,~] = ACBackGroundFunctions.CircularHough_Grd(TrapIm,[minrad maxrad] , 0.1, 8, 1);

accum = conv2(accum,gauss,'same');

accum = accum.*imregionalmax(accum);

for i=1:2
    
    [centers(i,2),centers(i,1)] = find(accum == max(accum(:)));
    accum(centers(i,2),centers(i,1)) = accum(1,1)-1;
    
end


%% finding boundary

[TrapPixels,~,~,~] = ACMethods.segment_elco_fmc_radial_play(TrapIm,centers,TrapIm);

TrapPixels = sum(TrapPixels,3);

TrapPixelsCert = bwdist(TrapPixels~=1)-uncertainty_in_edge;

TrapPixels = conv2(TrapPixels,smoothing_gauss,'same');

TrapPixels = TrapPixels+TrapPixelsCert;

end