function cTimelapse=loadCurrentTimelapse(cExperiment,positionsToLoad)

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
    load([cExperiment.saveFolder '/' cExperiment.dirs{positionsToLoad},'cTimelapse']);
end

cExperiment.cTimelapse=cTimelapse;
end    