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
    fileName=fileName{:}; % equivalent to fileName{1};
end

cE_description = 'cExperiment file uploaded by @experimentTracking.saveTimelapseExperiment';
lF_description = 'cExperiment log file uploaded by @experimentTracking.saveExperiment';

% If fileAnnotation IDs have not already been set for this experiment,
% determine them before saving the object. Start by getting the
% fileAnnotations for this dataset:
if isempty(cExperiment.fileAnnotation_id) || isempty(cExperiment.logFileAnnotation_id)
    fileAnnotations = getDatasetFileAnnotations(omeroDatabase.Session,omeroDs);
else
    % Both IDs are already known, so retrieve fileAnnotations directly:
    fileAnnotations = getFileAnnotations(omeroDatabase.Session,...
        [cExperiment.fileAnnotation_id,cExperiment.logFileAnnotation_id]);
end
fA_Ids = arrayfun(@(x) x.getId().getValue(),fileAnnotations);

% Now check if IDs are specified, and if not, make a 'dummy' update call to
% ensure the files have an associated fileAnnotation:
if isempty(cExperiment.fileAnnotation_id)
    cE_fA = omeroDatabase.updateFile(omeroDs,fileName,'dummy',true,...
        'dsFiles',fileAnnotations,'description',cE_description);
    cExperiment.fileAnnotation_id = cE_fA.getId().getValue();
else
    cE_fA = fileAnnotations(fA_Ids==cExperiment.fileAnnotation_id);
end
logFileName = fullfile(cExperiment.logger.file_dir,cExperiment.logger.file_name);
if isempty(cExperiment.logFileAnnotation_id)
    lF_fA = omeroDatabase.updateFile(omeroDs,logFileName,'dummy',true,...
        'dsFiles',fileAnnotations,'description',lF_description);
    cExperiment.logFileAnnotation_id = lF_fA.getId().getValue();
else
    lF_fA = fileAnnotations(fA_Ids==cExperiment.logFileAnnotation_id);
end

%Save cCellVision as a seperate variable
cCellVision=cExperiment.cCellVision;
cExperiment.cCellVision=[];

save(fileName,'cExperiment','cCellVision');

%Restore the cExperiment object
cExperiment.omeroDs=omeroDs;
cExperiment.OmeroDatabase=omeroDatabase;
cExperiment.cCellVision=cCellVision;

% Update the files on Omero:
omeroDatabase.updateFile(omeroDs,fileName,'dsFiles',cE_fA,...
    'description',cE_description);
% Only update the log file if it exists (some people may have
% shouldLog=false):
if exist(logFileName,'file')==2
    omeroDatabase.updateFile(omeroDs,logFileName,'dsFiles',lF_fA,...
        'description',lF_description);
end

end