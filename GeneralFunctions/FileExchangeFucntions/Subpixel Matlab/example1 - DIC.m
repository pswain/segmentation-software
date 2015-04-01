%%
load('/Users/mcrane2/OneDrive/timelapses/HOG_fitness_ramps_newdevice/Mar 16 - shortNoisy ramp - 2minSamples - 3strains wt-ste11-ssk1/cExperiment.mat')
%%
% cTimelapse=cExperiment.returnTimelapse(1);
load('/Users/mcrane2/OneDrive/timelapses/HOG_fitness_ramps_newdevice/Mar 16 - shortNoisy ramp - 2minSamples -3strains wt-ste11-ssk1/pos14cTimelapse.mat')

%%
close all
figure;
mChChannel=3;

% for tp=50:100
tp=150
trapIndex=14
im=cTimelapse.returnTrapsTimepoint(trapIndex,tp,mChChannel,'sum');
im=double(im);
im=im/max(im(:))*255;
image=im;
imshow(image/255,'InitialMagnification', 500);

% subpixel detection
threshold = 10;
tic
% image=medfilt2(image,true(2));
edges = subpixelEdges(image, threshold, 'SmoothingIter', 1); 
toc
% show edges
visEdges(edges);

% pause(2);
% end
% figure;
mChChannel=2;
cellIndex=2;
cellCenter=double(cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(cellIndex).cellCenter);
cellRadius=double(cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(cellIndex).cellRadius);
distToCenter=pdist2(cellCenter,[edges.x edges.y]);


%to remove points too far from where the edge "should" be
distThresh=[1.4 .5];
distPossible=distToCenter<cellRadius*distThresh(1) & distToCenter>cellRadius*distThresh(2);

x=edges.x-cellCenter(1);
y=edges.y-cellCenter(2);

[thetaIdeal, rhoIdeal]=cart2pol(x,y);

%correct for direction (coming out of cell center, so should be opposite
%direciton

x=edges.nx;
y=edges.ny;
[thetaEdge, rhoEdge]=cart2pol(x,y);
% thetaEdge=thetaEdge+pi;
% % thetaEdge=rem(thetaEdge,2*pi);
% % thetaEdge=thetaEdge-2*pi;
% thetaEdge(thetaEdge>pi)=
negTheta=thetaEdge<0;
thetaEdge(~negTheta)=thetaEdge(~negTheta)-pi;
thetaEdge(negTheta)=thetaEdge(negTheta)+pi;


thetaPossible=abs((abs(thetaEdge)-abs(thetaIdeal)))<(pi/8);

edgePts=thetaPossible&distPossible';

fieldN=fieldnames(edges);
for fieldInd=1:length(fieldN)
%     temp=edges.(fieldN{fieldInd});
    edges.(fieldN{fieldInd})=edges.(fieldN{fieldInd})(edgePts);
end
figure
imshow(image/255,'InitialMagnification', 500);
%
visEdges(edges);
impixelinfo

%
X=edges.x-cellCenter(1);
Y=edges.y-cellCenter(2);
[angles,radii] = cart2pol(X,Y)

image_size=size(im);
center=cellCenter;
angles(angles<0)=angles(angles<0)+2*pi;
%%
% function to take a set of radii,angles,a center and return an unbroken
% edge of the cell with no repeats.

% radii        -   vector of radii around the cell
% angles       -   angles to the x axis at which these radii are given (clockwise
%                  is positive)
% image_size   -   size of the image in which the points should be confined.

% px           -   x coordinates of resultant end points.
% py           -   y coordinates of resultant end points.
pixel_diff = 0.1;
angle_diff = pixel_diff/max(radii);
steps = (-.1:angle_diff:(2.1*pi))';

%order the angles vector (may not be necessary)
[~,indices_angles] = sort(abs(angles),1);
angles=angles(indices_angles);
radii = radii(indices_angles);

% angles(end+1)=angles(1);
% radii(end+1)=radii(1);
%construct spline using file exchange function 'splinefit'
% r_spline = splinefit([angles; 2*pi],[radii;radii(1)],[angles; 2*pi],'p');%make the spline
% r_spline = splinefit([angles; 2*pi],[radii;radii(1)],[angles(1:6:end); 2*pi],'p',7);%make the spline
r_spline = splinefit([angles; angles(1:floor(length(angles)/3))],[radii;radii(1:floor(length(radii)/3))],[0 ;angles(1:3:end); 2*pi],.1,'p',5);%make the spline


radii_full = ppval(r_spline,steps);

%convert radial coords to x y coords
px = round(center(1)+radii_full.*cos(steps));%radial cords
py = round(center(2)+radii_full.*sin(steps));

%check they are sensible
px(px<1) = 1;
px(px>image_size(2)) = image_size(2);

py(py<1) = 1;
py(py>image_size(1)) = image_size(1);

I = (diff(px)|diff(py));
px = px(I);
py = py(I);

imNew=im;
newVal=max(im(:))*1.5;
for i=1:length(px)
imNew(py(i),px(i))=newVal;
end
figure;imshow(imNew,[]);