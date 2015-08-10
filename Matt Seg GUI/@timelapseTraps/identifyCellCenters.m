function identifyCellCenters(cTimelapse,cCellVision,timepoint,channel, method)
nargin

if nargin<3
    timepoint=1;
end

if nargin<4
    channel=1
end

if nargin<5
    method='twostage'
end

% This goes through all images of the traps to determine the min/max
% intensity value and the best threshold to use for all traps
switch method
    case 'medfilt2'
        fluorescence_medfilt(cTimelapse,timepoint,channel)
    case 'linear'
        linear_segmentation(cTimelapse,cCellVision,timepoint,channel)
    case 'kernel'
        kernel_segmentation(cTimelapse,cCellVision,timepoint,channel)
    case 'twostage'
        TwoStage_segmentation(cTimelapse,cCellVision,timepoint,channel)

end
end

function linear_segmentation(cTimelapse,cCellVision,timepoint,channel)
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
        [p_im d_im]=cCellVision.classifyImageLinear(temp_im);
        cTimelapse.cTrapsLabelled(traps(j)).segmented(:,:,i)=p_im>0;
    end
end

end

function kernel_segmentation(cTimelapse,cCellVision,timepoint,channel)
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

function TwoStage_segmentation(cTimelapse,cCellVision,timepoint,channel)
% This preallocates the segmented images to speed up execution
image=cTimelapse.returnSingleTrapTimepoint(1,timepoint,channel);
traps=1:length(cTimelapse.cTimepoint(timepoint).trapLocations);
for j=1:length(cTimelapse.cTimepoint(timepoint).trapLocations)
    cTimelapse.cTimepoint(timepoint).trapInfo(j)=struct('segCenters',zeros(size(image))>0,'cellCenters',[],'cellRadius',[]);
    %     cTimelapse.cTimepoint(timepoint).segmentedCenters=zeros(size(image,1),size(image,2),length(traps))>0;
    %     cTimelapse.cTrapsLabelled(traps(j)).segmented=zeros(size(image,1),size(image,2),length(cTimelapse.cTrapsLabelled(traps(j)).timepoint))>0;
    %     cTimelapse.cTrapsLabelled(traps(j)).cellCenters=cell(length(cTimelapse.cTrapsLabelled(traps(j)).timepoint));
    %     cTimelapse.cTrapsLabelled(traps(j)).cellRadius=cell(length(cTimelapse.cTrapsLabelled(traps(j)).timepoint));
end

i=timepoint;

disp(['Timepoint ',int2str(i)])

figure(1);fig1=gca;
%     image=cTimelapse.returnTrapsTimepoint(temp_traps,cTimelapse.cTrapsLabelled(temp_traps(1)).timepoint(i),channel);
image=cTimelapse.returnTrapsTimepoint(traps,timepoint,channel);
for j=1:size(image,3)
    temp_im=image(:,:,j);
    [p_im d_im]=cCellVision.classifyImage2Stage(temp_im);
    t_im=imfilter(d_im,fspecial('disk',1));
    bw=t_im<0;
    
    bw_l=bwlabel(bw);
    props=regionprops(bw);
    for d=1:length(props)
        if props(d).Area<3
            bw(bw_l==d)=0;
        end
    end
    imshow(bw,[],'Parent',fig1);pause(.001);
    cTimelapse.cTimepoint(timepoint).trapInfo(j).segCenters=bw>0;
end
end



function fluorescence_medfilt(cTimelapse,traps,channel)
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
