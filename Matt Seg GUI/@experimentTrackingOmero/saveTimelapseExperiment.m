function saveTimelapseExperiment(cExperimentOmero,currentPos, saveCE)
% saveTimelapseExperiment(cExperimentOmero,currentPos, saveCE)
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
    currentPos = cExperimentOmero.currentPos;
end

if nargin<3
    saveCE=false;
end

%Save code for Omero loaded cTimelapses - upload cExperiment file to
%Omero database. Use the alternative method saveExperiment if you want
%to save only the cExperiment file.

cTimelapse = cExperimentOmero.cTimelapse;

% posName should be equivalent to the position folder name
posName = char(cTimelapse.omeroImage.getName().getValue());
% Verify that the currentPos is correct
if ~strcmp(posName,cExperimentOmero.dirs(currentPos))
    error('"currentPos" does not match the current cTimelapse');
end

%cTimelapse file
%Before saving, replace image object with its Id and the OmeroDatabase object with the server name - avoids a non-serializable warning
oD = cTimelapse.OmeroDatabase;
omeroImage=cTimelapse.omeroImage;
cTimelapse.omeroImage=cTimelapse.omeroImage.getId.getValue;
cTimelapse.OmeroDatabase=cTimelapse.OmeroDatabase.Server;
fileName=[cExperimentOmero.saveFolder filesep posName 'cTimelapse_' cExperimentOmero.rootFolder '.mat'];

cT_description = 'cTimelapse file uploaded by @experimentTracking.saveTimelapseExperiment';

% If fileAnnotation IDs have not already been set for this cTimelapse,
% determine them before saving the object.
if isempty(cTimelapse.fileAnnotation_id)
    fileAnnotations = getDatasetFileAnnotations(oD.Session,cExperimentOmero.omeroDs);
    % Make a 'dummy' update call to ensure the files have an associated 
    % fileAnnotation:
    cT_fA = oD.updateFile(cExperimentOmero.omeroDs,fileName,'dummy',true,...
        'dsFiles',fileAnnotations,'description',cT_description);
    cTimelapse.fileAnnotation_id = cT_fA.getId().getValue();
else
    % The ID is already known, so retrieve fileAnnotations directly:
    cT_fA = getFileAnnotations(oD.Session,cTimelapse.fileAnnotation_id);
end

% Save cTimelapse object, then restore image and OmeroDatabase objects
save(fileName,'cTimelapse');
cTimelapse.omeroImage=omeroImage;
cTimelapse.OmeroDatabase=oD;

% Update the file on Omero:
oD.updateFile(cExperimentOmero.omeroDs,fileName,...
    'dsFiles',cT_fA,'description',cT_description);

if saveCE, cExperimentOmero.saveExperiment; end

end