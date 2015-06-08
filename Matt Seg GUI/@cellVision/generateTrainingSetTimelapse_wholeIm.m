function [debug_outputs] =  generateTrainingSetTimelapse_wholeIm(cCellVision,cTimelapse,frame_ss,type,debugging)
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

ElcoWay = true; %boolean on whether to find training set Elco's way or Matt's way

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

trap1 = cTimelapse.returnSegmenationTrapsStack(1,cTimelapse.timepointsToProcess(1),'whole');

cCellVision.cTrap.currentTpOutline=ones([size(trap1{1},1) size(trap1{1},2)])>0;
features=getFilteredImage(cCellVision,trap1{1});

n_features=size(features,2);
total_num_timepoints=length(cTimelapse.cTimepoint);

num_frames=total_num_timepoints;

n_pos=num_frames*3000;
n_points=n_pos+cCellVision.negativeSamplesPerImage*num_frames;
cCellVision.trainingData.features=zeros(n_points,n_features,'double')-100;
cCellVision.trainingData.class=zeros(1,n_points,'double')-100;


n_points=[];
tic; time=toc;

if strcmp(cTimelapse.fileSoure,'swain-batman') && cTimelapse.magnification==60;
    se_edge=strel('disk',9);
else
    se_edge=strel('disk',20);
end

se1 = strel('disk',1);
se2 = strel('disk',2);
se3 = strel('disk',3);
se4 = strel('disk',4);
se5 = strel('disk',5);
se6 = strel('disk',6);

trapOutlineTemp=imerode(cCellVision.cTrap.trapOutline,se2);
trapOutlineTemp2=cCellVision.cTrap.trapOutline;
for timepoint=1:frame_ss:total_num_timepoints
    traps=1:length(cTimelapse.cTimepoint(timepoint).trapInfo);
    image=cTimelapse.returnSegmenationTrapsStack(traps,timepoint,'whole');
    elapsed_t=toc-time;
    disp([ 'Frame ', int2str(timepoint),'    '])
    disp(['Time ', num2str(elapsed_t)])
    
    
    
    bb=max(size(image{1}));
    trapCenters=zeros([2*bb+size(image{1},1) 2*bb+size(image{1},2)]);
    for k=1:length(traps)
        trapCenters(round(cTimelapse.cTimepoint(timepoint).trapLocations(k).ycenter)+bb,round(cTimelapse.cTimepoint(timepoint).trapLocations(k).xcenter)+bb)=1;
    end
    insideTraps=conv2(trapCenters,single(trapOutlineTemp),'same');
    currentTpOutline=insideTraps(bb+1:bb+size(image{1},1),bb+1:bb+size(image{1},2));
    trapEdges=conv2(trapCenters,ones(size(trapOutlineTemp)),'same');
    insideTraps(trapEdges==0)=1;
    insideTraps=insideTraps(bb+1:bb+size(image{1},1),bb+1:bb+size(image{1},2));

    cCellVision.cTrap.currentTpOutline=currentTpOutline>0;
    features=getFilteredImage(cCellVision,image{1});

    
    %used to broaden the lines for more accurate classification
    %             trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
    bb=max(size(image{1}));
    wholeImClass=zeros([2*bb+size(image{1},1) 2*bb+size(image{1},2)]);
    wholeImNearCenter=zeros([2*bb+size(image{1},1) 2*bb+size(image{1},2)]);
    for trap=1:length(traps)
        if isfield(cTimelapse.cTimepoint(timepoint).trapInfo(trap),'cellRadius')
            trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
        else
            trapInfo=struct('cellRadius',[],'cellCenters',[]);
            if cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellsPresent
                trapInfo.cellRadius=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellRadius];
                tempy=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellCenter];
                trapInfo.cellCenters=reshape(tempy,[2 length(tempy)/2])';
            else
                trapInfo.cellCenters=[];
                trapInfo.cellRadius=[];
            end
        end
        
        training_class=zeros([size(cCellVision.cTrap.trap1,1) size(cCellVision.cTrap.trap1,2) length(trapInfo.cellRadius)+1]);
        nearCenterTraining=zeros([size(cCellVision.cTrap.trap1,1) size(cCellVision.cTrap.trap1,2) length(trapInfo.cellRadius)+1]);
        if size(trapInfo.cellRadius,1)>0
            for num_cells=1:length(trapInfo.cellRadius)
                training_class(round(trapInfo.cellCenters(num_cells,2)),round(trapInfo.cellCenters(num_cells,1)),num_cells)=1;
                nearCenterTraining(round(trapInfo.cellCenters(num_cells,2)),round(trapInfo.cellCenters(num_cells,1)),num_cells)=1;
                if trapInfo.cellRadius<6
                    training_class(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se2);
                    nearCenterTraining(:,:,num_cells)=training_class(:,:,num_cells);
%                     nearCenterTraining(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se1);
                elseif trapInfo.cellRadius<9
                    training_class(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se3);
                    nearCenterTraining(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se1);
                elseif trapInfo.cellRadius<14
                    training_class(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se3);
                    nearCenterTraining(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se1);
                elseif trapInfo.cellRadius<22
                    training_class(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se4);
                    nearCenterTraining(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se2);
                elseif trapInfo.cellRadius<27
                    training_class(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se5);
                    nearCenterTraining(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se3);
                else
                    training_class(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se6);
                    nearCenterTraining(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se4);
                end
            end
        end
        training_class=max(training_class,[],3);
        training_class=training_class>0;
        nearCenterTraining=max(nearCenterTraining,[],3);
        nearCenterTraining=nearCenterTraining>0;
        exclude_from_negs = nearCenterTraining;
        
        trapCenters=zeros([2*bb+size(image{1},1) 2*bb+size(image{1},2)]);
        trapCenters(round(cTimelapse.cTimepoint(timepoint).trapLocations(trap).ycenter)+bb,round(cTimelapse.cTimepoint(timepoint).trapLocations(trap).xcenter)+bb)=1;
        
        wholeImClass=wholeImClass | conv2(trapCenters,single(training_class),'same');
        wholeImNearCenter=wholeImNearCenter | conv2(trapCenters,single(nearCenterTraining),'same');
        
    end
%     wholeImClass=max(wholeImClass,[],3);
%     wholeImNearCenter=max(wholeImNearCenter,[],3);
    wholeImClass=wholeImClass(bb+1:bb+size(image{1},1),bb+1:bb+size(image{1},2));
    wholeImNearCenter=wholeImNearCenter(bb+1:bb+size(image{1},1),bb+1:bb+size(image{1},2));
    
    training_class=wholeImClass;
    %another option
    edge_im_all = false(size(image{1},1), size(image{1},2));
    for i=1:size(image{1},3)
        [edge_im thresh]=edge(max(image{1}(:,:,i),[],3),'canny');
        edge_im=imdilate(edge_im,se_edge);
        edge_im_all = edge_im | edge_im_all;
    end
    
    num_neg=cCellVision.negativeSamplesPerImage;
    % exclude regions that are inside the traps;
    neg_index=find(~wholeImNearCenter & edge_im>0 & ~insideTraps);
    %             neg_index=find(class==0 & ~insideTraps);
    if debugging
        neg_exclude_stack = cat(3,neg_exclude_stack,exclude_from_negs);
        positive_stack = cat(3,positive_stack,training_class);
        entry_index = cat(1,entry_index,[timepoint trap]);
    end
    if length(neg_index)>num_neg
        neg_perm=randperm(length(neg_index));
        class_temp=zeros(1,num_neg);
        output=features(neg_index(neg_perm(1:num_neg)),:);
        pos_index=find(training_class~=0);
        class_temp(1,end+1:end+length(pos_index))=ones(1,length(pos_index));
        output(end+1:end+length(pos_index),:)=features(pos_index,:);
        
        n_points=size(output,1);
        cCellVision.trainingData.features(index:index+n_points-1,:)=output;
        cCellVision.trainingData.class(1,index:index+n_points-1)=class_temp;
        index=index+n_points;
        if debugging
            temp_neg = false(size(image{1},1), size(image{1},2));
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
            temp_neg = false(size(image{1},1), size(image{1},2));
            temp_neg(neg_index) = true;
            negatives_stack = cat(3,negatives_stack,temp_neg);
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