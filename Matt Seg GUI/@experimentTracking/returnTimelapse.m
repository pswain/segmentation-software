function cTimelapse=returnTimelapse(cExperiment,timelapseNum)
%cTimelapse=returnTimelapse(cExperiment,timelapseNum)
%
% loads a cTimelapse. timelapseNum should be a single number
% indicating which position to load. Note, timelapseNum indicates an index
% in cExperiment.dirs to load, so depending on the ordering of the
% directories in dirs cExperiment.loadCurrentTimelapse(2) will not
% necessarily load the cTimlapse related to directory pos2, and will in
% general load pos10 - his is due to alphabetic ordering.
%
if isempty(cExperiment.OmeroDatabase)
    %Loading a timelapse from a file folder
    if isempty(cExperiment.saveFolder)
        cExperiment.saveFolder=cExperiment.rootFolder;
    end
    load([cExperiment.saveFolder filesep cExperiment.dirs{timelapseNum},'cTimelapse']);
    cTimelapse.OmeroDatabase=cExperiment.OmeroDatabase;%This should be already logged in (empty if experiment loaded from a folder
else
    %Loading a cTimelapse from an Omero database
    %First check we are logged in
    try
        cExperiment.OmeroDatabase.Client.ice_getConnection;
    catch
        if ischar (cExperiment.OmeroDatabase)
            cExperiment.OmeroDatabase=OmeroDatabase('upload',cExperiment.OmeroDatabase);
        else
        cExperiment.OmeroDatabase=cExperiment.OmeroDatabase.login;
        end
    end
    posName=cExperiment.dirs{timelapseNum};
    fileName=[posName 'cTimelapse_' cExperiment.rootFolder '.mat'];
    if exist([cExperiment.saveFolder filesep fileName])==7
        %This cTimelapse has already been downloaded to the temporary local
        %folder
        load ([cExperiment.saveFolder filesep fileName]);
    else
        %Get file from the database
        fileAnnotations=getDatasetFileAnnotations(cExperiment.OmeroDatabase.Session,cExperiment.omeroDs);
        for n=1:length(fileAnnotations)
            faNames{n}=char(fileAnnotations(n).getFile.getName.getValue);
        end
        matched=strmatch(fileName,faNames);
        disp(['Downloading ' posName 'cTimelapse_' cExperiment.rootFolder '.mat'])
        getFileAnnotationContent(cExperiment.OmeroDatabase.Session, fileAnnotations(matched(1)), [cExperiment.saveFolder filesep fileName]);
        load ([cExperiment.saveFolder filesep fileName]);
    end
    %Saved version will not have the correct OmeroDatabase and omeroImage
    %objects - need to restore these:
    cTimelapse.OmeroDatabase=cExperiment.OmeroDatabase;
    if ~isempty(cTimelapse.omeroImage)
        cTimelapse.omeroImage=getImages(cTimelapse.OmeroDatabase.Session, cTimelapse.omeroImage);
    end
    %Ensure the timelapse has the channels list for the dataset
    cTimelapse.channelNames=cExperiment.experimentInformation.channels;
end