function saveExperiment(cExperiment)
% SAVEEXPERIMENT(cExperiment)
% Uploads changes to the experiment to the Omero database

%cExperiment file
%Before saving, replace OmeroDatabase object with the server name, make .cTimelapse empty and replace .omeroDs with its Id to avoid
%non-serializable errors.
cExperiment.cTimelapse=[];
omeroDatabase=cExperiment.OmeroDatabase;
cExperiment.OmeroDatabase=cExperiment.OmeroDatabase.Server;
omeroDs=cExperiment.omeroDs;
cExperiment.omeroDs=double(omeroDs.getId.getValue);
fileName=[cExperiment.saveFolder filesep 'cExperiment_' cExperiment.rootFolder '.mat'];
if iscell(fileName)
    fileName=fileName{:};
end


%Save cCellVision as a seperate variable
cCellVision=cExperiment.cCellVision;
cExperiment.cCellVision=[];

save(fileName,'cExperiment','cCellVision');
%Update or upload the file - first need to find the file annotation
%object

%Are there existing cExperiment and log files representing this cExperiment?
fileAnnotations=getDatasetFileAnnotations(omeroDatabase.Session,omeroDs);
%Create a cell array of file annotation names
faNames = {};
for n=1:length(fileAnnotations)
    faNames{n}=char(fileAnnotations(n).getFile.getName.getValue);
end

cEIndex=strcmp(['cExperiment_' cExperiment.rootFolder '.mat'],faNames);
logName=cExperiment.logger.file_name;
logIndex=strcmp(logName,faNames);
cEIndex=find(cEIndex);
logIndex=find(logIndex);
%Upload or update the cExperiment file
if ~isempty(cEIndex)
    cEIndex=cEIndex(1);
    disp(['Uploading file ' char(fileAnnotations(cEIndex).getFile.getName.getValue)]);
    fA = updateFileAnnotation(omeroDatabase.Session, fileAnnotations(cEIndex), fileName);
else%The file is not yet attached to the dataset
    omeroDatabase.uploadFile(fileName, omeroDs, 'cExperiment file uploaded by @experimentTracking.saveTimelapseExperiment');
end
%Restore the cExperiment object
cExperiment.omeroDs=omeroDs;
cExperiment.OmeroDatabase=omeroDatabase;
cExperiment.cCellVision=cCellVision;
%Upload or update the log file
if ~isempty(logIndex)
    logIndex=logIndex(1);
    disp(['Uploading file ' logName]);
    fA = updateFileAnnotation(omeroDatabase.Session, fileAnnotations(logIndex), logName);
else%The file is not yet attached to the dataset
    logFileName=[cExperiment.saveFolder filesep 'cExperiment_log_' cExperiment.rootFolder '.txt'];
    omeroDatabase.uploadFile(logFileName, omeroDs, 'cExperiment log file uploaded by @experimentTracking.saveTimelapseExperiment');
end
end
