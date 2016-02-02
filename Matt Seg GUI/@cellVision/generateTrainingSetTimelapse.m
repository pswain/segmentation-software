function [debug_outputs] =  generateTrainingSetTimelapse(cCellVision,cTimelapse,frame_ss,type,debugging)
%type can be a string or a handle to a function. if a handle, expects
%cCellvision object and then image(or image stack)

% dictionary - contrains the images to be used and x-y coordinates for the synapses

% cPixelTraining - contains the
% cPixelTraining.negativeSamplesPerImage - contains the number of negative
% samples per image

% s_strel - a structuring element used to increase the size of
% the selected point identifying the synapse
%
% s_strel = strel('disk',2);
% cPixelTraining.negativeSamplesPerImage=200;

%debug_outputs is for debugging:
%     debug_outputs = { negatives_stack , positive_stack , neg_exclude_stack}

ElcoWay = false; %boolean on whether to find training set Elco's way or Matt's way
useSegEdge=true;

debug_outputs = {};
if nargin<3
    frame_ss=1;
end

if nargin<4
    type='full';
end

if nargin<5 || isempty(debugging)
    debugging = false;
end

if debugging
    neg_exclude_stack = []; %pixels excluded from negatives for each stack
    negatives_stack = [];
    positive_stack = [];
    entry_index = [];
end

cCellVision.training_channels = cTimelapse.channelNames(cTimelapse.channelsForSegment);
cCellVision.filterFunction = type;
cCellVision.TrainDataGenerationDate = date;

index=1;

trap1 = cTimelapse.returnSegmenationTrapsStack(1,cTimelapse.timepointsToProcess(1));

features=getFilteredImage(cCellVision,trap1{1});

n_features=size(features,2);
total_num_timepoints=length(cTimelapse.cTimepoint);
num_frames=0;
for i=1:total_num_timepoints
    num_frames=num_frames+length(cTimelapse.cTimepoint(i).trapInfo);
end

disp('Assuming edge pixels desired')
n_pos=num_frames*1000;
n_points=n_pos+3*cCellVision.negativeSamplesPerImage*num_frames;
cCellVision.trainingData.features=zeros(n_points,n_features)-100;
cCellVision.trainingData.class=zeros(1,n_points)-100;


n_points=[];
tic; time=toc;

if strcmp(cTimelapse.fileSoure,'swain-batman') && cTimelapse.magnification==60;
    se_edge=strel('disk',16);
else
    se_edge=strel('disk',20);
end

se1 = strel('disk',1);
se2 = strel('disk',2);
se3 = strel('disk',3);
se4 = strel('disk',4);
se5 = strel('disk',5);
se6 = strel('disk',6);
se7 = strel('disk',7);

if ~isempty(cCellVision.cTrap)
    insideTraps=imerode(cCellVision.cTrap.trapOutline,se2);
%     insideTraps=imdilate(cCellVision.cTrap.trapOutline,se1);

else
    insideTraps = false([size(trap1{1},1) size(trap1{1},2)]);
end
% figure;imshow(cTimelapse.returnSingleTrapTimepoint(1,1,1),[]);
% fig1=gca;
for timepoint=1:frame_ss:total_num_timepoints
    traps=1:length(cTimelapse.cTimepoint(timepoint).trapInfo);
    image=cTimelapse.returnSegmenationTrapsStack(traps,timepoint);
    for trap=1:max(traps)
        elapsed_t=toc-time;
        disp(['Trap ', int2str(trap), 'Frame ', int2str(timepoint)])
        disp(['Time ', num2str(elapsed_t)])
        
        
        features=getFilteredImage(cCellVision,image{trap});
        
        
        
        if ~ElcoWay %Matt's way of getting cell centres. Elco is trying something different
            %used to broaden the lines for more accurate classification
            %             trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
            
            if isfield(cTimelapse.cTimepoint(timepoint).trapInfo(trap),'cellRadius') 
                
                trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
            else
                trapInfo=struct('cellRadius',[],'cellCenters',[],'cell',[]);
                if ~isempty(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell)
                    trapInfo.cellRadius=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellRadius];
                    tempy=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellCenter];
                    trapInfo.cellCenters=reshape(tempy,[2 length(tempy)/2])';
                    trapInfo.cell=cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell;
                else
                    trapInfo.cellRadius=[];
                    trapInfo.cellCenters=[];
                end
            end
            training_class=zeros([size(image{trap},1) size(image{trap},2) length(trapInfo.cellRadius)+1]);
            training_classEdge=zeros([size(image{trap},1) size(image{trap},2) 1]);
            
            % generate the edge pixel training
            if false
                tim=image{trap}(:,:,1);
                timS=stdfilt(tim,true(11));
                timD=tim-timS;
                timD=imfilter(timD,fspecial('average',4));
                tim2=imerode(timD<60,se1);
            else
                tim=image{trap}(:,:,1);
                fG=[1 0 0 0 0  1];
                hx=imfilter(tim,fG,'replicate');
                hy=imfilter(tim,fG','replicate');
                gim=(hx.^2 + hy.^2).^.5;
                
                ngim=gim/1;
                timS=stdfilt(tim,true(11));
                timD=tim+ngim-timS;
                thresh=mean(timD(:))-.35*std(timD(:));
                tim2=timD<thresh;
                props=bwpropfilt(tim2,'area',[200 10000]);
%                 tim2=imerode(props,se1);

%                 tim2=props;
            end

            training_classEdge=tim2>0;
            
            
            nearCenterTraining=zeros([size(image{trap},1) size(image{trap},2) length(trapInfo.cellRadius)+1]);
            if size(trapInfo.cellRadius,1)>0
                for cellInd=1:length(trapInfo.cellRadius)
                    training_class(round(trapInfo.cellCenters(cellInd,2)),round(trapInfo.cellCenters(cellInd,1)),cellInd)=1;
                    nearCenterTraining(round(trapInfo.cellCenters(cellInd,2)),round(trapInfo.cellCenters(cellInd,1)),cellInd)=1;
                    training_class(round(trapInfo.cellCenters(cellInd,2)),round(trapInfo.cellCenters(cellInd,1)),cellInd)=1;
                    
                    
                    % This is in case the training images are not circles.
                    % In this case, want to use the major axis, not a
                    % single center point for training.
                    
                    currCellRadius=trapInfo.cellRadius(cellInd);
                    fillIm=imfill(imdilate(full(trapInfo.cell(cellInd).segmented),se1),'holes');
                    bwProps=regionprops(fillIm,'MajorAxisLength','MinorAxisLength','Orientation','EquivDiameter');
                    if ~isempty(bwProps)
                        if bwProps(1).MajorAxisLength ~= bwProps(1).MinorAxisLength
                            convLine=ones(1,ceil((bwProps(1).MajorAxisLength-bwProps(1).MinorAxisLength)/2));
                            convLine=imrotate(convLine,bwProps(1).Orientation)>0;
                            training_class(:,:,cellInd)=imdilate(training_class(:,:,cellInd),convLine);
                            
                            %b/c we are using the whole length of the elipse,
                            %don't want to dilate it too much so don't use the
                            %EquivRadius, instead use the minor axis length
                            currCellRadius=(bwProps(1).MinorAxisLength/2);
                        end
                        
                    end
                    if useSegEdge
                        t=imdilate(full(trapInfo.cell(cellInd).segmented),se1);
                        training_classEdge(t>0)=1;
                    end
                    if currCellRadius>4 && currCellRadius<6
                        training_class(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se1);
                        nearCenterTraining(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se1);
                    elseif currCellRadius<7
                        training_class(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se2);
                        nearCenterTraining(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se1);
                    elseif currCellRadius<9
                        training_class(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se3);
                        nearCenterTraining(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se2);
                    elseif currCellRadius<14
                        training_class(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se4);
                        nearCenterTraining(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se2);
                    elseif currCellRadius<17
                        training_class(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se5);
                        nearCenterTraining(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se2);
                    elseif currCellRadius<20
                        training_class(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se6);
                        nearCenterTraining(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se2);
                    else
                        training_class(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se7);
                        nearCenterTraining(:,:,cellInd)=imdilate(training_class(:,:,cellInd),se2);
                    end
                end
            end
            
            
            training_class=max(training_class,[],3);
            nearCenterTraining=max(nearCenterTraining,[],3);
            nearCenterTraining=nearCenterTraining>0;
            
            %             training_class(training_classEdge>0)=2;
%             if useSegEdge
%                 training_classEdge=imdilate(training_classEdge,se1);
%             end
            training_classEdge(training_class>0)=0; %center pixels are more important
            training_classEdge(nearCenterTraining>0)=0; %center pixels are more important

            exclude_from_negs = nearCenterTraining;
            
            % exclude the pixels around the trap only
            exclude_from_negs = nearCenterTraining & imdilate(cCellVision.cTrap.contour,se2);
        end
        
        for z=1
        if ElcoWay
            trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
            
            training_class=zeros([size(image{trap},1) size(image{trap},2) length(trapInfo.cell)+1]);
            exclude_from_negs = training_class;
            if trapInfo.cellsPresent && ~isempty(trapInfo.cell) %shouldn't be necessary in future
                for cellInd=1:length(trapInfo.cell)
                    if ~isempty(trapInfo.cell(cellInd).cellCenter)
                        training_class(round(trapInfo.cell(cellInd).cellCenter(2)),round(trapInfo.cell(cellInd).cellCenter(1)),cellInd)=1;
                        exclude_from_negs(:,:,cellInd) = imerode(imfill(full(trapInfo.cell(cellInd).segmented),'holes'),se2);
                    end
                end
            end
            training_class=max(training_class,[],3);
            training_class=training_class>0;
            exclude_from_negs=max(exclude_from_negs,[],3);
            exclude_from_negs=exclude_from_negs>0;
            %exclude pixels around right next to centre pixels to try and
            %make classification more robust
        end
        end
        
        
        %another option
        edge_im_all = false(size(image{1},1), size(image{1},2));
        for i=1:size(image{trap},3)
            [edge_im thresh]=edge(max(image{trap}(:,:,i),[],3),'canny');
            edge_im=imdilate(edge_im,se_edge);
            edge_im_all = edge_im | edge_im_all;
        end
        
        %or just make everything an option
        %             edge_im=ones(size(image,1),size(image,2));
        
        num_neg=cCellVision.negativeSamplesPerImage;
        % exclude regions that are inside the traps;
        neg_index=find(exclude_from_negs==0 & edge_im & ~insideTraps & ~training_classEdge & ~training_class);
        training_classEdge(insideTraps)=0;
        training_classEdge(exclude_from_negs)=0;

        edge_index=find(training_classEdge);
        %             neg_index=find(class==0 & ~insideTraps);
        if debugging
            neg_exclude_stack = cat(3,neg_exclude_stack,exclude_from_negs);
            positive_stack = cat(3,positive_stack,training_class);
            entry_index = cat(1,entry_index,[timepoint trap]);
        end
        if length(neg_index)>2*num_neg
            neg_perm=randperm(length(neg_index));
            class_temp=zeros(1,2*num_neg);
            output=features(neg_index(neg_perm(1:2*num_neg)),:);
            pos_index=find(training_class~=0);
            class_temp(1,end+1:end+length(pos_index))=training_class(pos_index);
            output(end+1:end+length(pos_index),:)=features(pos_index,:);
            
            %lame way of detecting edges, should have a separate edge_num
            %rather than using the num_neg
            num_edge=min([length(edge_index) num_neg]);
            edge_perm=randperm(length(edge_index));
            output(end+1:end+num_edge,:)=features(edge_index(edge_perm(1:num_edge)),:);
            class_temp(1,end+1:end+num_edge)=2;
            
            n_points=size(output,1);
            cCellVision.trainingData.features(index:index+n_points-1,:)=output;
            cCellVision.trainingData.class(1,index:index+n_points-1)=class_temp;
            index=index+n_points;
            if debugging
                temp_neg = false(size(image{trap},1), size(image{trap},2));
                temp_neg(neg_index(neg_perm(1:num_neg))) = true;
                negatives_stack = cat(3,negatives_stack,temp_neg);
            end
        else
            neg_perm=randperm(length(neg_index));
            class_temp=zeros(1,length(neg_index));
            output=features(neg_index,:);
            
            pos_index=find(training_class~=0);
            class_temp(1,end+1:end+length(pos_index))=training_class(pos_index);
            output(end+1:end+length(pos_index),:)=features(pos_index,:);
            
            n_points=size(output,1);
            cCellVision.trainingData.features(index:index+n_points-1,:)=output;
            cCellVision.trainingData.class(1,index:index+n_points-1)=class_temp';
            index=index+n_points;
            if debugging
                temp_neg = false(size(image{trap},1), size(image{trap},2));
                temp_neg(neg_index) = true;
                negatives_stack = cat(3,negatives_stack,temp_neg);
            end
        end
    end
end

if debugging
    
    debug_outputs{1} = negatives_stack;
    debug_outputs{2} = positive_stack;
    debug_outputs{3} = neg_exclude_stack;
    debug_outputs{4} = entry_index;
else
    debug_outputs{1} = [];
end

non_entries=find(cCellVision.trainingData.class<0);
cCellVision.trainingData.class(non_entries)=[];
cCellVision.trainingData.features(non_entries,:)=[];
[r c]=find(cCellVision.trainingData.features==Inf)
[r c]=find(cCellVision.trainingData.features==NaN)



cCellVision.scaling.min=min(cCellVision.trainingData.features);
cCellVision.scaling.max=max(cCellVision.trainingData.features);

loc=find(cCellVision.scaling.max==cCellVision.scaling.min)
cCellVision.scaling.max(loc)=cCellVision.scaling.max(loc)+1;
%
cCellVision.trainingData.features=(cCellVision.trainingData.features - repmat(cCellVision.scaling.min,size(cCellVision.trainingData.features,1),1));
cCellVision.trainingData.features=cCellVision.trainingData.features*spdiags(1./(cCellVision.scaling.max-cCellVision.scaling.min)',0,size(cCellVision.trainingData.features,2),size(cCellVision.trainingData.features,2));
end