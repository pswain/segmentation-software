function d_im=identifyCellCentersTrap(cTimelapse,cCellVision,timepoint,trap,trap_image,old_d_im)

if nargin<3
    timepoint=1;
end

if nargin<4
    trap=1;
end


if nargin<5 ||isempty(trap_image)
    image=cTimelapse.returnSegmenationTrapsStack(trap,timepoint);
else
    image=trap_image;
end

if cCellVision.magnification/cTimelapse.magnification ~= 1
image=imresize(image,cCellVision.magnification/cTimelapse.magnification);
end

if nargin<6
    old_d_im=[];
end    


% This goes through all images of the traps to determine the min/max
% intensity value and the best threshold to use for all traps
switch cCellVision.method
    case 'medfilt2'
        fluorescence_medfilt(cTimelapse,timepoint,trap,image,old_d_im);
    case 'linear'
        [d_im bw]=linear_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im);
%         bw=imresize(bw,cTimelapse.magnification/cCellVision.magnification);
%         cTimelapse.cTimepoint(timepoint).trapInfo(trap).segCenters=sparse(bw>0);
    case 'kernel'
        d_im=kernel_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im);
%         bw=imresize(bw,cTimelapse.magnification/cCellVision.magnification);
%         cTimelapse.cTimepoint(timepoint).trapInfo(trap).segCenters=sparse(bw>0);
    case 'twostage'
        [d_im bw]=TwoStage_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im);
end

% d_im=imresize(d_im,cCellVision.pixelSize/cTimelapse.pixelSize);
% bw=imresize(bw,cCellVision.pixelSize/cTimelapse.pixelSize);

% d_im=imresize(d_im,cTimelapse.magnification/cCellVision.magnification);

end



function [d_im bw]=linear_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im)
% This preallocates the segmented images to speed up execution
tPresent=cTimelapse.trapsPresent;
new_dim=zeros(size(old_d_im));

for k=1:length(trap) %CHANGE BACK to PARFOR
    [p_im d_im]=cCellVision.classifyImageLinear(image{k});
    
    % combined_d_im=d_im+old_d_im/5;
    if cTimelapse.magnification<100
        t_im=imfilter(d_im,fspecial('gaussian',4,1.1),'symmetric') +imfilter(old_d_im(:,:,k),fspecial('gaussian',3,1))/6; %
            bw=t_im<cCellVision.twoStageThresh; 
                new_dim(:,:,k)=d_im;

    else
        t_im=imfilter(d_im,fspecial('disk',4),'symmetric'); %+imfilter(old_d_im,fspecial('gaussian',3,1))/6; %
        bw=t_im<cCellVision.twoStageThresh;
        if ~cTimelapse.trapsPresent
            bw=imerode(bw,strel('disk',2));
        end
    end
    
%     bw=d_im<cCellVision.twoStageThresh; 
    segCenters{k}=sparse(bw>0); 
end

for k=1:length(trap)
    j=k;
    data_template = sparse(zeros(size(image{j},1),size(image{j},2))>0);
    if tPresent
        cTimelapse.cTimepoint(timepoint).trapInfo(j)=struct('segCenters',data_template,'cell',struct('cellCenter',[],'cellRadius',[],'segmented',data_template), ...
            'cellsPresent',0,'cellLabel',[],'segmented',data_template,'trackLabel',data_template);
    else
        cTimelapse.cTimepoint(timepoint).trapInfo=struct('segCenters',data_template,'cell',[],'cellsPresent',0,'cellLabel',[],'segmented',data_template,'trackLabel',data_template);
        cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.cellCenter=[];
        cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.cellRadius=[];
        cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.segmented=data_template;
        cTimelapse.cTimepoint(timepoint).trapInfo(1).cellsPresent=0;
    end
    cTimelapse.cTimepoint(timepoint).trapInfo(j).segCenters=segCenters{k};
end

d_im=new_dim;
bw=1;

end




function d_im=kernel_segmentation(cTimelapse,cCellVision,timepoint,trap,old_d_im)

error('Elco thinks this code is way out of date and needs serious bringing up to speed before anyone can use it')
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




function [d_im bw]=TwoStage_segmentation(cTimelapse,cCellVision,timepoint,trap,image,old_d_im)
% This preallocates the segmented images to speed up execution
% image=cTimelapse.returnSingleTrapTimepoint(1,timepoint,channel);

tPresent=cTimelapse.trapsPresent;
new_dim=zeros(size(old_d_im));

parfor k=1:length(trap)
    %     j=trap(k);
    [p_im d_im]=cCellVision.classifyImage2Stage(image{k});
    
%     combined_d_im=d_im+old_d_im(:,:,j)/5;
    new_dim(:,:,k)=d_im;
    t_im=imfilter(d_im,fspecial('gaussian',5,1.5),'symmetric') +imfilter(old_d_im(:,:,k),fspecial('gaussian',4,2),'symmetric')/5; %  
    bw=t_im<cCellVision.twoStageThresh; 
    segCenters{k}=sparse(bw>0); 
end

for k=1:length(trap)
    %     j=trap(k);
    j=k;
    data_template = sparse(zeros(size(image{j},1),size(image{j},2))>0);
    if tPresent
        if isempty(cTimelapse.cTimepoint(timepoint).trapInfo)
            cTimelapse.cTimepoint(timepoint).trapInfo=struct('segCenters',data_template,'cell',struct('cellCenter',[],'cellRadius',[],'segmented',data_template), ...
            'cellsPresent',0,'cellLabel',[],'segmented',data_template,'trackLabel',data_template);
        end
        cTimelapse.cTimepoint(timepoint).trapInfo(j)=struct('segCenters',data_template,'cell',struct('cellCenter',[],'cellRadius',[],'segmented',data_template), ...
            'cellsPresent',0,'cellLabel',[],'segmented',data_template,'trackLabel',data_template);
    else
        cTimelapse.cTimepoint(timepoint).trapInfo=struct('segCenters',data_template,'cell',[],'cellsPresent',0,'cellLabel',[],'segmented',data_template,'trackLabel',data_template);
        cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.cellCenter=[];
        cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.cellRadius=[];
        cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.segmented=data_template;
        cTimelapse.cTimepoint(timepoint).trapInfo(1).cellsPresent=0;
    end
    cTimelapse.cTimepoint(timepoint).trapInfo(j).segCenters=segCenters{k};
end

% d_im=1;
d_im=new_dim;
bw=1;
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
