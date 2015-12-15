function createGroundTruth(cCellVisionGUI)

answer=inputdlg('would you like to retrack the traps?This will remove any preexisting trap information','trap tracking',1,{'No'});
TrapTrackingRequired = ~strcmp(answer{1},'No');

cTrapDisplay(cCellVisionGUI.cTimelapse,cCellVisionGUI.cCellVision,[],[],[],TrapTrackingRequired);
