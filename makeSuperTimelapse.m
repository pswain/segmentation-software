%% make sure timelapse

ExperimentLocations = {'~/Documents/microscope_files_swain_microscope/microscope characterisation/2014_06_25_bleed_through_trianing/analysis/cExperiment.mat' ...
                        '~/Documents/microscope_files_swain_microscope/microscope characterisation/2014_06_26_bleed_through_training_2/analysis_Gal_00/cExperiment.mat' };

PositionsToLoad = {[1 13 19 25 9] [12 13 17 18 22]};

for ei=1:length(ExperimentLocations)
    
    load(ExperimentLocations{ei});
    
    for pi = 1:length(PositionsToLoad{ei})
        load([fullfile(cExperiment.saveFolder, sprintf('pos%d',PositionsToLoad{ei}(pi))) 'cTimelapse']);
        if ei==1 && pi==1
            cTimelapseOut = fuseTimlapses({cTimelapse});
        else
            cTimelapseOut = fuseTimlapses({cTimelapseOut,cTimelapse});
        end
    end
    
end