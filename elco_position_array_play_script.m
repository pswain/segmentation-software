% script for playing with the position data extracted from a curated data
% set of pairs

%% store original
original_radii_array_tp1 = radii_array_tp1;
original_radii_array_tp2 = radii_array_tp2;

original_centre_array_tp1 = centre_array_tp1;
original_centre_array_tp2 = centre_array_tp2;


%% reset

radii_array_tp1 = original_radii_array_tp1;
radii_array_tp2 = original_radii_array_tp2;

centre_array_tp1 = original_centre_array_tp1;
centre_array_tp2 = original_centre_array_tp2;

%% remove points not in both

to_remove = any(centre_array_tp1==0,2) | any(centre_array_tp2==0,2);

centre_array_tp1(to_remove,:) = [];
centre_array_tp2(to_remove,:) = [];

radii_array_tp1(to_remove,:) = [];
radii_array_tp2(to_remove,:) = [];


%% load cCellVision for the trapOutline

l1 = load('~/SkyDrive/Dropbox/MATLAB_DROPBOX/SegmentationSoftware/Matt Seg GUI/cCellvisionFiles/cCellVision_Elco_brightfield_oof_1_3_linear.mat');
trap_outline = l1.cCellVision.cTrap.trapOutline;
cCellVision = l1.cCellVision;

cCellVision.radiusLarge = 15;

l2 = load('~/Documents/microscope_files_swain_microscope_analysis/cCellVision_training/BF_OOF_24_25_30_pairs/cExperiment_curated/24th_pos12cTimelapse.mat');
cTimelapse = l2.cTimelapse;

%% FlowInTrap objec
% cut and pasted from flowInTrap

FT = ACMotionPriorObjects.FlowInTrap(cTimelapse,cCellVision);

loc_map = FT.locMap;
radius_bins = FT.radius_bins;

%%
imshow(OverlapGreyRed(loc_map,trap_outline,[],[],true),[])

%% get locs

% get the location of each sample, as its location from the first timepoint

index = centre_array_tp1(:,2) + size(trap_outline,1)*(centre_array_tp1(:,1)-1);
loc = loc_map(index);

%% get rs

rs = mean(radii_array_tp1,2);

%% get move

size_sub_image = cTimelapse.ACParams.CrossCorrelation.ProspectiveImageSize*[1 1];
centre_point = ceil(size_sub_image/2);

move = centre_array_tp2 - centre_array_tp1;
move_centred = move + repmat(centre_point,size(move,1),1);

move_centred_subs = move_centred(:,2) + size_sub_image(1)*(move_centred(:,1)-1);

%% make flowLookUpTable

smoothing_element = fspecial('gaussian',[5 5],1);

flowLookUpTable = zeros([size_sub_image length(unique(loc))]);

for i = unique(loc)'
    to_use = loc==i;
    temp_im = accumarray(move_centred_subs(to_use),ones(sum(to_use),1));
    temp_im(end+1: (size_sub_image(1)*size_sub_image(2))) = 0;
    temp_im = reshape(temp_im,size_sub_image);
    temp_im = double(temp_im)/sum(temp_im(:));
    
    %smooth
    if ~isempty(smoothing_element)
        temp_im = conv2(temp_im,smoothing_element,'same');
    end
    
    flowLookUpTable(:,:,i) = temp_im;
    
    
end
%%
gui = GenericStackViewingGUI(flowLookUpTable)

%% make sizeLookUpTable

smoothing_element = fspecial('gaussian',[5 5],1);

sizeLookUpTable = zeros([size_sub_image (length(radius_bins)-1)]);

radius_bins(1) = -Inf;
radius_bins(end) = Inf;

for i = 1:(length(radius_bins)-1)
    to_use = rs>radius_bins(i) & rs<=radius_bins(i+1);
    temp_im = accumarray(move_centred_subs(to_use),ones(sum(to_use),1));
    temp_im(end+1: (size_sub_image(1)*size_sub_image(2))) = 0;
    temp_im = reshape(temp_im,size_sub_image);
    temp_im = double(temp_im)/sum(temp_im(:));
    
    %smooth
    if ~isempty(smoothing_element)
        temp_im = conv2(temp_im,smoothing_element,'same');
    end
    
    sizeLookUpTable(:,:,i) = temp_im;
    
    
end

%%
gui = GenericStackViewingGUI(sizeLookUpTable)

%% save

%save('~/Documents/microscope_files_swain_microscope_analysis/cCellVision_training/BF_OOF_24_25_30_pairs/curated_centres_processed.mat')

