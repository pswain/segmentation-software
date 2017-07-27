function cExperiment_orig =  append_cExperiment(cExperiment_orig, pos_to_add, num_timepoints,location, append_name,delete_extractedData,change_channel_names,do_pairs)
% cExperiment_orig = append_cExperiment(cExperiment_orig, pos_to_add, num_timepoints,location, append_name,delete_extractedData,change_channel_names,do_pairs)
%
% adds positions 'DirToAdd' from one cExperiment to another. If num_timepoints is
% specified, it will take that many timepoints from the new cExperiment
% distributed evenly over the old cExperiment positions to be added.
% the positions are trimmed to just the desired timepoints and appended to
% the new cExperiment as new positions.
%
% if cExperiment_orig is empty it will cutdown the timepoints and what not
% but just save the cExperiment in a new location. Good if it is the first
% cExperiment.
%
% if you want all position and timepoints set num_timepoints to Inf.
%
% this is all designed for training cellVision models, so that successive
% cExperiments can be added together to make a ground truth from numerous
% experiments.
%
% inputs:
% cExperiment_orig          :   cExperiment to which positions are added if
%                               this is empty, the experiment being added
%                               will become cExperiment_orig and a save
%                               location for it will be requested.
% pos_to_add                :   positions from the new experiment to
%                               append. If empty they will be selected by GUI.
% num_timepoints            :   total number of timepoints to add
%                               distributed evenly over positions (see
%                               footnote)
% location                  :   file location of cExperiment to be appended.
%                               Requested by GUI if absent or empty.
% append_name               :   name added to position to identify them. If
%                               empty this will be a random number.
% delete_extracted_data     :   boolean. whether to delete extracted data
%                               from the cTimelapses when saving. This can
%                               make the loading rather faster and
%                               extractedData is useless when the
%                               purpose of the cExperiment is training a
%                               cCellVision.
% change_channel_names      :   if true, change cTimelapse.channelNames to
%                               cExperiment_orig.channelNames. Handy for
%                               processing. 
% do_pairs                  :   if true, takes timepoints in pairs of n and
%                               n+1 (when randomly selected). This will
%                               result in double the number of timepoints.
%                               This is primarily used if the cExperiment
%                               will be used for training a shape space
%                               model.
%
% * There is a slight caveat on num_timepoints. If num_timpoints is Inf,
% nothing will be done to modify the timepoints. If it is less than Inf,
% sub sets will be selected only from those labelled as 'toProcess' in
% cTimelapse.timepointToProcess. This means that even if all the timepoints
% are taken, only those labelled as 'toProcess' will remain after the fuse
% (unless num_timpoint ==Inf)
% written by Elco

if nargin<3 || isempty(num_timepoints)
    num_timepoints = Inf;
end

if nargin<4 || isempty(location)
    fprintf('\n\n please select a cExperiment file you would like to append to the new one \n \n');
    [file,path] = uigetfile;
    location = fullfile(path,file);
end


if nargin<5 || isempty(append_name)
    if isempty(cExperiment_orig)
        append_name = '';
    else
        append_name = num2str(randi(1000,1));
    end
    
end

if nargin<6 || isempty(delete_extractedData)
    delete_extractedData = true;
end

if nargin<7 || isempty(change_channel_names)
    change_channel_names = true;
end

if nargin<8 || isempty(do_pairs)
    do_pairs = false;
end


l1 = load(location);
cExperiment_new = l1.cExperiment;
cExperiment_new.cCellVision = l1.cCellVision;

if nargin<2 || isempty(pos_to_add)
    [pos_to_add] = listdlg('Liststring',cExperiment_new.dirs,'SelectionMode','muliple',...
        'Name','Positions To Append','PromptString','Please select the positions from the new cExperiment to add to the existing cExperiment'); 
end
TPtoUse = ones(size(pos_to_add));

% if no cExperiment_orig has been provided, use the one being added but
% remove all the directories.
if isempty(cExperiment_orig)
    l1 = load(location);
    cExperiment_orig = l1.cExperiment;
    cExperiment_orig.cCellVision = l1.cCellVision;
    fprintf('\n\n please select a location for the reduced cExperiment file\n\n')
    cExperiment_orig.saveFolder = uigetdir(cExperiment_orig.saveFolder);
    cExperiment_orig.dirs = {};
    cExperiment_orig.cellInf = [];
end

% if there are more positions than timpoints to add, select a single
% timepoint from a random subset of the positions.
if length(pos_to_add)>num_timepoints
    
    pos_to_add = pos_to_add(randperm(length(pos_to_add)));
    pos_to_add = pos_to_add(1:num_timepoints);
    TPtoUse = ones(size(pos_to_add));
    
end

% if there are more timpoeints to add than positions, assign timepoints
% evenly as possible across all the positions.
if length(pos_to_add)<num_timepoints
    
    TPtoUse = floor(num_timepoints/length(cExperiment_new.dirs))*ones(size(pos_to_add));
    remainder = mod(num_timepoints,length(cExperiment_new.dirs));
    if remainder>0
        
        assign_remainders = randperm(length(cExperiment_new.dirs));
        assign_remainders = assign_remainders(1:remainder);
        TPtoUse(assign_remainders) = TPtoUse(assign_remainders)+1; 
        
    end

end

cExperiment_new.dirs = cExperiment_new.dirs(pos_to_add);

for di = 1:length(cExperiment_new.dirs)

    cTimelapse = cExperiment_new.loadCurrentTimelapse(di);
    if delete_extractedData
        cTimelapse.extractedData = [];
    end
    
    %set field names to be consistent across experiments
    if change_channel_names
        cTimelapse.channelNames = cExperiment_orig.channelNames;
    end
    
    if ~isinf(num_timepoints)
        
        % select random timepoints but maintain order
        if do_pairs
            TPs_index = randperm(length(cTimelapse.timepointsToProcess)-1);
            TPs_index = TPs_index(1:min(TPtoUse(di),length(cTimelapse.timepointsToProcess)));
            TPs_index = union(TPs_index,TPs_index+1);
        else
            TPs_index = randperm(length(cTimelapse.timepointsToProcess));
            TPs_index = TPs_index(1:min(TPtoUse(di),length(cTimelapse.timepointsToProcess)));
        end
        TPs = sort(cTimelapse.timepointsToProcess(TPs_index));
        
        cTimelapse.cTimepoint = cTimelapse.cTimepoint(TPs);
        cTimelapse.timepointsToProcess = 1:length(cTimelapse.cTimepoint);
        cTimelapse.timepointsProcessed = false(size(cTimelapse.timepointsToProcess));
    end
    cExperiment_orig.dirs{end+1} = [append_name,cExperiment_new.dirs{di}];
    save(fullfile(cExperiment_orig.saveFolder , [append_name,cExperiment_new.dirs{di},'cTimelapse']),'cTimelapse')
    
end

cExperiment_orig.saveExperiment;
