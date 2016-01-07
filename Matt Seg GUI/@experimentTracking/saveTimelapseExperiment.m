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
% Third input is only used by Omero code.It is saveCE: logical - if true,
% save the cExperiment file as well as the timelapse,
    cTimelapse=cExperiment.cTimelapse;
if isempty(cExperiment.OmeroDatabase)
    save([cExperiment.saveFolder filesep cExperiment.dirs{currentPos},'cTimelapse'],'cTimelapse');
    cTimelapse.ActiveContourObject.TimelapseTraps = cTimelapse;
    
    cExperiment.cTimelapse=[];
    cCellVision=cExperiment.cCellVision;
    cExperiment.cCellVision=[];
    save([cExperiment.saveFolder filesep 'cExperiment.mat'],'cExperiment','cCellVision');
    cExperiment.cCellVision=cCellVision;
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
    
    if nargin<3
        saveCE=true;
    end
    if saveCE
        %cExperiment file
        %Before saving, replace OmeroDatabase object with the server name, make .cTimelapse empty and replace .omeroDs with its Id to avoid
        %non-serializable errors.   
        cExperiment.cTimelapse=[];
        omeroDatabase=cExperiment.OmeroDatabase;
        cExperiment.OmeroDatabase=cExperiment.OmeroDatabase.Server;
        omeroDs=cExperiment.omeroDs;
        cExperiment.omeroDs=[];
        fileName=[cExperiment.saveFolder filesep 'cExperiment_' cExperiment.rootFolder '.mat'];
        save(fileName,'cExperiment');
        faIndex=strcmp(['cExperiment_' cExperiment.rootFolder '.mat'],faNames);
        faIndex=find(faIndex);
        if ~isempty(faIndex)
             faIndex=faIndex(1);
             disp(['Uploading file ' char(fileAnnotations(faIndex).getFile.getName.getValue)]);
             fA = updateFileAnnotation(omeroDatabase.Session, fileAnnotations(faIndex), fileName);
        else%The file is not yet attached to the dataset
            omeroDatabase.uploadFile(fileName, omeroDs, 'cExperiment file uploaded by @experimentTracking.saveTimelapseExperiment');
        end
        %Restore the cExperiment object
        cExperiment.omeroDs=omeroDs;
        cExperiment.OmeroDatabase=omeroDatabase;
    end
end
