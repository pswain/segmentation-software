function generateTrainingSetTimelapseCellEdge(cCellVision,cTimelapse,frame_ss,type)
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

if nargin<3
    frame_ss=1;
end

if nargin<4
    type='full';
end

cCellVision.training_channels = cTimelapse.channelNames(cTimelapse.channelsForSegment);

cCellVision.filterFunction = type;

index=1;

trap1 = cTimelapse.returnSegmenationTrapsStack(1,cTimelapse.timepointsToProcess(1));

features=getFilteredImage(cCellVision,trap1{1});

n_features=size(features,2);
total_num_timepoints=length(cTimelapse.cTimepoint);
num_frames=0;
for i=1:total_num_timepoints
    num_frames=num_frames+length(cTimelapse.cTimepoint(i).trapInfo);
end


n_pos=num_frames*100;
n_points=n_pos+cCellVision.negativeSamplesPerImage*num_frames;
cCellVision.trainingData.features=zeros(n_points,n_features)-100;
cCellVision.trainingData.class=zeros(1,n_points)-100;


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

if ~isempty(cCellVision.cTrap)
    insideTraps=imdilate(cCellVision.cTrap.trapOutline,se2);
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

            %used to broaden the lines for more accurate classification
            %             trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
            
            if isfield(cTimelapse.cTimepoint(timepoint).trapInfo(trap),'cell')
                trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
            end
            
            
            training_class=zeros([size(image{trap},1) size(image{trap},2)]);
            nearCenterTraining=zeros([size(image{trap},1) size(image{trap},2)]);
            if trapInfo.cellsPresent
                for num_cells=1:length(trapInfo.cell)
                    tempTraining=zeros(size(image{trap}));
                    tempTraining(trapInfo.cell(num_cells).segmented)=1;
                    if trapInfo.cell(num_cells).cellRadius>4 & trapInfo.cell(num_cells).cellRadius<10
%                         tempNearTraining=imdilate(tempTraining,se1);
                        tempNearTraining=tempTraining;

                    else
                        tempTraining=imdilate(tempTraining,se1);
                        tempNearTraining=imdilate(tempTraining,se1);
                    end
                    training_class(tempTraining>0)=1;
                    nearCenterTraining(tempNearTraining>0)=1;
                end
            end
            training_class=training_class>0;
            nearCenterTraining=nearCenterTraining>0;

            %exclude pixels around right next to centre pixels to try and
            %make classification more robust
%             exclude_from_negs = imdilate(training_class,se1);
            exclude_from_negs = nearCenterTraining;

%             tempy=image(:,:,trap);
%             tempy(class)=tempy(class)*2;
%             imshow(tempy,[],'Parent',fig1);pause(.01);

            
            %             se=strel('disk',8);
%             edge_im=ones(size(image,1),size(image,2));

            %this is a bit of a fudge and one should probably do something
            %more clever to find the pixels to pick from than this
            
%             edge_im=imdilate(training_class,se_edge);
            
            %another option
            [edge_im thresh]=edge(max(image{trap},[],3),'canny');
            edge_im=imdilate(edge_im,se_edge);

            %or just make everything an option
%             edge_im=ones(size(image,1),size(image,2));
            
            num_neg=cCellVision.negativeSamplesPerImage;
            % exclude regions that are inside the traps;
            neg_index=find(exclude_from_negs==0 & edge_im & ~insideTraps);
%             neg_index=find(class==0 & ~insideTraps);
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
            end
    end
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
