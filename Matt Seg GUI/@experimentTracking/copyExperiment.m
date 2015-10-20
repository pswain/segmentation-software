function copyExperiment(cExperiment,new_location)
% copyExperiment(cExperiment,fileName)
%copies all the cTimelapse files to a new file, changing the saveFolder of
%cExperiment so that it won't overwrite the original.
    

if nargin<2 || isempty(new_location)
    fprintf('\n\n   please select a location to save the copy of the experiment info     \n\n')
    new_location = uigetdir(cExperiment.saveFolder); 
end

for diri=1:length(cExperiment.dirs)
    
    load([cExperiment.saveFolder filesep cExperiment.dirs{diri} 'cTimelapse.mat'],'cTimelapse');
    save([new_location filesep cExperiment.dirs{diri} 'cTimelapse.mat'],'cTimelapse');
    
end

cExperiment.saveFolder = new_location;
cExperiment.saveExperiment;

end

