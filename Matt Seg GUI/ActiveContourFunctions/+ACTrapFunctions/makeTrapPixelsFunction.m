function [TrapPixels,TrapPixelLogical] = makeTrapPixelsFunction(TrapIm)

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
smoothing_gauss =fspecial('gaussian',5,1);

TrapIm = (TrapIm-min(TrapIm(:)));
TrapIm = TrapIm/max(TrapIm(:));

%% finding centers

% [accum,~,~,~] = ACBackGroundFunctions.CircularHough_Grd(TrapIm,[minrad maxrad] , 0.1, 8, 1);
% 
% accum = conv2(accum,gauss,'same');
% 
% accum = accum.*imregionalmax(accum);
% 
% for i=1:2
%     
%     [centers(i,2),centers(i,1)] = find(accum == max(accum(:)));
%     accum(centers(i,2),centers(i,1)) = accum(1,1)-1;
%     
% end
f_im = figure;
imshow(TrapIm,[])
n = 1;
fprintf('\n\nselect pillar centers\n\n');
while n<3
    [centers(n,1), centers(n,2)] = ginput(1);
    hold on
    plot(centers(n,1),centers(n,2),'or');
    pause(0.1);
    n = n+1;
    
end
hold off

%% finding boundary

% just a way to get default parameters
ttacObject = timelapseTrapsActiveContour;
ttacObject.Parameters.ActiveContour.opt_points = 20;
ttacObject.Parameters.ActiveContour.visualise = 3;
ttacObject.Parameters.ActiveContour.alpha = 5e-1;
ttacObject.Parameters.ImageTransformation.ImageTransformFunction = 'none';
%ttacObject.Parameters.ImageTransformation.TransformParameters.invert = true;
PillarImages = zeros([ttacObject.Parameters.ImageSegmentation.SubImageSize*[1 1] 2]);

for i=1:2
    
    PillarImages(:,:,i) = ACBackGroundFunctions.get_cell_image(TrapIm,...
                            ttacObject.Parameters.ImageSegmentation.SubImageSize,...
                            centers(i,:) );
    
end

ImageTransformFunction = str2func(['ACImageTransformations.' ttacObject.Parameters.ImageTransformation.ImageTransformFunction]);
TransformedTrapImage = ImageTransformFunction(PillarImages,ttacObject.Parameters.ImageTransformation.TransformParameters);

TrapPixels = false(size(TrapIm));

for i=1:2
    [RadiiResult,AnglesResult] = ...
        ACMethods.PSORadialTimeStack(TransformedTrapImage(:,:,i),ttacObject.Parameters.ActiveContour,ceil(ttacObject.Parameters.ImageSegmentation.SubImageSize/2)*[1 1;1 1]);
    
[px,py] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult',AnglesResult',centers(i,:),size(TrapIm));

TrapPixels(py+size(TrapIm,1)*(px-1))=true;

end


TrapPixels = imfill(TrapPixels,'holes');

TrapPixelsCert = (bwdist(TrapPixels~=1)-uncertainty_in_edge) > 0;

%TrapPixels = imdilate(TrapPixels,strel('disk',1),'same');

TrapPixelLogical = TrapPixels;

TrapPixels = conv2(1*TrapPixels,smoothing_gauss,'same');

TrapPixels(TrapPixelsCert>0) = 1;

imshow(OverlapGreyRed(TrapIm,TrapPixels),[]);
pause;

close(f_im);
end