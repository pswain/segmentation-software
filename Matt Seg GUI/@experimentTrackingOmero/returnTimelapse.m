function cTimelapse=returnTimelapse(cExperiment,timelapseNum)
%cTimelapseOmero=returnTimelapse(cExperimentOmero,timelapseNum)
%
% loads a cTimelapse. timelapseNum should be a single number
% indicating which position to load. Note, timelapseNum indicates an index
% in cExperiment.dirs to load, so depending on the ordering of the
% directories in dirs cExperiment.loadCurrentTimelapse(2) will not
% necessarily load the cTimlapse related to directory pos2, and will in
% general load pos10 - this is due to alphabetic ordering.
%
% See also, EXPERIMENTTRACKING.LOADCURRENTTIMELAPSE


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
if exist([cExperiment.saveFolder fileName])==7
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


% In either case, once the timelapse is successfully loaded, trigger a
% PositionChanged event to notify experimentLogging
experimentLogging.changePos(cExperiment,timelapseNum,cTimelapse);

end