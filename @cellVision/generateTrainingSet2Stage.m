function generateTrainingSet2Stage(cCellVision,cTimelapse,frame_ss)

%% This is for the two stage classifier, first 
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

s_strel = strel('disk',1);
num_neg=300;


index=1;
if cTimelapse.trapsPresent
    features=cCellVision.createImFilterSetCellTrap(cTimelapse.returnSingleTrapTimepoint(1,1,1));
else
    features=cCellVision.createImFilterSetCellAsic(cTimelapse.returnSingleTrapTimepoint(1,1,1));
end
n_features=size(features,2);
total_num_timepoints=length(cTimelapse.cTimepoint);
num_frames=0;
for i=1:total_num_timepoints
    num_frames=num_frames+length(cTimelapse.cTimepoint(i).trapInfo);
end


n_pos=num_frames*100;
n_points=n_pos+num_neg*num_frames;
cCellVision.trainingData.kernel_features=zeros(n_points,n_features)-100;
cCellVision.trainingData.kernel_class=zeros(1,n_points)-100;


n_points=[];
tic; time=toc;

se_edge=strel('disk',9);
se1 = strel('disk',1);
se2 = strel('disk',2);
se3 = strel('disk',3);
se4 = strel('disk',4);
se5 = strel('disk',5);

% fig1=figure(10);

for timepoint=1:frame_ss:total_num_timepoints
    traps=1:length(cTimelapse.cTimepoint(timepoint).trapInfo);
    image=cTimelapse.returnTrapsTimepoint(traps,timepoint,1);
    for trap=1:max(traps)
            elapsed_t=toc-time;
            disp(sprintf('Trap %d', i, 'Frame %d', j))
            disp(sprintf('Time %d', elapsed_t))
            
            
            [p_im d_im features]=cCellVision.classifyImageLinear(image(:,:,trap));
            
            
            %used to broaden the lines for more accurate classification
%             trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
            trapInfo=struct('cellRadius',[],'cellCenters',[]);
            trapInfo.cellRadius=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellRadius];
            tempy=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellCenter];
            trapInfo.cellCenters=reshape(tempy,[2 length(tempy)/2])';
            class=zeros([size(image(:,:,trap)) length(trapInfo.cellRadius)+1]);
            
            if size(trapInfo.cellRadius,1)>0
                for num_cells=1:length(trapInfo.cellRadius)
                    class(round(trapInfo.cellCenters(num_cells,2)),round(trapInfo.cellCenters(num_cells,1)),num_cells)=1;
                    if trapInfo.cellRadius<11
                        class(:,:,num_cells)=imdilate(class(:,:,num_cells),se2);
                    elseif trapInfo.cellRadius<14
                        class(:,:,num_cells)=imdilate(class(:,:,num_cells),se3);
                    else
                        class(:,:,num_cells)=imdilate(class(:,:,num_cells),se4);
                    end      
                end
            end
            class=max(class,[],3);
            class=class>0;
%             tempy=image(:,:,trap);
%             tempy(class)=tempy(class)*2;
%             imshow(tempy,[],'Parent',fig1);
            
            
            bw_im=d_im<cCellVision.twoStageThresh;
            if cTimelapse.trapsPresent
                bw_im=imdilate(bw_im,se3);
            else
                bw_im=imdilate(bw_im,se5);
            end
            
            dif_loc=find(bw_im);
            
            neg_index=find(class==0 & bw_im);
            if length(neg_index)>num_neg
                neg_perm=randperm(length(neg_index));
                class_temp=zeros(1,num_neg);
                output=features(neg_index(neg_perm(1:num_neg)),:);
                pos_index=find(class~=0);
                class_temp(1,end+1:end+length(pos_index))=ones(1,length(pos_index));
                output(end+1:end+length(pos_index),:)=features(pos_index,:);

                
                n_points=size(output,1);
                cCellVision.trainingData.kernel_features(index:index+n_points-1,:)=output;
                cCellVision.trainingData.kernel_class(1,index:index+n_points-1)=class_temp;
                index=index+n_points;
            else
                neg_perm=randperm(length(neg_index));
                class_temp=zeros(1,length(neg_index));
                output=features(neg_index,:);
                
                pos_index=find(class~=0);
                class_temp(1,end+1:end+length(pos_index))=class(pos_index);
                output(end+1:end+length(pos_index),:)=features(pos_index,:);
                
                n_points=size(output,1);
                cCellVision.trainingData.kernel_features(index:index+n_points-1,:)=output;
                cCellVision.trainingData.kernel_class(1,index:index+n_points-1)=class_temp';
                index=index+n_points;
            end
            
            
            toc
    end
end

% non_entries=find(kernel_class==-1000);
cCellVision.trainingData.kernel_features=cCellVision.trainingData.kernel_features(1:index-1,:);
cCellVision.trainingData.kernel_class=cCellVision.trainingData.kernel_class(1:index-1);

