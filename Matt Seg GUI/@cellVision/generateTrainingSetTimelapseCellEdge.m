function [debug_outputs] =  generateTrainingSetTimelapseCellEdge(cCellVision,cTimelapse,frame_ss,seg_method,debugging)
% [debug_outputs] =  generateTrainingSetTimelapseCellEdge(cCellVision,cTimelapse,frame_ss,seg_method,debugging)
%
% populates the trainingData property of the cellVision object with values
% obtained from the curated cTimelapse object provided
%
%  cCellVision  -   a cellVison object.
%  cTimelapse   -   a timelapseTraps object
%  frame_ss     -   step to take between images used in the curation. If
%                   larger than 1, some images will be left out of the
%                   curation set. Useful if the set is so large that memory
%                   is an issue.
%  seg_method   -   Handle to the function used to generate the features.
%                   Also used to populate the filterFunction property of
%                   cellVision.
%  debugging    -   If true, will provide an output (debug_outputs). These
%                   can be used to visualise the classes of pixels in the
%                   training set. May make thing a little slower.
%
% outcome is to populate the features property of the cellVision model.
% This is structure of 2 arrays:
%   features  -     an num_training_pixels x num_features array with each
%                   row being the features for a training pixel.
%   class     -     a num_training_pixels vector with a corresponding class
%                   for each pixel in the features array.

exclude_boundary_size = 10; % exclude pixels this close to the edge from consideration.


se_edge=strel('disk',30);
se1 = strel('disk',1);
se2 = strel('disk',2);

debug_outputs = {};
if nargin<3
    frame_ss=1;
end

if nargin<4
    seg_method='full';
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
cCellVision.filterFunction = seg_method;
cCellVision.TrainDataGenerationDate = date;

index=1;

trap1 = cTimelapse.returnSegmenationTrapsStack(1,cTimelapse.timepointsToProcess(1));

% just used to get feature size.
if cTimelapse.trapsPresent
    trapImage = cCellVision.cTrap.trapOutline*1;
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

% estimate the number of example pixels and preallocate.
% class is preallocated with negative numbers so that these can later be
% identified and removed.
n_pos = num_frames*100;
n_points=n_pos+cCellVision.negativeSamplesPerImage*num_frames;
cCellVision.trainingData.features=zeros(n_points,n_features)-100;
cCellVision.trainingData.class=zeros(1,n_points)-100;

tic; time=toc;

for timepoint=1:frame_ss:length(cTimelapse.cTimepoint)
    traps=1:length(cTimelapse.cTimepoint(timepoint).trapInfo);
    image=cTimelapse.returnSegmenationTrapsStack(traps,timepoint,cCellVision.imageProcessingMethod);
    for trap=1:max(traps)
        elapsed_t=toc-time;
        disp(['Trap ', int2str(trap), 'Frame ', int2str(timepoint)])
        disp(['Time ', num2str(elapsed_t)])
        
        if cTimelapse.trapsPresent
            if isfield(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1), 'refinedTrapPixelsInner') && ~isempty(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1).refinedTrapPixelsInner)
                % If it has been populated, use the refined trap image to create a trap
                % Image which is 1 at the trap centre and 0.5 at the trap edge.
                trapImage = 0.5*(full(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1).refinedTrapPixelsInner) + ...
                    full(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo(1).refinedTrapPixelsBig));
            else
                trapImage = cCellVision.cTrap.trapOutline*1;
            end
        else
            trapImage = zeros(size(cTimelapse.defaultTrapDataTemplate));
        end
        
        allTrapPixels = trapImage>0;
        features = getFilteredImage(cCellVision,image{trap},trapImage);
        trapInfo = cTimelapse.cTimepoint(timepoint).trapInfo(trap);
        
        % logical of pixels not to include in negatives (background)
        % training set starts with just all trap pixels.
        % trap pixels are excluded from the training set since they are
        % manually excluded anyway, and their similarity to cells may
        % impair the classifier.
        exclude_from_negs = allTrapPixels;
        
        % trapInnerLog is a logical array of the area between the
        % pillars. If it has been calculated, draw many negative
        % samples from this region.
        if isfield(cCellVision.cTrap,'trapInnerLog')
            % logical array of pixels to make sure are in the negative
            % (background) training set.
            fix_in_negs = cCellVision.cTrap.trapInnerLog;
        else
            fix_in_negs = false([size(exclude_from_negs,1),size(exclude_from_negs,2)]);
        end
        
        %%%%%% GO FROM HERE
        
        % how many (dilated) cells a pixel occurs in
        all_cell_im = false([size(image{trap},1) size(image{trap},2)]);
        all_cell_edge_im = all_cell_im;
        all_cell_centre_im = all_cell_im;
        all_cell_big_edge_im = all_cell_im;
        
        % exclude pixel from the image edge in training.
        exclude_boundary = true(size(all_cell_im));
        exclude_boundary((exclude_boundary_size+1):(end - exclude_boundary_size),...
            (exclude_boundary_size+1):(end - exclude_boundary_size)) = false;
        
        if trapInfo.cellsPresent && ~isempty(trapInfo.cell)
            for num_cells=1:length(trapInfo.cell)
                if ~isempty(trapInfo.cell(num_cells).cellCenter)
                    % extract edge/interior of cell by  various erosions
                    % and dilations.
                    cell_im =  imfill(full(trapInfo.cell(num_cells).segmented),'holes');
                    % make sure the central pixel is part of the training
                    % set and is not eroded away later.
                    all_cell_centre_im(round(trapInfo.cell(num_cells).cellCenter(2)),round(trapInfo.cell(num_cells).cellCenter(1))) = true;
                    all_cell_edge_im = all_cell_edge_im | (cell_im - imerode(cell_im,se1));
                    all_cell_big_edge_im = all_cell_big_edge_im |  (imdilate(cell_im,se1) -cell_im);
                    all_cell_im = all_cell_im | cell_im;
                    all_cell_centre_im = all_cell_centre_im | imerode(cell_im,se2);
                    
                end
            end
        end
        training_class=zeros(size(exclude_from_negs));
        % centres are labelled 1
        training_class(all_cell_centre_im) = 1;
        % edges are labelled 2
        training_class(all_cell_edge_im) = 2;
        
        % exclude cells  and the area directly around cells
        % (all_cell_big_edge_im) from negative set.
        exclude_from_negs = exclude_from_negs | all_cell_im | all_cell_big_edge_im;
        
        % exclude pixels right next to the cells from the negative training
        % set to try and make classification more robust
        exclude_from_negs = exclude_from_negs | exclude_boundary;
        % ensure pixels on cell boundary are included in negatives if
        % the are not in exclusion zone
        fix_in_negs = fix_in_negs & ~exclude_from_negs;
        
        
        
        % identify an 'edgy' image and take negatives from close to this.
        % Especially important when there are no traps.
        edge_im_all = false(size(image{1},1), size(image{1},2));
        for i=1:size(image{trap},3)
            [edge_im, thresh]=edge(image{trap}(:,:,i),'canny');
            edge_im=imdilate(edge_im,se_edge);
            edge_im_all = edge_im | edge_im_all;
        end
        
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
        
        % take negative (background) samples first from the pixels fixed to
        % be in the negative sample (neg_index_fixed) and then from random
        % pixels in the rest of the candidate negative pixel region.
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

% remove any elements in the training data that were preallocated but never
% filled (these have a negative class).
non_entries=find(cCellVision.trainingData.class<0);
cCellVision.trainingData.class(non_entries)=[];
cCellVision.trainingData.features(non_entries,:)=[];

% normalise features and store the normalisation.
cCellVision.scaling.min=min(cCellVision.trainingData.features);
cCellVision.scaling.max=max(cCellVision.trainingData.features);

loc=find(cCellVision.scaling.max==cCellVision.scaling.min);
cCellVision.scaling.max(loc)=cCellVision.scaling.max(loc)+1;

cCellVision.trainingData.features=(cCellVision.trainingData.features - repmat(cCellVision.scaling.min,size(cCellVision.trainingData.features,1),1));
cCellVision.trainingData.features=cCellVision.trainingData.features*spdiags(1./(cCellVision.scaling.max-cCellVision.scaling.min)',0,size(cCellVision.trainingData.features,2),size(cCellVision.trainingData.features,2));
end