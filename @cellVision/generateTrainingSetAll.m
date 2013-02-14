function generateTrainingSetAll(cCellSVM,cDictionary,frame_ss)


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

for i=1:size(cDictionary.labelledSoFar,1)
    for j=1:frame_ss:size(cDictionary.labelledSoFar,2)
        if cDictionary.labelledSoFar(i,j)
            temp_im=imdilate(cDictionary.cTrap(i).class(:,:,j),s_strel);
            n_points=n_points+sum(temp_im(:));
            total_num_frames=total_num_frames+1;
        end
    end
end
n_points=n_points+cCellSVM.negativeSamplesPerImage*total_num_frames;
cCellSVM.trainingData.features=zeros(n_points,n_features)-100;
cCellSVM.trainingData.class=zeros(1,n_points)-100;


n_points=[];
tic; time=toc;

se_edge=strel('disk',9);

for i=1:size(cDictionary.labelledSoFar,1)
    for j=1:frame_ss:size(cDictionary.labelledSoFar,2)
        if cDictionary.labelledSoFar(i,j)
            elapsed_t=toc-time;
            disp(['Trap ', int2str(i), 'Frame ', int2str(j)])
            disp(['Time ', num2str(elapsed_t)])
            
            
            features=cCellSVM.createImFilterSetCellTrap(cDictionary.cTrap(i).image(:,:,j));
            
            
            %used to broaden the lines for more accurate classification
            temp_im=imdilate(cDictionary.cTrap(i).class(:,:,j)==1,s_strel);
            class=temp_im(:);
            
                        [edge_im thresh]=edge(cDictionary.cTrap(i).image(:,:,j),'canny');
            %             se=strel('disk',8);
            %             edge_im=imdilate(edge_im,se);
%             edge_im=ones(size(image,1),size(image,2));
            edge_im=imdilate(edge_im,se_edge);
            
            num_neg=cCellSVM.negativeSamplesPerImage;
            neg_index=find(class==0 & edge_im(:));
            if length(neg_index)>num_neg
                neg_perm=randperm(length(neg_index));
                class_temp=zeros(1,num_neg);
                output=features(neg_index(neg_perm(1:num_neg)),:);
                pos_index=find(class~=0);
                class_temp(1,end+1:end+length(pos_index))=ones(1,length(pos_index));
                output(end+1:end+length(pos_index),:)=features(pos_index,:);
                
                n_points=size(output,1);
                cCellSVM.trainingData.features(index:index+n_points-1,:)=output;
                cCellSVM.trainingData.class(1,index:index+n_points-1)=class_temp;
                index=index+n_points;
            else
                neg_perm=randperm(length(neg_index));
                class_temp=zeros(1,length(neg_index));
                output=features(neg_index,:);
                
                pos_index=find(class~=0);
                class_temp(1,end+1:end+length(pos_index))=class(pos_index);
                output(end+1:end+length(pos_index),:)=features(pos_index,:);
                
                n_points=size(output,1);
                cCellSVM.trainingData.features(index:index+n_points-1,:)=output;
                cCellSVM.trainingData.class(1,index:index+n_points-1)=class_temp';
                index=index+n_points;
            end
        end
    end
end


non_entries=find(cCellSVM.trainingData.class<0);
cCellSVM.trainingData.class(non_entries)=[];
cCellSVM.trainingData.features(non_entries,:)=[];
[r c]=find(cCellSVM.trainingData.features==Inf)
[r c]=find(cCellSVM.trainingData.features==NaN)



cCellSVM.scaling.min=min(cCellSVM.trainingData.features);
cCellSVM.scaling.max=max(cCellSVM.trainingData.features);
%
cCellSVM.trainingData.features=(cCellSVM.trainingData.features - repmat(cCellSVM.scaling.min,size(cCellSVM.trainingData.features,1),1));
cCellSVM.trainingData.features=cCellSVM.trainingData.features*spdiags(1./(cCellSVM.scaling.max-cCellSVM.scaling.min)',0,size(cCellSVM.trainingData.features,2),size(cCellSVM.trainingData.features,2));
