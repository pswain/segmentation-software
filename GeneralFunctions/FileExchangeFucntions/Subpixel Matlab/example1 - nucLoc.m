%% syntethic ring

addpath('Synthetic');
imageSize = 35;
xCenter = imageSize/2;
yCenter = imageSize/2;
innerRadius = 8.0;
outerRadius = 10.0;
innerIntensity = 100;
outerIntensity = 200;
gridResolution = 100;
image = ring(imageSize, imageSize, xCenter, yCenter, ...
    innerRadius, outerRadius, innerIntensity, outerIntensity, ...
    gridResolution);
%%
load('/Users/mcrane2/OneDrive/timelapses/HOG_fitness_ramps_newdevice/Mar 15 - shortNoisy ramp - 2minSamples - 3strains wt-ste11-ssk1/cExperiment.mat')
%%
cTimelapse=cExperiment.returnTimelapse(1);
%%
close all
figure;
for tp=50:100
mChChannel=3;
im=cTimelapse.returnTrapsTimepoint(1,tp,mChChannel,'max');
im=double(im);
im=im/max(im(:))*255;
image=im;
imshow(image/255,'InitialMagnification', 600);

% subpixel detection
threshold = 15;
edges = subpixelEdges(image, threshold, 'SmoothingIter', 1); 

% show edges
visEdges(edges);

pause(2);
end