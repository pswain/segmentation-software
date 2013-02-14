function generateTrainingSet2Stage(cCellSVM,cDictionary,frame_ss)

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

s_strel = strel('disk',0);

index=1;

index=1;
features=cCellSVM.createImFilterSetCellTrap(cDictionary.cTrap(1).image(:,:,1));
n_features=size(features,2);
n_points=0;
total_num_frames=0;
num_neg=100;

for i=1:size(cDictionary.labelledSoFar,1)
    for j=1:frame_ss:size(cDictionary.labelledSoFar,2)
        if cDictionary.labelledSoFar(i,j)
            temp_im=imdilate(cDictionary.cTrap(i).class(:,:,j),s_strel);
            n_points=n_points+sum(temp_im(:));
            total_num_frames=total_num_frames+1;
        end
    end
end


n_points=n_points+num_neg*total_num_frames;
cCellSVM.trainingData.kernel_features=zeros(n_points,n_features)-100;
cCellSVM.trainingData.kernel_class=zeros(1,n_points)-100;


n_points=[];
tic; time=toc;

se_edge=strel('disk',10);
se1 = strel('disk',1);

index=1;

tic
for i=1:size(cDictionary.labelledSoFar,1)
    for j=1:frame_ss:size(cDictionary.labelledSoFar,2)
        if cDictionary.labelledSoFar(i,j)
            elapsed_t=toc-time;
            disp(sprintf('Trap %d', i, 'Frame %d', j))
            disp(sprintf('Time %d', elapsed_t))
            
            
            [p_im d_im features]=cCellSVM.classifyImageLinear(cDictionary.cTrap(i).image(:,:,j));
            
            
            temp_im=imdilate(cDictionary.cTrap(i).class(:,:,j)==1,s_strel);
            class=temp_im(:);
            
            bw_im=d_im<cCellSVM.twoStageThresh;
%             bw_im=imdilate(bw_im,se1);
            dif_loc=find(bw_im);
            
            neg_index=find(class==0 & bw_im(:));
            if length(neg_index)>num_neg
                neg_perm=randperm(length(neg_index));
                class_temp=zeros(1,num_neg);
                output=features(neg_index(neg_perm(1:num_neg)),:);
                pos_index=find(class~=0);
                class_temp(1,end+1:end+length(pos_index))=ones(1,length(pos_index));
                output(end+1:end+length(pos_index),:)=features(pos_index,:);

                
                n_points=size(output,1);
                cCellSVM.trainingData.kernel_features(index:index+n_points-1,:)=output;
                cCellSVM.trainingData.kernel_class(1,index:index+n_points-1)=class_temp;
                index=index+n_points;
            else
                neg_perm=randperm(length(neg_index));
                class_temp=zeros(1,length(neg_index));
                output=features(neg_index,:);
                
                pos_index=find(class~=0);
                class_temp(1,end+1:end+length(pos_index))=class(pos_index);
                output(end+1:end+length(pos_index),:)=features(pos_index,:);
                
                n_points=size(output,1);
                cCellSVM.trainingData.kernel_features(index:index+n_points-1,:)=output;
                cCellSVM.trainingData.kernel_class(1,index:index+n_points-1)=class_temp';
                index=index+n_points;
            end
            
            
            toc
        end
    end
end

% non_entries=find(kernel_class==-1000);
cCellSVM.trainingData.kernel_features=cCellSVM.trainingData.kernel_features(1:index-1,:);
cCellSVM.trainingData.kernel_class=cCellSVM.trainingData.kernel_class(1:index-1);

