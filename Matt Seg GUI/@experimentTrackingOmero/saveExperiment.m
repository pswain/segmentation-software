function saveExperiment(cExperiment)
% SAVEEXPERIMENT(cExperiment)
% Uploads changes to the experiment to the Omero database

%cExperiment file
%Before saving, replace OmeroDatabase object with the server name, make .cTimelapse empty and replace .omeroDs with its Id to avoid
%non-serializable errors.
cExperiment.cTimelapse=[];
omeroDatabase=cExperiment.OmeroDatabase;
cExperiment.OmeroDatabase=omeroDatabase.Server;
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

if ~isempty(cExperiment.fileAnnotation_id)
    %There is a recorded file annotation attached to the dataset representing
    %the cExperiment.
    %Download and replace it's associated file.
    fA=getFileAnnotations(omeroDatabase.Session, cExperiment.fileAnnotation_id);
    fA = updateFileAnnotation(omeroDatabase.Session, fA, fileName);
else
    %There is no file annotation recorded for this object - either this is the
    %first save of the object, or it was created with a previous version that
    %didn't record this info. For back-compatibility need to check if there is
    %an existing file annotation representing this cExperiment - can be done
    %by checking the file names of existing annotations.    
    
    %Are there existing cExperiment and log files representing this cExperiment?
    fileAnnotations=getDatasetFileAnnotations(omeroDatabase.Session,omeroDs);
    %Create a cell array of file annotation names
    faNames = {};
    for n=1:length(fileAnnotations)
        faNames{n}=char(fileAnnotations(n).getFile.getName.getValue);
    end
    
    cEIndex=strcmp(['cExperiment_' cExperiment.rootFolder '.mat'],faNames);
    cEIndex=find(cEIndex);
    %Upload or update the cExperiment file
    if ~isempty(cEIndex)
        cEIndex=cEIndex(1);
        disp(['Uploading file ' char(fileAnnotations(cEIndex).getFile.getName.getValue)]);
        fA = updateFileAnnotation(omeroDatabase.Session, fileAnnotations(cEIndex), fileName);
    else%The file is not yet attached to the dataset
        %omeroDatabase.uploadFile(fileName, omeroDs, 'cExperiment file uploaded by @experimentTracking.saveTimelapseExperiment');
        fA=omeroDatabase.uploadFile(fileName, omeroDs, 'cExperiment file uploaded by @experimentTracking.saveTimelapseExperiment');
        cExperiment.fileAnnotation_id=fA.getId.getValue;
    end
    %Restore the cExperiment object
    cExperiment.omeroDs=omeroDs;
    cExperiment.OmeroDatabase=omeroDatabase;
    cExperiment.cCellVision=cCellVision;
    %Upload or update the log file
       logFileName=fullfile (cExperiment.logger.file_dir, cExperiment.logger.file_name);
    if ~isempty(cExperiment.logger.fileAnnotation_id)
       fA=getFileAnnotations(omeroDatabase.Session, cExperiment.logger.fileAnnotation_id);
       fA = updateFileAnnotation(omeroDatabase.Session, getFileAnnotations(omeroDatabase.Session, cExperiment.logger.fileAnnotation_id), logFileName);
    else
        %fileAnnotation_id property will be empty when the logger object is
        %first created - make a new file annotation, upload the file and write
        %this property
        logFileName=fullfile (cExperiment.logger.file_dir, cExperiment.logger.file_name);
        fa=omeroDatabase.uploadFile(logFileName, omeroDs, 'cExperiment log file uploaded by @experimentTracking.saveExperiment');
        cExperiment.logger.fileAnnotation_id=fa.getId.getValue;
    end
    
    
end
