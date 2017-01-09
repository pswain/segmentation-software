function saveExperiment(cExperiment)
% SAVEEXPERIMENT(cExperiment)
% save the experiment in the saveFolder.

%cExperiment file
%Before saving, replace OmeroDatabase object with the server name, make .cTimelapse empty and replace .omeroDs with its Id to avoid
%non-serializable errors.
cExperiment.cTimelapse=[];
omeroDatabase=cExperiment.OmeroDatabase;
cExperiment.OmeroDatabase=cExperiment.OmeroDatabase.Server;
omeroDs=cExperiment.omeroDs;
cExperiment.omeroDs=[];
fileName=[cExperiment.saveFolder filesep 'cExperiment_' cExperiment.rootFolder '.mat'];
%Save cCellVision as a seperate variable
cCellVision=cExperiment.cCellVision;
cExperiment.cCellVision=[];

save(fileName,'cExperiment','cCellVision');
%Update or upload the file - first need to find the file annotation
%object
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
cExperiment.cCellVision=cCellVision;
end
