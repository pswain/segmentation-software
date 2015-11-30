function cTimelapse=loadCurrentTimelapse(cExperiment,positionsToLoad)
%cTimelapse=loadCurrentTimelapse(cExperiment,positionsToLoad)
%
% loads a cTimelapse. Positions to load should be a single number
% indicating which position to load. Note, positionsToLoad indicated index
% in cExperiment.dirs to load, so depending on the ordering of the
% directories in dirs cExperiment.loadCurrentTimelapse(2) will not
% necessarily load the cTimlapse related to directory pos2, and will in
% general load pos10 - his is due to alphabetic ordering.
%
if ~isempty(cExperiment.OmeroDatabase)%Experiment created from an Omero dataset - has a suffix to distinguish different cExperiment/timelapse files
    %Has this file already been downloaded?
    if strcmp(cExperiment.saveFolder(end),'/') || strcmp(cExperiment.saveFolder(end),'\')
        cExperiment.saveFolder(end)=[];
    end
    if exist([cExperiment.saveFolder '/' cExperiment.dirs{positionsToLoad},'cTimelapse_' cExperiment.rootFolder '.mat'],'file')==2
        load([cExperiment.saveFolder '/' cExperiment.dirs{positionsToLoad},'cTimelapse_' cExperiment.rootFolder '.mat']);
    else
        cTimelapse=cExperiment.returnTimelapse(positionsToLoad);
    end
    %Saved version has only the server name in .OmeroDatabase and the
    %image Id number in omeroImage
    cTimelapse.OmeroDatabase=cExperiment.OmeroDatabase;
    if isnumeric (cTimelapse.omeroImage)
        cTimelapse.omeroImage=getImages(cExperiment.OmeroDatabase.Session, cTimelapse.omeroImage);
    end
        
else%Experiment created from a folder - name is just 'cTimelapse'
    load([cExperiment.saveFolder filesep cExperiment.dirs{positionsToLoad},'cTimelapse']);
end

cExperiment.cTimelapse=cTimelapse;
end    