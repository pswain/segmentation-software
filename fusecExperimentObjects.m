function cExperimentFinal = fusecExperimentObjects(cExperimentCell,SaveFolder)
% cExperimentFinal = fusecExperimentObjects(cExperimentCell,saveFolder)
%fuses cExperiment objects (assumes they have the same number of positions
%and that those match up and just runs the fuse timelapse procedure on
%them.
%final cExperiment and cTimepoint files will be saved in SaveFolder.Can be
%the SaveFolder of one of the cExperiment files.


if nargin<2 || isempty(SaveFolder)
    
    fprintf('\n\n     please select a folder in which to save the final timelapse   \n\n')
    
    SaveFolder = uigetdir('~/Documents/microscope_files_swain_microscope_analysis/');
    
    
end


positions = 1:length(cExperimentCell{1}.dirs);
cexperiments = 1:length(cExperimentCell);

cExperiment = cExperimentCell{1};
load(fullfile(cExperiment.saveFolder, 'cExperiment.mat'),'cCellVision');
cExperiment.cCellVision = cCellVision;

NTP = 0;

for posi = positions
    
    TimelapseCell = cell(size(cExperimentCell));
    for cexpi = cexperiments
        TimelapseCell{cexpi} = cExperimentCell{cexpi}.returnTimelapse(posi);
        if posi==1
            %concatenate timepoint to process
            cExperiment.timepointsToProcess =cat(2,...
                cExperiment.timepointsToProcess,...
                cExperimentCell{cexpi}.timepointsToProcess + NTP);
            NTP = NTP + length(TimelapseCell{cexpi}.cTimepoint);
            
        end
    end
    cTimelapse = fuseTimlapses(TimelapseCell);
    save([SaveFolder filesep,cExperiment.dirs{posi},'cTimelapse'],'cTimelapse')
    cTimelapse = [];
    
end

cExperiment.saveFolder = SaveFolder;
cExperiment.cCellVision = cCellVision;
cExperiment.saveExperiment;

cExperimentFinal = cExperiment;
   

end