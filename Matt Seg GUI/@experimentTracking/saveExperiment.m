function saveExperiment(cExperiment,fileName)
%     save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
if isempty(cExperiment.OmeroDatabase)
    %Original save code for experiments created from a folder full of image
    %files
    if nargin<2
        cCellVision=cExperiment.cCellVision;
        cExperiment.cCellVision=[];
        save([cExperiment.saveFolder '/cExperiment'],'cExperiment','cCellVision');
        cExperiment.cCellVision=cCellVision;

    else
            cCellVision=cExperiment.cCellVision;
        cExperiment.cCellVision=[];
        save([cExperiment.saveFolder '/' fileName],'cExperiment','cCellVision');
        cExperiment.cCellVision=cCellVision;
    end
else
    %Save code for cExperiments created from an Omero dataset - only call
    %with one input
    expFileName=['cExperiment_' cExperiment.rootFolder '.mat'];
    %Prepare for local save - need to remove Omero database objects to
    %avoid a non-serializable warning on saving
    cExperiment.cTimelapse=[];
    omeroDatabase=cExperiment.OmeroDatabase;
    cExperiment.OmeroDatabase=cExperiment.OmeroDatabase.Server;
    omeroDs=cExperiment.omeroDs;
    cExperiment.omeroDs=[];
    if iscell(expFileName)
        expFileName=expFileName{:};
    end
    save([cExperiment.saveFolder filesep expFileName],'cExperiment');
    %Is there an existing file representing this cExperiment?
    fileAnnotations=getDatasetFileAnnotations(omeroDatabase.Session,omeroDs);
    %Create a cell array of file annotation names
    for n=1:length(fileAnnotations)
        faNames{n}=char(fileAnnotations(n).getFile.getName.getValue);
    end
    faIndex=strcmp(expFileName,faNames);
    if any(faIndex)
        %Update existing file
        faIndex=find(faIndex);
        faIndex=faIndex(1);
        disp(['Uploading modified file ' expFileName]);
        fA = updateFileAnnotation(omeroDatabase.Session, fileAnnotations(faIndex), [cExperiment.saveFolder filesep expFileName]);
    else
        %Save a new cExperiment file
        disp(['Uploading file ' expFileName]);

        if ismac
            if ~strcmp(cExperiment.saveFolder,'/')
                if ~strcmp(cExperiment.saveFolder,'\')
                    cExperiment.saveFolder(end+1)='/';
                end
            end
            omeroDatabase.uploadFile([cExperiment.saveFolder expFileName], omeroDs, 'cExperiment file uploaded by @experimentTracking.saveExperiment');
        else
            omeroDatabase.uploadFile([cExperiment.saveFolder filesep expFileName], omeroDs, 'cExperiment file uploaded by @experimentTracking.saveExperiment');
        end
    end
    %Restore the cExperiment object
    cExperiment.omeroDs=omeroDs;
    cExperiment.OmeroDatabase=omeroDatabase;
    
    %Also save the cCellVision file if present
    visFileName=['cCellVision_' cExperiment.rootFolder '.mat'];
    visFilePath=[cExperiment.saveFolder filesep 'cCellVision_' cExperiment.rootFolder '.mat'];
    cCellVision=cExperiment.cCellVision;
    if ~isempty(cCellVision)
        save(visFilePath,'cCellVision');
        faIndex=strcmp(visFileName,faNames);
        faIndex=find(faIndex);
        if ~isempty(faIndex)
            faIndex=faIndex(1);
            disp(['Uploading file cCellVision_' cExperiment.rootFolder '.mat']);
            fA = updateFileAnnotation(cExperiment.OmeroDatabase.Session, fileAnnotations(faIndex), visFilePath);
        else%The file is not yet attached to the dataset
            disp(['Uploading file cCellVision_' cExperiment.rootFolder '.mat']);
            cExperiment.OmeroDatabase.uploadFile(visFilePath, cExperiment.omeroDs, 'cCellVision file uploaded by @experimentTracking.saveTimelapseExperiment');
        end
    end
end

