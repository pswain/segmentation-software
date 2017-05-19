function saveTimelapseExperiment(cExperiment,currentPos, saveCE)
% saveTimelapseExperiment(cExperiment,currentPos, saveCE)
% 
% saves cExperiment.cTimelapse to:
%   [cExperiment.saveFolder filesep cExperiment.dirs{currentPos},'cTimelapse']
%
% also saves the cExperiment to:
%       [cExperiment.saveFolder filesep 'cExperiment.mat']
%
% removing cExperiment.cCellVision, saving it as a separate object, then
% putting it back. 
%
% If currentPos is not provided, cExperiment.currentPos (populated when
% EXPERIMENTTRACKING.LOADCURRENTTIMELAPSE is called) is used. It will be
% empty if experimentTracking.TimelapseTraps has been replaced by a
% non-identical object (see EXPERIMENTTRACKING.SET.CTIMELAPSE)
% 
% Third input is boolean - saveCE: logical - if true,
% save the cExperiment file as well as the timelapse. Defaults to false.
%
% See also, EXPERIMENTTRACKING.LOADCURRENTTIMELAPSE
if nargin<2 || isempty(currentPos)
    currentPos = cExperiment.currentPos;
end

if nargin<3
    saveCE=false;
end

cTimelapse = cExperiment.cTimelapse;
cTimelapseFilename=[cExperiment.saveFolder filesep cExperiment.dirs{currentPos},'cTimelapse'];
save(cTimelapseFilename,'cTimelapse');

if saveCE
    cExperiment.saveExperiment; 
end

end
