function identifyTrapsTimelapses(cExperiment,cCellVision,positionsToIdentify)


if nargin<3
    positionsToIdentify=1:length(cExperiment.dirs);
end

Message=(['Each position of the experiment will be displayed one by one. The program will guess where the traps are present at first, but you will need to add (left-click) or remove' ...
    ' (right-click) traps to make sure that the trap selection is properly performed. It is generally advisable to look at the timelapse for a single position to make sure the stage ' ...
    'didnt drift too much during the experiment. If it did drift you want to make sure not to select traps that will go out of the field of view during the experiment.']);
h = helpdlg(Message);
    
%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    cTrapSelectDisplay(cTimelapse,cCellVision);
    
    uiwait();
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end
