function d_im=identifyCellCentersTrap(cTimelapse,cCellVision,timepoint,trap,channel,trap_image,old_d_im)

if nargin<3
    timepoint=1;
end

if nargin<4
    trap=1;
end

if nargin<5
    channel=1;
end

% if nargin<6
%     method='twostage';
% end

if nargin<6
    image=cTimelapse.returnSingleTrapTimepoint(trap,timepoint,channel);
else
    image=trap_image;
end

image=imresize(image,cTimelapse.pixelSize/cCellVision.pixelSize);

if nargin<7
    old_d_im=[];
end    


% This goes through all images of the traps to determine the min/max
% intensity value and the best threshold to use for all traps
switch cCellVision.method
    case 'medfilt2'
        fluorescence_medfilt(cTimelapse,timepoint,channel,trap,image,old_d_im);
    case 'linear'
        d_im=linear_segmentation(cTimelapse,cCellVision,timepoint,channel,trap,image,old_d_im);
    case 'kernel'
        d_im=kernel_segmentation(cTimelapse,cCellVision,timepoint,channel,trap,image,old_d_im);
    case 'twostage'
        d_im=TwoStage_segmentation(cTimelapse,cCellVision,timepoint,channel,trap,image,old_d_im);

end

d_im=imresize(d_im,cCellVision.pixelSize/cTimelapse.pixelSize);

end

function d_im=linear_segmentation(cTimelapse,cCellVision,timepoint,channel,trap,image,old_d_im)
% This preallocates the segmented images to speed up execution
% This preallocates the segmented images to speed up execution

% traps=1:length(cTimelapse.cTimepoint(timepoint).trapLocations);
j=trap;
if cTimelapse.trapsPresent
    cTimelapse.cTimepoint(timepoint).trapInfo(j)=struct('segCenters',zeros(size(image))>0,'cell',[],'cellsPresent',0,'cellLabel',[],'segmented',sparse(zeros(size(image))>0));
    cTimelapse.cTimepoint(timepoint).trapInfo(j).cell.cellCenter=[];
    cTimelapse.cTimepoint(timepoint).trapInfo(j).cell.cellRadius=[];
    cTimelapse.cTimepoint(timepoint).trapInfo(j).cell.segmented=sparse(zeros(size(image))>0);

else
    cTimelapse.cTimepoint(timepoint).trapInfo=struct('segCenters',zeros(size(image))>0,'cell',[],'cellsPresent',0,'cellLabel',[],'segmented',sparse(zeros(size(image))>0));
    cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.cellCenter=[];
    cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.cellRadius=[];
    cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.segmented=sparse(zeros(size(image))>0);
    cTimelapse.cTimepoint(timepoint).trapInfo(1).cellsPresent=0;
end
% cTimelapse.cTimepoint(timepoint).trapInfo(j)=struct('segCenters',zeros(size(image))>0,'cell',[],'cellCenters',[],'cellRadius',[],'segmented',zeros(size(image))>0,'cellLabel',zeros(1,15));

i=timepoint;
% [p_im d_im]=cCellVision.classifyImage2Stage(image);
[p_im d_im]=cCellVision.classifyImageLinear(image);


if isempty(old_d_im)
    if timepoint>1
        temp_im=cTimelapse.returnSingleTrapTimepoint(trap,timepoint-1,channel);
        [p_im old_d_im]=cCellVision.classifyImageLinear(temp_im);
    else
        old_d_im=zeros(size(d_im));
    end
end

combined_d_im=d_im+old_d_im/4;
t_im=imfilter(combined_d_im,fspecial('gaussian',3,.4));
% t_im=imfilter(d_im,fspecial('disk',1));

bw=t_im<0;
% bw=imclose(bw,strel('disk',2));
bw_l=bwlabel(bw);
props=regionprops(bw);
for d=1:length(props)
    if props(d).Area>40
        seg_thresh=min(t_im(bw_l==d))/3;
        bw(bw_l==d)=t_im(bw_l==d)<seg_thresh;
    end
end

bw_l=bwlabel(bw);
props=regionprops(bw);
for d=1:length(props)
    if props(d).Area<5
        bw(bw_l==d)=0;
    end
end
% bw=imclose(bw,strel('disk',2));

% imshow(bw,[],'Parent',fig1);pause(.001);
cTimelapse.cTimepoint(timepoint).trapInfo(trap).segCenters=bw>0;

end


function d_im=kernel_segmentation(cTimelapse,cCellVision,timepoint,channel,trap,old_d_im)
% This preallocates the segmented images to speed up execution
image=cTimelapse.returnSingleTrapTimepoint(traps(1),1,channel);
for j=1:length(traps)
    cTimelapse.cTrapsLabelled(traps(j)).segmented=zeros(size(image,1),size(image,2),length(cTimelapse.cTrapsLabelled(traps(j)).timepoint))>0;
end

for i=1:length(cTimelapse.cTrapsLabelled(traps(1)).timepoint)
    disp(['Timepoint ',int2str(i)])
    
    image=cTimelapse.returnTrapsTimepoint(traps,i,channel);
    for j=1:size(image,3)
        temp_im=image(:,:,j);
        [p_im d_im]=cCellVision.classifyImage(temp_im);
        cTimelapse.cTrapsLabelled(traps(j)).segmented(:,:,i)=imfilter(d_im,fspecial('disk',2)),0;
    end
end

end

function d_im=TwoStage_segmentation(cTimelapse,cCellVision,timepoint,channel,trap,image,old_d_im)
% This preallocates the segmented images to speed up execution
% image=cTimelapse.returnSingleTrapTimepoint(1,timepoint,channel);

% traps=1:length(cTimelapse.cTimepoint(timepoint).trapLocations);
j=trap;
if cTimelapse.trapsPresent
    cTimelapse.cTimepoint(timepoint).trapInfo(j)=struct('segCenters',zeros(size(image))>0,'cell',[],'cellsPresent',0,'cellLabel',[],'segmented',sparse(zeros(size(image))>0));
    cTimelapse.cTimepoint(timepoint).trapInfo(j).cell.cellCenter=[];
    cTimelapse.cTimepoint(timepoint).trapInfo(j).cell.cellRadius=[];
    cTimelapse.cTimepoint(timepoint).trapInfo(j).cell.segmented=sparse(zeros(size(image))>0);

else
    cTimelapse.cTimepoint(timepoint).trapInfo=struct('segCenters',zeros(size(image))>0,'cell',[],'cellsPresent',0,'cellLabel',[],'segmented',sparse(zeros(size(image))>0));
    cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.cellCenter=[];
    cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.cellRadius=[];
    cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.segmented=sparse(zeros(size(image))>0);
    cTimelapse.cTimepoint(timepoint).trapInfo(1).cellsPresent=0;
end
% cTimelapse.cTimepoint(timepoint).trapInfo(j)=struct('segCenters',zeros(size(image))>0,'cell',[],'cellCenters',[],'cellRadius',[],'segmented',zeros(size(image))>0,'cellLabel',zeros(1,15));

i=timepoint;

% disp(['Timepoint ',int2str(i)])


[p_im d_im]=cCellVision.classifyImage2Stage(image);
% [p_im d_im]=cCellVision.classifyImageLinear(image);


if isempty(old_d_im)
    if timepoint>1
        temp_im=cTimelapse.returnSingleTrapTimepoint(trap,timepoint-1,channel);
        [p_im old_d_im]=cCellVision.classifyImage2Stage(temp_im);
    else
        old_d_im=zeros(size(d_im));
    end
end

combined_d_im=d_im+old_d_im/4;
t_im=imfilter(combined_d_im,fspecial('gaussian',3,.4));
% t_im=imfilter(d_im,fspecial('disk',1));

bw=t_im<0;
% bw=imclose(bw,strel('disk',2));
bw_l=bwlabel(bw);
props=regionprops(bw);
for d=1:length(props)
    if props(d).Area>40
        seg_thresh=min(t_im(bw_l==d))/3;
        bw(bw_l==d)=t_im(bw_l==d)<seg_thresh;
    end
end

bw_l=bwlabel(bw);
props=regionprops(bw);
for d=1:length(props)
    if props(d).Area<5
        bw(bw_l==d)=0;
    end
end
% bw=imclose(bw,strel('disk',2));

% imshow(bw,[],'Parent',fig1);pause(.001);
cTimelapse.cTimepoint(timepoint).trapInfo(trap).segCenters=bw>0;
end


function fluorescence_medfilt(cTimelapse,traps,channel,old_d_im)
        if length(traps)<11
        trapTimelapse=cTimelapse.returnTrapsTimelapse(traps,channel);
        trapTimelapse=double(trapTimelapse);
        %     minTrapTimelapse=min(trapTimelapse(:));
        maxTrapTimelapse=max(trapTimelapse(:));
        % trapTimelapse=trapTimelapse-minTrapTimelapse;
        trapTimelapse=trapTimelapse/maxTrapTimelapse;
        thresh=graythresh(trapTimelapse(:));
    else
        trapTimelapse=cTimelapse.returnTrapsTimelapse(traps(1:10),channel);
        trapTimelapse=double(trapTimelapse);
        minTrapTimelapse=min(trapTimelapse(:));
        maxTrapTimelapse=max(trapTimelapse(:));
        % trapTimelapse=trapTimelapse-minTrapTimelapse;
        trapTimelapse=trapTimelapse/maxTrapTimelapse;
        thresh=graythresh(trapTimelapse(:));
    end
    
    % This preallocates the segmented images to speed up execution
    image=cTimelapse.returnSingleTrapTimepoint(traps(1),1,channel);
    for j=1:length(traps)
        cTimelapse.cTrapsLabelled(traps(j)).segmented=zeros(size(image,1),size(image,2),length(cTimelapse.cTrapsLabelled(traps(j)).timepoint))>0;
    end
    
    % This uses the threshold to
    imf=fspecial('disk',3);
    for i=1:length(cTimelapse.cTrapsLabelled(traps(1)).timepoint)
        disp(['Timepoint ',int2str(i)])
        
        image=cTimelapse.returnTrapsTimepoint(traps,i,channel);
        image=double(image);
        %     image=image-minTrapTimelapse;
        image=image/maxTrapTimelapse;
        for j=1:size(image,3)
            temp_im=image(:,:,j);
            temp_im=imfilter(temp_im,imf);
            % temp_im=medfilt2(temp_im);
            bw=im2bw(temp_im,thresh*1);
            %         figure(1);imshow(bw,[]);pause(.1);
            cTimelapse.cTrapsLabelled(traps(j)).segmented(:,:,i)=bw>0;
            %         cTimelapse.cTrapsLabelled(traps(j)).segmented(:,:,i)=cCellVision.segment(image(:,:,j));
        end
    end
end
