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

%TODO work out why currentPose isn't used.
if nargin<2 || isempty(currentPos)
    currentPos = cExperimentOmero.currentPos;
end

if nargin<3
    saveCE=false;
end


%Save code for Omero loaded cExperiments - upload cExperiment file to
%Omero database. Use the alternative method saveExperiment if you want
%to save only the cExperiment file.

cTimelapse = cExperimentOmero.cTimelapse;

%Replace any existing cExperiment and cTimelapse files for the same
%dataset.
fileAnnotations=getDatasetFileAnnotations(cExperimentOmero.OmeroDatabase.Session,cExperimentOmero.omeroDs);
dsName=char(cExperimentOmero.cTimelapse.omeroImage.getName.getValue);%Name is equivalent to the position folder name

%Create a cell array of file annotation names
for n=1:length(fileAnnotations)
    faNames{n}=char(fileAnnotations(n).getFile.getName.getValue);
end



%Need to save to temp file before updating the file in the database.

%cTimelapse file
%Before saving, replace image object with its Id and the OmeroDatabase object with the server name - avoids a non-serializable warning
oD=cTimelapse.OmeroDatabase;
omeroImage=cTimelapse.omeroImage;
cTimelapse.omeroImage=cTimelapse.omeroImage.getId.getValue;
cTimelapse.OmeroDatabase=cTimelapse.OmeroDatabase.Server;
fileName=[cExperimentOmero.saveFolder filesep dsName 'cTimelapse_' cExperimentOmero.rootFolder '.mat'];
save(fileName,'cTimelapse');
%Restore image and OmeroDatabase objects
cTimelapse.omeroImage=omeroImage;
cTimelapse.OmeroDatabase=oD;
faIndex=strcmp([dsName 'cTimelapse_' cExperimentOmero.rootFolder '.mat'],faNames);
faIndex=find(faIndex);

if ~isempty(faIndex)
    faIndex=faIndex(1);
    disp(['Uploading file ' char(fileAnnotations(faIndex).getFile.getName.getValue)]);
    fA = updateFileAnnotation(cExperimentOmero.OmeroDatabase.Session, fileAnnotations(faIndex), fileName);
else%The file is not yet attached to the dataset
    cExperimentOmero.OmeroDatabase.uploadFile(fileName, cExperimentOmero.omeroDs, 'cTimelapse file uploaded by @experimentTracking.saveTimelapseExperiment');
end


if saveCE
    cExperimentOmero.saveExperiment;
end
end
