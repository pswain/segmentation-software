function compileCellInformation(cExperiment,positionsToExtract,force)
% compileCellInformation(cExperiment,positionsToExtract,force)
%
% compiles all the data extracted in each of the positions into cellInf
% fiels of cExperiment.
%
% positionsToExtract    :   indexes of positions to extract. defaults to
%                           all positions.
% force                 :   boolean, defaults to false. If true, data is
%                           compiled even if the extraction parameters for
%                           each of the individual timelapses done match.
%                           Otherwise it will skip positions who's
%                           extractedData.extractionParameters field do not
%                           match those of the first timelapse.

if nargin<2 || isempty(positionsToExtract)
    positionsToExtract=find(cExperiment.posTracked);
end

if nargin<3 || isempty(force)
    
    force = false;
    
end

% Start logging protocol
try

cTimelapse=cExperiment.returnTimelapse(positionsToExtract(1));

cExperiment.cellInf=cTimelapse.extractedData;

[cExperiment.cellInf(:).posNum]=deal(positionsToExtract(1)*ones(size(cExperiment.cellInf(1).trapNum)));

% Track extracted timepoints for compilation of times from meta data:
extractedTimepoints = false(length(cExperiment.dirs),...
    length(cTimelapse.timepointsProcessed));
extractedTimepoints(positionsToExtract(1),:) = cTimelapse.timepointsProcessed;

% list of fields that are not identically sized arrays
fields_treated_special = {'posNum','trapNum','cellNum','extractionParameters'};

% size of chunks to preallocate.
tempLen=50e3;
field_names = fieldnames(cExperiment.cellInf);
fields_to_treat = field_names(~ismember(field_names,fields_treated_special));

index = length(cExperiment.cellInf(1).posNum);
for posi=2:length(positionsToExtract)

    if index>= length(cExperiment.cellInf(1).posNum) || posi==2
        %preallocate more space
        for chi = 1:length(cExperiment.cellInf)
            for fi = 1:length(fields_to_treat)
                fn = fields_to_treat{fi};
                if fi==1 && chi==1 && posi==2
                    %timepoints in the data
                    tps = size(cExperiment.cellInf(chi).(fn),2);
                    data_template = spalloc(tempLen,tps,0.5*tempLen*tps);
                    %assumes only 50 percent of timepoints will be present on
                    %average.
                end
                
                cExperiment.cellInf(chi).(fn)((index+1):(index+tempLen),:)=data_template;
            end
            cExperiment.cellInf(chi).trapNum((index+1):(index+tempLen)) = zeros(1,tempLen);
            cExperiment.cellInf(chi).cellNum((index+1):(index+tempLen)) = zeros(1,tempLen);
            cExperiment.cellInf(chi).posNum((index+1):(index+tempLen)) = zeros(1,tempLen);

        end

    end

    pos = positionsToExtract(posi);
    cTimelapse=cExperiment.returnTimelapse(pos);

    if ~isequaln(cTimelapse.extractedData.extractionParameters,cExperiment.cellInf(1).extractionParameters) && ~force
        logmsg(cExperiment,'Not compiling data %d, extraction parameters do not match.',pos);
        continue
    end

    num_cells = length(cTimelapse.extractedData(1).cellNum);
    for chi = 1:length(cExperiment.cellInf)
        for fi = 1:length(fields_to_treat)
            fn = fields_to_treat{fi};
           cExperiment.cellInf(chi).(fn)((index+1):(index+num_cells),:)=cTimelapse.extractedData(chi).(fn);
        end
        cExperiment.cellInf(chi).trapNum((index+1):(index+num_cells)) = cTimelapse.extractedData(chi).trapNum;
        cExperiment.cellInf(chi).cellNum((index+1):(index+num_cells)) = cTimelapse.extractedData(chi).cellNum;
        cExperiment.cellInf(chi).posNum((index+1):(index+num_cells)) = pos*ones(1,num_cells);

    end
    extractedTimepoints(pos,:) = cTimelapse.timepointsProcessed;
    index = index + num_cells;

    cExperiment.cTimelapse = [];

end

%remove left over zeros from preallocation.
for chi=1:length(cExperiment.cellInf)
    for fi = 1:length(fields_to_treat)
        fn = fields_to_treat{fi};
        cExperiment.cellInf(chi).(fn)((index+1):end,:)=[];
    end
    cExperiment.cellInf(chi).trapNum((index+1):end) =[];
    cExperiment.cellInf(chi).cellNum((index+1):end) = [];
    cExperiment.cellInf(chi).posNum((index+1):end) = [];

end

if force
    [cExperiment.cellInf(:).extractionParameters] = deal([]);
end

% Compile meta data into the cellInf:

cExperiment.compileMetaData(extractedTimepoints,cExperiment.logger.progress_bar);

cExperiment.saveExperiment();
%Tag dataset in Omero for archiving - we assume that if the data are worth
%compiling then the experiment should be archived.
if exist('OmeroDatabase','class')==8%Only run this if the Omero code is available
    %If is an experimentTrackingOmero object - tag for archiving - if not,
    %run convertSegmented to upload
    if isa (cExperiment,'experimentTrackingOmero')
        addArchiveTag(cExperiment.id);
        writeOmeroLog('Added archive tag',['Experiment ' cExperiment.metadata.experiment ' tagged for automated archiving: experimentTracking.compileCellInformation']);
    else
        %Run convertSegemented - will upload the cExperiment as a cExperimentOmero object
        oDb=OmeroDatabase('upload','sce-bio-c04287.bio.ed.ac.uk',true);
        cExperimentOm=oDb.convertSegmented(cExperiment);       
    end
    
    try
        
        catch err
        warning ('Error adding archive tag');
        writeOmeroLog('Error adding archive tag',['Archive tagging failed for experiment ' cExperiment.metadata.experiment ': ' err.message]);
    end
    else
    warning('Experiment can''t be archived - Add Omero code to your Matlab path to enable this feature. Code available GIT@skye.bio.ed.ac.uk:~/GITrepositories/OmeroCode.git');
end

% Finish logging protocol
cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end

end