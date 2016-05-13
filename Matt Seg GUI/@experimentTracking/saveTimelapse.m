function saveTimelapse(cExperiment,currentPos)
% saveTimelapse(cExperiment,currentPos, saveCE)
%
% saves cExperiment.cTimelapse to:
%   [cExperiment.saveFolder filesep cExperiment.dirs{currentPos},'cTimelapse']
%
% cExperiment variable is not saved by this function.
cTimelapse=cExperiment.cTimelapse;
cTimelapse.temporaryImageStorage=[];

if isempty(cExperiment.OmeroDatabase)
    if nargin>1
        cTimelapseFilename=[cExperiment.saveFolder filesep cExperiment.dirs{currentPos},'cTimelapse'];
    else
        cTimelapseFilename=cExperiment.currentTimelapseFilename;
    end
    save(cTimelapseFilename,'cTimelapse');
else
    %Save code for Omero loaded cExperiments - upload cExperiment file to
    %Omero database. Use the alternative method saveExperiment if you want
    %to save only the cExperiment file.
    
    %Replace any existing cExperiment and cTimelapse files for the same
    %dataset.
    fileAnnotations=getDatasetFileAnnotations(cExperiment.OmeroDatabase.Session,cExperiment.omeroDs);
    dsName=char(cExperiment.cTimelapse.omeroImage.getName.getValue);%Name is equivalent to the position folder name
    
    %Create a cell array of file annotation names
    for n=1:length(fileAnnotations)
        faNames{n}=char(fileAnnotations(n).getFile.getName.getValue);
    end

    
    
    %Need to save to temp file before updating the file in the database.
    
    %cTimelapse file
    %Before saving, replace image object with its Id and the OmeroDatabase object with the server name - avoids a non-serializable warning
    cTimelapse.omeroImage=cTimelapse.omeroImage.getId.getValue;
    cTimelapse.OmeroDatabase=cTimelapse.OmeroDatabase.Server;
    fileName=[cExperiment.saveFolder filesep dsName 'cTimelapse_' cExperiment.rootFolder '.mat'];
    save(fileName,'cTimelapse');
    faIndex=strcmp([dsName 'cTimelapse_' cExperiment.rootFolder '.mat'],faNames);
    faIndex=find(faIndex);
 
    if ~isempty(faIndex)
        faIndex=faIndex(1);
        disp(['Uploading file ' char(fileAnnotations(faIndex).getFile.getName.getValue)]);
        fA = updateFileAnnotation(cExperiment.OmeroDatabase.Session, fileAnnotations(faIndex), fileName);
    else%The file is not yet attached to the dataset
        cExperiment.OmeroDatabase.uploadFile(fileName, cExperiment.omeroDs, 'cTimelapse file uploaded by @experimentTracking.saveTimelapseExperiment');
    end
            
    %cCellVision file
    fileName=[cExperiment.saveFolder filesep dsName 'cCellVision_' cExperiment.rootFolder '.mat'];
    cCellVision=cExperiment.cCellVision;
    save(fileName,'cCellVision');
    faIndex=strcmp([dsName 'cCellVision_' cExperiment.rootFolder '.mat'],faNames);
    faIndex=find(faIndex);
   
    if ~isempty(faIndex)
         faIndex=faIndex(1);
         disp(['Uploading file ' char(fileAnnotations(faIndex).getFile.getName.getValue)]);
         fA = updateFileAnnotation(cExperiment.OmeroDatabase.Session, fileAnnotations(faIndex), fileName);
    else%The file is not yet attached to the dataset
        cExperiment.OmeroDatabase.uploadFile(fileName, cExperiment.omeroDs, 'cCellVision file uploaded by @experimentTracking.saveTimelapseExperiment');
    end
    
end
