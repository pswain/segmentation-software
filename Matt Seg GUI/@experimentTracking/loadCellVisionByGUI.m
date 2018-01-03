function loadCellVisionByGUI( cExperiment)
%LOADCELLVISIONBYGUI select a cellVision to load and append to the
%cExperiment by interactive GUI.
% loadCellVisionByGUI( cExperiment)

file_path = mfilename('fullpath');
filesep_loc = strfind(file_path,filesep);
cellVision_path = fullfile(file_path(1:(filesep_loc(end-1)-1)),  'cCellVisionFiles', 'cCellVision_Brightfield_2_slices_default.mat');

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of saved CellVision Model',cellVision_path) ;

load(fullfile(PathName,FileName),'cCellVision');

cExperiment.cCellVision=cCellVision;

cExperiment.setSegmentationChannels;

end

