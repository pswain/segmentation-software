function cExperiment_orig =  append_cExperiment(cExperiment_orig, DirToAdd, num_timepoints,location, append_name,delete_extractedData,changeChannelNames)
% cExperiment_orig = append_cExperiment(cExperiment_orig, DirToAdd, num_timepoints,location, append_name)
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
% cExperiment_orig          :   cExperiment to which positions are added
% DirToAdd                  :   directories to use in adding (defaults to
%                               all). If empty, starts with this one.
% num_timepoints            :   total number of timepoints to add
%                               distributed evenly over positions
% location                  :   file location of experiment to be added.
%                               Requested by GUI if absent.
% append_name               :   name added to position to identify them
% delete_extracted_data     :   boolean. whether to delete extracted data
%                               from the cTimelapses when saving
%
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

if nargin<6 || isempty(changeChannelNames)
    changeChannelNames = true;
end


l1 = load(location);
cExperiment_new = l1.cExperiment;
cExperiment_new.cCellVision = l1.cCellVision;

if nargin<2 || isempty(DirToAdd)
    
    [DirToAdd] = listdlg('Liststring',cExperiment_new.dirs,'SelectionMode','muliple',...
        'Name','Positions To Append','PromptString','Please select the positions from the new cExperiment to add to the existing cExperiment');
    
    
end
TPtoUse = ones(size(DirToAdd));

if isempty(cExperiment_orig)
    l1 = load(location);
    cExperiment_orig = l1.cExperiment;
    cExperiment_orig.cCellVision = l1.cCellVision;
    fprintf('\n\n please select a location for the reduced cExperiment file\n\n')
    cExperiment_orig.saveFolder = uigetdir(cExperiment_orig.saveFolder);
    cExperiment_orig.dirs = {};
end

if length(cExperiment_new.dirs)>num_timepoints
    
    DirToAdd = randperm(length(cExperiment_new.dirs));
    DirToAdd = DirToAdd(1:num_timepoints);
    TPtoUse = ones(size(DirToAdd));
    
end

if length(cExperiment_new.dirs)<num_timepoints
    
    TPtoUse = floor(num_timepoints/length(cExperiment_new.dirs))*ones(size(DirToAdd));
    remainder = mod(num_timepoints,length(cExperiment_new.dirs));
    if remainder>0
        
        assign_remainders = randperm(length(cExperiment_new.dirs));
        assign_remainders = assign_remainders(1:remainder);
        TPtoUse(assign_remainders) = TPtoUse(assign_remainders)+1; 
        
    end

end

cExperiment_new.dirs = cExperiment_new.dirs(DirToAdd);

for di = 1:length(cExperiment_new.dirs)

    cTimelapse = cExperiment_new.loadCurrentTimelapse(di);
    if delete_extractedData
        cTimelapse.extractedData = [];
    end
    
    %set field names to be consistent across experiments
    if changeChannelNames
        cTimelapse.channelNames = cExperiment_orig.channelNames;
    end
    % select random timepoints but maintain order
    TPs_index = randperm(length(cTimelapse.timepointsToProcess));
    TPs = sort(cTimelapse.timepointsToProcess(TPs_index(1:min(TPtoUse(di),length(cTimelapse.timepointsToProcess)))));
    
    cTimelapse.cTimepoint = cTimelapse.cTimepoint(TPs);
    cTimelapse.timepointsToProcess = 1:min(TPtoUse(di),length(cTimelapse.timepointsToProcess));
    cTimelapse.timepointsProcessed = false(size(cTimelapse.timepointsToProcess));
    cExperiment_orig.dirs{end+1} = [append_name,cExperiment_new.dirs{di}];
    save(fullfile(cExperiment_orig.saveFolder , [append_name,cExperiment_new.dirs{di},'cTimelapse']),'cTimelapse')
    
end

cExperiment_orig.saveExperiment;
