function new_location = copyExperiment(cExperiment,new_location)
% new_location = copyExperiment(cExperiment,new_location)
%
% copies all the cTimelapse files to a new locaiton, changing the
% saveFolder of cExperiment so that it won't overwrite the original.
    

if nargin<2 || isempty(new_location)
    fprintf('\n\n   please select a location to save the copy of the experiment info     \n\n')
    new_location = uigetdir(cExperiment.saveFolder); 
end

for diri=1:length(cExperiment.dirs)
    
    copyfile([cExperiment.saveFolder filesep cExperiment.dirs{diri} 'cTimelapse.mat'],...
        [new_location filesep cExperiment.dirs{diri} 'cTimelapse.mat']);
    
end

cExperiment.saveFolder = new_location;
cExperiment.saveExperiment;

end

