function loadCellVision(cExpGUI)

file_path = mfilename('fullpath');
filesep_loc = strfind(file_path,filesep);
cellVision_path = fullfile(file_path(1:(filesep_loc(end-1)-1)),  'cCellVisionFiles', 'cCellVision_Brightfield_2_slices_default.mat');

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of saved CellVision Model',cellVision_path) ;

load(fullfile(PathName,FileName),'cCellVision');

cExpGUI.cExperiment.cCellVision=cCellVision;

cExpGUI.cExperiment.setSegmentationChannels;


