function cExperiment_orig =  append_cExperiment(cExperiment_orig, num_timepoints,location, append_name)
% cExperiment_orig =  append_cExperiment(cExperiment_orig, num_timepoints,location, append_name)
% adds positions from one cExperiment to another. If num_timepoints is
% specified, it will take that many timepoints from the new cExperiment
% distributed evenly over the old cExperiment positions.
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
% written by Elco

if nargin<3 || isempty(location)
    fprintf('\n\n please select a cExperiment file you would like to append to the new one \n \n');
    [file,path] = uigetfile;
    location = fullfile(path,file);
end

if nargin<4 || isempty(append_name)
    if isempty(cExperiment_orig)
        append_name = '';
    else
    end
    append_name = num2str(randi(1000,1));
    
end

% set to false if you don't want to refine the trap outline but hard to do
% later.
refine_trap_outline = true;

delete_extractedData = true;

l1 = load(location);
cExperiment_new = l1.cExperiment;
cExperiment_new.cCellVision = l1.cCellVision;

if isempty(cExperiment_orig)
    l1 = load(location);
    cExperiment_orig = l1.cExperiment;
    cExperiment_orig.cCellVision = l1.cCellVision;
    fprintf('\n\n please select a location for the reduced cExperiment file\n\n')
    cExperiment_orig.saveFolder = uigetdir(cExperiment_orig.saveFolder);
    cExperiment_orig.dirs = {};
end

DirToUse = 1:length(cExperiment_new.dirs);
TPtoUse = ones(size(DirToUse));

if length(cExperiment_new.dirs)>num_timepoints
    
    DirToUse = randperm(length(cExperiment_new.dirs));
    DirToUse = DirToUse(1:num_timepoints);
    TPtoUse = ones(size(DirToUse));
    
end

if length(cExperiment_new.dirs)<num_timepoints
    
    TPtoUse = floor(num_timepoints/length(cExperiment_new.dirs))*ones(size(DirToUse));
    remainder = mod(num_timepoints,length(cExperiment_new.dirs));
    if remainder>0
        
        assign_remainders = randperm(length(cExperiment_new.dirs));
        assign_remainders = assign_remainders(1:remainder);
        TPtoUse(assign_remainders) = TPtoUse(assign_remainders)+1; 
        
    end

end

cExperiment_new.dirs = cExperiment_new.dirs(DirToUse);
channel = 0;
for di = 1:length(cExperiment_new.dirs)

    cTimelapse = cExperiment_new.loadCurrentTimelapse(di);
    if delete_extractedData
        cTimelapse.extractedData = [];
    end
    TPs = randperm(length(cTimelapse.timepointsToProcess));
    TPs = cTimelapse.timepointsToProcess(TPs(1:min(TPtoUse(di),length(cTimelapse.timepointsToProcess))));
    cTimelapse.cTimepoint = cTimelapse.cTimepoint(TPs);
    cTimelapse.timepointsToProcess = 1:min(TPtoUse(di),length(cTimelapse.timepointsToProcess));
    if refine_trap_outline
        if channel==0
            [channel,OK_response] =  selectChannelGUI(cTimelapse,'Trap Refine Channel',...
                'please select a channel with which to refine the trap outline. Traps are expected to be bright with a dark halo. Cancel will prevent trap refinement',...
                false);
        end
        if OK_response
        cTimelapse.refineTrapOutline(cExperiment_new.cCellVision.cTrap.trapOutline,channel,[],[]);
        end
    end
    cExperiment_orig.dirs{end+1} = [append_name,cExperiment_new.dirs{di}];
    save(fullfile(cExperiment_orig.saveFolder , [append_name,cExperiment_new.dirs{di},'cTimelapse']),'cTimelapse')
    
end

cExperiment_orig.saveExperiment;
