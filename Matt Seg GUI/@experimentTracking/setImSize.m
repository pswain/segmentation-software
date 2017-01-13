function setImSize(cExperiment)
% setImSize(cExperiment)
% 
% uses the pixel_size of the cCellVision and that of the timelapseTraps objects
% to set the imSize property of each position (which is under all normal
% circumstances the same for all of them).
%
% See also TIMELAPSETRAPS.DETERMINEIMSIZE

poses = 1:numel(cExperiment.dirs);

for posi = poses
    pos = poses(posi);
    cExperiment.loadCurrentTimelapse(pos);
    cExperiment.cTimelapse.determineImSize(cExperiment.cCellVision.pixelSize);
    cExperiment.saveTimelapseExperiment;
end

end