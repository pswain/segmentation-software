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
    if isa(cExperiment.OmeroDatabase,'OmeroDatabase')
        cExperiment.OmeroDatabase.login;
    else
        disp('Initialsing OmeroDatabase...');
        cExperiment.OmeroDatabase = OmeroDatabase('upload',cExperiment.OmeroDatabase);
    end
end

posName=cExperiment.dirs{timelapseNum};
fileName=[posName 'cTimelapse_' cExperiment.rootFolder '.mat'];

% Download/update the specified cTimelapse if necessary:
localFile = cExperiment.OmeroDatabase.downloadFile(cExperiment.omeroDs,fileName);

% Load the cTimelapse
load(localFile);

%Saved version will not have the correct OmeroDatabase and omeroImage
%objects - need to restore these:
cTimelapse.OmeroDatabase=cExperiment.OmeroDatabase;
if ~isempty(cTimelapse.omeroImage)
    cTimelapse.omeroImage=getImages(cTimelapse.OmeroDatabase.Session, cTimelapse.omeroImage);
end
%Ensure the timelapse has the channels list for the dataset
cTimelapse.channelNames=cExperiment.channelNames;
cTimelapse.metadata = cExperiment.metadata;
cTimelapse.metadata.posname = cExperiment.dirs{timelapseNum};

% In either case, once the timelapse is successfully loaded, trigger a
% PositionChanged event to notify experimentLogging
experimentLogging.changePos(cExperiment,timelapseNum,cTimelapse);

end