function [d_imCenters, d_imEdges]=identifyCellCentersTrap(cTimelapse,cCellVision,timepoint,trap,image,old_d_im)
% d_im=identifyCellCentersTrap(cTimelapse,cCellVision,timepoint,trap,trap_image,old_d_im)
%
% - calculates the decision image - the image in which negative pixels
%   indicate a pixel likely to be a cell centre 
% - resets the trapInfo field  cTimelapse.cTimepoint(timepoint).trapInfo(trap) to be blank with
%   segCentres populated with a sparse logical array of the areas under the
%   two stage threshold.
% 
% cTimelapse    :   object of the timelapseTraps class
% cCellVision   :   object of the cellVision class
% timepoint     :   timepoint at which the segmentation is occurring.
%                   defaults to 1.
% trap          :   array of indices of traps at which segmentation should
%                   be performed. defaults to 1.
% image         :   optional. cell array of stacks of images to be used in
%                   the segmentation procedure. Exact size of cell array
%                   and images is different depending on the
%                   cCellVision.method, but defaults to the output from 
%                   cTimelapse.returnSegmenationTrapsStack(trap,timepoint,cCellVision.method)
%                   and it should follow the convention given in that
%                   method.
%                   
% old_d_im      :   optional. The decision image from the previous
%                   timepoint, which if provided is smoothed with a
%                   gaussian transform and then 1/6th added to the
%                   calculated decision image to try and provide temporal
%                   information. defaults to zeros of appropriate size.
%
% Behaviour is dependent on cCellVision.method, but basically amounts to
% running the same function either in a parfor loop over individual trap
% image stacks (if method is 'linear' or 'twostage') or running the
% segmentation outside a for loop over the whole image ('wholeIm') or over
% a strip of trap image ('wholeTrap')
% This affects the size of the decision image (d_im) returned but does not
% affect the way the segCentres field is populated. 
%
% these methods will be differentially efficient depending on the way the
% transformed image is calculated. 
%
% The decision image is also smoothed with a gaussian before being
% returned, and if the magnification of the cTimelapse and the cCellVision
% are different it will also be a different size from the input image, as
% will the segCentres field.
%
% Also populates the:
%       cCellVision.cTrap.currentTpOutline=trapOutline
% field with the logical trapOutline (filled) of all the trap pixels in the
% image. Important for the wholeIm/wholeTrap methods.

if nargin<3
    timepoint=1;
end

if nargin<4
    trap=1;
end


if nargin<5 ||isempty(image)
    image=cTimelapse.returnSegmenationTrapsStack(trap,timepoint,cCellVision.method);

end

if cCellVision.magnification/cTimelapse.magnification ~= 1
    image=imresize(image,cCellVision.magnification/cTimelapse.magnification);
end

if nargin<6 || isempty(old_d_im)
    old_d_im=zeros(size(image{1},1),size(image{1},2),size(image,1));
end    


switch cCellVision.method
    case {'linear','twostage'}
        [d_imCenters, d_imEdges]=TwoStage_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im);
    case {'wholeIm','wholeTrap'}
        [d_imCenters]=wholeIm_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im);
end

end



function [d_imCenters, d_imEdges]=TwoStage_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im)
%[d_im]=TwoStage_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im)
%
% This function now does both linear and two stage segmentation.
% The decision image (an image of the likliness of each pixel to be a cell
% centre - lower values being more likely - is calculated for each trap
% using the classifyImage2Stage method of cCellVision.
% This method does linear or two stage classification depending whether the
% cCellVision model is capable of two stage classification.
%
% A number of post processing steps are then performed:
%       - dilation with a gaussian filter
%       - addition of the one sixth of the old_d_im, after gaussian
%         filtering. this is to try and include temporal information.
%
% This is filtered using the twoStageThresh of cCellVision and stored in
% the trapInfo structure in segCentres. this is used for the cell
% identification by the identifyCellObjects method.

% This preallocates the segmented images to speed up execution
d_imCenters=zeros(size(old_d_im));
d_imEdges=zeros(size(old_d_im));
if cTimelapse.trapsPresent
    trapOutline=imdilate(cCellVision.cTrap.trapOutline,cCellVision.se.se2);
else
    trapOutline = false(size(image{1},1),size(image{1},2));
end

%calculate the decisions image, do some transformations on it, and
%threshold it to give segCentres.

%uncomment when you change parfor to for for debugginf
% fprintf('change back to parfor  - line 118 identifyCellCentresTrap\n')
parfor k=1:length(trap) %CHANGE BACK TO parfor
    [~, d_im_temp]=cCellVision.classifyImage2Stage(image{k},trapOutline>0);
    d_imCenters(:,:,k)=d_im_temp(:,:,1);
    if size(d_im_temp,3)>1
        d_imEdges(:,:,k)=d_im_temp(:,:,2);
    end
%     t_im=imfilter(d_im_temp(:,:,1),fspecial('gaussian',5,1.5),'symmetric') +imfilter(old_d_im(:,:,k),fspecial('gaussian',4,2),'symmetric')/5;  
    bw=medfilt2(d_im_temp(:,:,1))<cCellVision.twoStageThresh; 
    segCenters{k}=sparse(bw>0); 
end

cCellVision.cTrap.currentTpOutline=trapOutline>0;


% store the segmentation result (segCenters) in the cTimelapse object.
for k=1:length(trap)
    if cTimelapse.trapsPresent
        data_template = sparse(zeros(size(cCellVision.cTrap.trap1,1),size(cCellVision.cTrap.trap1,2))>0);
    else
        data_template = sparse(zeros(size(image{k},1),size(image{k},2))>0);
    end
    if isempty(cTimelapse.cTimepoint(timepoint).trapInfo)
        cTimelapse.cTimepoint(timepoint).trapInfo = cTimelapse.createTrapInfoTemplate(data_template);
    end
    cTimelapse.cTimepoint(timepoint).trapInfo(trap(k))=cTimelapse.createTrapInfoTemplate(data_template);
    cTimelapse.cTimepoint(timepoint).trapInfo(trap(k)).segCenters=segCenters{k};
end
end


function [d_im]=wholeIm_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im)
%[d_im]=wholeIm_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im)
%
% handles two types of cCellVision.method : wholeIm and wholeTrap. 
%
% In the case of wholeIm the whole image is used and the trap pixels
% constructed accordingly using returnWholeTrapImage method of cTimelapse.
%
% In the case of wholeTrap the trap images are arranged in a strip and the
% segmented all together. The trapOutline is constructed accordingly as a
% strip of trap outline images. This may produce funny results if a half
% cell from one trap causes a low decision image values in an adjacent
% trap.
%
% wholeIm method is probably not recommended if traps are present since a
% large number of trapPixels (untracked traps) will still be present.
%
% the same post processing steps of gaussian smoothing and population of
% the:
%       cTimelapse.cTimepoint(timepoint).cTrapInfo(trap).segCentres 
% field are performed as above, and the cCellVision.method does not affect
% the size of this stored segCentres.
tPresent=cTimelapse.trapsPresent;
if tPresent
    if strcmp(cCellVision.method,'wholeTrap')
        trapOutline=repmat(cCellVision.cTrap.trapOutline,[1 length(trap)]);
    elseif strcmp(cCellVision.method,'wholeIm')
        trapOutline = cTimelapse.returnWholeTrapImage(cCellVision,timepoint);
    else
        error('cCellVision.method should one of {wholeIm  wholeTrap linear twostage}');
    end
else
    trapOutline = zeros(cTimelapse.imSize);
end

trapOutline = trapOutline>0;
cCellVision.cTrap.currentTpOutline=trapOutline;

[~,d_im]=cCellVision.classifyImage2StageWhole(image{1},trapOutline);

t_im=imfilter(d_im,fspecial('gaussian',5,1.5),'symmetric') +imfilter(old_d_im,fspecial('gaussian',4,2),'symmetric')/5; %
bw=t_im<cCellVision.twoStageThresh;
segCenters=cTimelapse.returnTrapsFromImage(bw,timepoint,trap);

% store the segmentation result (segCenters) in the cTimelapse object.
for k=1:length(trap)
    if tPresent
    data_template = sparse(zeros(size(cCellVision.cTrap.trap1,1),size(cCellVision.cTrap.trap1,2))>0);
    else
    data_template = sparse(zeros(size(image{k},1),size(image{k},2))>0);
    end
    if isempty(cTimelapse.cTimepoint(timepoint).trapInfo)
        cTimelapse.cTimepoint(timepoint).trapInfo = cTimelapse.createTrapInfoTemplate(data_template);
    end
    cTimelapse.cTimepoint(timepoint).trapInfo(trap(k))=cTimelapse.createTrapInfoTemplate(data_template);
    cTimelapse.cTimepoint(timepoint).trapInfo(trap(k)).segCenters=segCenters(:,:,k);
end

end

