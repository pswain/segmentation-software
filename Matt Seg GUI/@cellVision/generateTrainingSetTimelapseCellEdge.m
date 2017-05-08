function [debug_outputs] =  generateTrainingSetTimelapseCellEdge(cCellVision,cTimelapse,frame_ss,type,debugging)
% as CELLVISION.GENERATETRAININGSETTIMELAPSECELLEDGE but classifies the
% edge pixels separately. 
% type can be a string or a handle to a function. if a handle, expects
% cCellvision object and then image(or image stack)

% 
% DO NOT COMMIT
ElcoWay = true; %boolean on whether to find training set Elco's way or Matt's way
exclude_boundary_size = 10; % exclude pixels this close to the edge from consideration.

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
    outer_stack = [];
    inner_stack = [];
    entry_index = [];
    edge_stack = [];
end

cCellVision.training_channels = cTimelapse.channelNames(cTimelapse.channelsForSegment);
cCellVision.filterFunction = type;
cCellVision.TrainDataGenerationDate = date;

index=1;

trap1 = cTimelapse.returnSegmenationTrapsStack(1,cTimelapse.timepointsToProcess(1));
if cTimelapse.trapsPresent
    if isfield(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1), 'refinedTrapPixelsInner')
        trapImage = 0.5*(full(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1).refinedTrapPixelsInner) + ...
            full(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1).refinedTrapPixelsBig));
    else
        trapImage = cCellVision.cTrap.trapOutline*1;
    end
else
    trapImage = zeros(size(cTimelapse.defaultTrapDataTemplate));
end
features=getFilteredImage(cCellVision,trap1{1},trapImage);

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
    %se_edge=strel('disk',9);
    se_edge=strel('disk',30);
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
    insideTraps=imerode(cCellVision.cTrap.trapOutline,se2);
else
    insideTraps = false([size(trap1{1},1) size(trap1{1},2)]);
end
% figure;imshow(cTimelapse.returnSingleTrapTimepoint(1,1,1),[]);
% fig1=gca;
%for timepoint=1:frame_ss:total_num_timepoints

for timepoint=1:frame_ss:length(cTimelapse.cTimepoint)
    traps=1:length(cTimelapse.cTimepoint(timepoint).trapInfo);
    image=cTimelapse.returnSegmenationTrapsStack(traps,timepoint,cCellVision.imageProcessingMethod);
    for trap=1:max(traps)
        elapsed_t=toc-time;
        disp(['Trap ', int2str(trap), 'Frame ', int2str(timepoint)])
        disp(['Time ', num2str(elapsed_t)])
        
        if cTimelapse.trapsPresent
            if isfield(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1), 'refinedTrapPixelsInner') && ~isempty(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1).refinedTrapPixelsInner)
                trapImage = 0.5*(full(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1).refinedTrapPixelsInner) + ...
                    full(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1).refinedTrapPixelsBig));
                insideTraps = trapImage==1;
                
            else
                trapImage = cCellVision.cTrap.trapOutline*1;
            end
        else
            trapImage = zeros(size(cTimelapse.defaultTrapDataTemplate));
        end
        allTrapPixels = trapImage>0;
        features=getFilteredImage(cCellVision,image{trap},trapImage);
        
        
        
        if ~ElcoWay %Matt's way of getting cell centres. Elco is trying something different
            %used to broaden the lines for more accurate classification
            %             trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
            
            if isfield(cTimelapse.cTimepoint(timepoint).trapInfo(trap),'cellRadius')
                trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
            else
                trapInfo=struct('cellRadius',[],'cellCenters',[]);
                trapInfo.cellRadius=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellRadius];
                tempy=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellCenter];
                trapInfo.cellCenters=reshape(tempy,[2 length(tempy)/2])';
            end
            
            training_class=zeros([size(image{trap},1) size(image{trap},2) length(trapInfo.cellRadius)+1]);
            nearCenterTraining=zeros([size(image{trap},1) size(image{trap},2) length(trapInfo.cellRadius)+1]);
            if size(trapInfo.cellRadius,1)>0
                for num_cells=1:length(trapInfo.cellRadius)
                    training_class(round(trapInfo.cellCenters(num_cells,2)),round(trapInfo.cellCenters(num_cells,1)),num_cells)=1;
                    nearCenterTraining(round(trapInfo.cellCenters(num_cells,2)),round(trapInfo.cellCenters(num_cells,1)),num_cells)=1;
                    if trapInfo.cellRadius>4 & trapInfo.cellRadius<7
                        training_class(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se1);
                        nearCenterTraining(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se1);
                    elseif trapInfo.cellRadius<9
                        training_class(:,:,num_cells)=imdilate(training_class(:,:,num_cells),se2);
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
            fix_in_negs = false(size(exclude_from_negs));

            %exclude pixels around right next to centre pixels to try and
            %make classification more robust
            %             exclude_from_negs = imdilate(training_class,se1);
        end
        
        if ElcoWay
            trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo(trap);
            
            % not to include in negative (outside cell) training set 
            % starts with just all trap pixels
            exclude_from_negs = allTrapPixels;
            
            % trapInnerLog is a logical array of the area between the
            % pillars. If it has been calculated, draw many negative
            % samples from this region.
            if isfield(cCellVision.cTrap,'trapInnerLog')
                fix_in_negs = cCellVision.cTrap.trapInnerLog;
            else
                fix_in_negs = false([size(exclude_from_negs,1),size(exclude_from_negs,2)]);
            end
            
            % how many (dilated) cells a pixel occurs in
            all_cell_im = false([size(image{trap},1) size(image{trap},2)]);
            all_cell_edge_im = all_cell_im;
            all_cell_centre_im = all_cell_im;
            all_cell_big_edge_im = all_cell_im;
            
            % exclude pixel from the edge in training.
            exclude_boundary = true(size(all_cell_im));
            exclude_boundary((exclude_boundary_size+1):(end - exclude_boundary_size),...
                (exclude_boundary_size+1):(end - exclude_boundary_size)) = false;
            
            if trapInfo.cellsPresent && ~isempty(trapInfo.cell) %shouldn't be necessary in future
                for num_cells=1:length(trapInfo.cell)
                    if ~isempty(trapInfo.cell(num_cells).cellCenter)
                        cell_im =  imfill(full(trapInfo.cell(num_cells).segmented),'holes');
                        dist_im = bwdist(~cell_im);
                        dist_im = dist_im/max(dist_im(:));
                        all_cell_centre_im(round(trapInfo.cell(num_cells).cellCenter(2)),round(trapInfo.cell(num_cells).cellCenter(1))) = true;
                        all_cell_edge_im = all_cell_edge_im | (cell_im - imerode(cell_im,se1));
                        all_cell_big_edge_im = all_cell_big_edge_im |  (imdilate(cell_im,se1) -cell_im);
                        %all_cell_im = all_cell_im | imdilate(cell_im,se2);
                        all_cell_im = all_cell_im | cell_im;
                        %all_cell_centre_im = all_cell_centre_im | dist_im>0.4;
                        all_cell_centre_im = all_cell_centre_im | imerode(cell_im,se1);
                        
                    end
                end
            end
            training_class=zeros(size(exclude_from_negs));
            % centres are labelled 1
            training_class(all_cell_centre_im) = 1;
            % edges are labelled 2
            training_class(all_cell_edge_im) = 2;
            
            % exclude cells from negative set.
            exclude_from_negs = exclude_from_negs | all_cell_im;
            
            % exclude pixels around right next to centre pixels to try and
            % make classification more robust
            exclude_from_negs = exclude_from_negs | exclude_boundary;
            % ensure pixels on cell boundary are included in negatives if
            % the are not in exclusion zone
            fix_in_negs = fix_in_negs | all_cell_big_edge_im>0;
            fix_in_negs = fix_in_negs & ~exclude_from_negs;
            
        end
        
        
        edge_im_all = false(size(image{1},1), size(image{1},2));
        for i=1:size(image{trap},3)
            [edge_im, thresh]=edge(image{trap}(:,:,i),'canny');
            edge_im=imdilate(edge_im,se_edge);
            edge_im_all = edge_im | edge_im_all;
        end
        
        %or just make everything an option
        %             edge_im=ones(size(image,1),size(image,2));
        
        num_neg=cCellVision.negativeSamplesPerImage;
        % exclude regions that are inside the traps;
        neg_logical = ~exclude_from_negs & edge_im ;
        neg_logical = neg_logical & ~fix_in_negs;
        neg_logical(training_class>0) = false;
        neg_index_fixed=find(fix_in_negs);
        neg_index_rest = find(neg_logical);
        
        if debugging
            neg_exclude_stack = cat(3,neg_exclude_stack,exclude_from_negs);
            inner_stack = cat(3,inner_stack,all_cell_centre_im);
            entry_index = cat(1,entry_index,[timepoint trap]);
            edge_stack = cat(3,edge_stack,all_cell_edge_im);
            
        end
        if length(neg_index_fixed)>num_neg
            neg_perm=randperm(length(neg_index_fixed));
            final_neg_index = neg_index_fixed(neg_perm(1:num_neg));
        elseif length(neg_index_fixed)+length(neg_index_rest)>num_neg
            neg_perm=randperm(length(neg_index_rest));
            final_neg_index = [neg_index_fixed ; ...
                neg_index_rest(neg_perm(1:(num_neg - length(neg_index_fixed))))];
        else
            final_neg_index = [neg_index_fixed ; ...
                neg_index_rest];
        end
        num_neg_temp = length(final_neg_index);
        
        
        class_temp=zeros(1,num_neg_temp);
        output=features(final_neg_index,:);
        
        % add centres with label 1
        pos_index=find(training_class==1);
        class_temp(1,end+1:end+length(pos_index))=ones(1,length(pos_index));
        output(end+1:end+length(pos_index),:)=features(pos_index,:);
        
        %add edges with label 2
        edge_index=find(training_class==2);
        class_temp(1,end+1:end+length(edge_index))=2*ones(1,length(edge_index));
        output(end+1:end+length(edge_index),:)=features(edge_index,:);
        
        
        n_points=size(output,1);
        cCellVision.trainingData.features(index:index+n_points-1,:)=output;
        cCellVision.trainingData.class(1,index:index+n_points-1)=class_temp;
        index=index+n_points;
        if debugging
            temp_neg = false(size(image{trap},1), size(image{trap},2));
            temp_neg(final_neg_index) = true;
            outer_stack = cat(3,outer_stack,temp_neg);
        end
        
        
    end
end

if debugging
    
    debug_outputs{1} = outer_stack;
    debug_outputs{2} = inner_stack;
    debug_outputs{3} = neg_exclude_stack;
    debug_outputs{4} = entry_index;
    debug_outputs{5} = edge_stack;
else
    debug_outputs{1} = [];
end

non_entries=find(cCellVision.trainingData.class<0);
cCellVision.trainingData.class(non_entries)=[];
cCellVision.trainingData.features(non_entries,:)=[];



cCellVision.scaling.min=min(cCellVision.trainingData.features);
cCellVision.scaling.max=max(cCellVision.trainingData.features);

loc=find(cCellVision.scaling.max==cCellVision.scaling.min);
cCellVision.scaling.max(loc)=cCellVision.scaling.max(loc)+1;
%
cCellVision.trainingData.features=(cCellVision.trainingData.features - repmat(cCellVision.scaling.min,size(cCellVision.trainingData.features,1),1));
cCellVision.trainingData.features=cCellVision.trainingData.features*spdiags(1./(cCellVision.scaling.max-cCellVision.scaling.min)',0,size(cCellVision.trainingData.features,2),size(cCellVision.trainingData.features,2));
end