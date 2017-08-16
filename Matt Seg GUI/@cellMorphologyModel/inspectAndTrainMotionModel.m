function inspectAndTrainMotionModel(cCellMorph,radius_bins)
% inspectAndTrainMotionModel(cCellMorph,radius_bins)
% 
% trains the motion model (how cells move in the traps) from curated data.
% expect the data training data to already be populated
% (CELLMORPHOLOGYMODEL.EXTRACTTRAININGDATAFROMEXPERIMENT)
%
% radius_bins   -   the edges of the radius bins used to sort the cell for
%                   training the sizeLookUpTable. If not provided it is
%                   taken from the data.
%
% shows 2 guis and 1 plot:
% log(flowLookUpTable) - set of motion priors for cells in different
% regions of the trap.
% log(sizeLookUpTable) - set of motion priors for cells in the different
% size categories determined by radius_bins.
% plot of size o each cell with the distance moved. radius_bins edges also
% shown. Intended to show if you have cells with very different movement
% behaviours.
% NOTE: radius_bins(1) is always set to -Inf and radius_bins(end) is always
% set to Inf to ensure all cells have a size based component to their
% motion prior.
% See also, JBTEST,CELLMORPHOLOGYMODEL.EXTRACTTRAININGDATAFROMEXPERIMENT

centre_array_tp1 = cCellMorph.location_arrays{1};
centre_array_tp2 = cCellMorph.location_arrays{2};

radii_array_tp1 = cCellMorph.radii_arrays{1};

trap_index_array = cCellMorph.trap_index_array;

% remove points not in both

to_remove = any(centre_array_tp1==0,2) | any(centre_array_tp2==0,2);

centre_array_tp1(to_remove,:) = [];
centre_array_tp2(to_remove,:) = [];

radii_array_tp1(to_remove,:) = [];

trap_index_array(to_remove) = [];

% get location of cells in location map

% for each trap that was used in obtaining the training data set, get the
% trap_map (the division into broad areas) and find the area in which each
% cell is at tp1. This is the loc vector.
% This is equivalent to what will be done in the segmentation to decide the
% motion prior.
location_index = zeros(size(trap_index_array));
mean_radius_tp1 = mean(radii_array_tp1,2);

% if radius bins was not provided, make is a regular array.
if nargin<2 || isempty(radius_bins)
    radius_bins = linspace(min(mean_radius_tp1),max(mean_radius_tp1),6);
end
radius_bins(1) =0;
radius_bins(end) = Inf;
    
min_radius = floor(min(mean_radius_tp1));
for ti = 1:size(cCellMorph.trap_array,3)
    trap_map = ACMotionPriorObjects.FlowInTrap.processTrapOutline(cCellMorph.trap_array(:,:,ti),min_radius);
    cells_to_use = trap_index_array==ti;
    index = centre_array_tp1(cells_to_use,2) + size(trap_map,1)*(centre_array_tp1(cells_to_use,1)-1);
    location_index(cells_to_use) = trap_map(index);
end


%%% get move

size_sub_image = [size(cCellMorph.trap_array,1),size(cCellMorph.trap_array,2)];
centre_point = ceil(size_sub_image/2);

move = centre_array_tp2 - centre_array_tp1;
move_centred = move + repmat(centre_point,size(move,1),1);

% make into single indices
move_centred_ind = move_centred(:,2) + size_sub_image(1)*(move_centred(:,1)-1);

%%% make flowLookUpTable
% this is the part of the prior determined by the cells location in the
% trap.

flowLookUpTable = zeros([size_sub_image length(unique(location_index))]);

for i = unique(location_index)'
    to_use = location_index==i;
    temp_im = accumarray(move_centred_ind(to_use),ones(sum(to_use),1));
    temp_im(end+1: (size_sub_image(1)*size_sub_image(2))) = 0;
    temp_im = reshape(temp_im,size_sub_image);
    temp_im = double(temp_im)/sum(temp_im(:));
    flowLookUpTable(:,:,i) = temp_im;
    
    
end
% show flow lookup table

gui = GenericStackViewingGUI(log(flowLookUpTable+1));
gui.title = 'log flow look-up table';
fprintf('\n\n please close the gui when you have finished inspecting the flow look-up table \n\n')
uiwait()


%%% make sizeLookUpTable
figure;
plot(mean_radius_tp1,sqrt(sum(move.^2,2)),'ob');
hold on
ax =gca;
for ri =2:(length(radius_bins)-1)
    plot([1,1]*radius_bins(ri),ax.YLim,'-r')
end
hold off
xlabel('cell radius')
ylabel('norm of move')
legend({'training data','radius bin edges'})
sizeLookUpTable = zeros([size_sub_image (length(radius_bins)-1)]);

radius_bins(1) = -Inf;
radius_bins(end) = Inf;

for i = 1:(length(radius_bins)-1)
    to_use = mean_radius_tp1>radius_bins(i) & mean_radius_tp1<=radius_bins(i+1);
    temp_im = accumarray(move_centred_ind(to_use),ones(sum(to_use),1));
    temp_im(end+1: (size_sub_image(1)*size_sub_image(2))) = 0;
    temp_im = reshape(temp_im,size_sub_image);
    temp_im = double(temp_im)/sum(temp_im(:));
    sizeLookUpTable(:,:,i) = temp_im;

end
gui = GenericStackViewingGUI(log(sizeLookUpTable+1));
gui.title = 'log size look-up table';
fprintf('\n\n please close the gui when you have finished inspecting the size look-up table \n\n')
uiwait()

cCellMorph.motion_model = struct('flowLookUpTable',flowLookUpTable,...
                                 'sizeLookUpTable',sizeLookUpTable,...
                                 'radius_bins',radius_bins);
end

