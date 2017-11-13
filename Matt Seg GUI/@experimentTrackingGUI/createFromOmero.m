function createFromOmero(cExpGUI)
%Runs the Omero gui and if the user loads an experiment for segmentation,
%creates or downloads a cExperiment from the user-selected Omero dataset.
%Newly-created cExperiment and cTimelapse files are saved as file
%attachments to the database.

%Get a dataset selection from the user:
dsStruct = omeroGUI('download','sce-bio-c04287.bio.ed.ac.uk');
%There are options other than selecting a dataset for segmentation in that
%gui - so only create a dataset if the correct button has been pressed
if ~strcmp(dsStruct.action,'segment')
    return
end

%The OmeroDatabase now manages a folder for each dataset, so the DataPath
%folder is no longer required. The cExperiment.saveFolder must be set to
%the folder used by OmeroDatabase.

%First check if a cExperiment exists for this dataset:
[expNames,fileAnnotations] = dsStruct.OmeroDatabase.listcExperiments(dsStruct.dataset);

if isempty(expNames)
    % No cExperiment has been created for this dataset so create a new one:
    expName = omeroDB.getValidExpName(omeroDs,expNames); % get a valid name
    if ~expName, return; end % user cancelled
    cExpGUI.cExperiment = createNew(dsStruct.OmeroDatabase,...
        dsStruct.dataset,expName);
else
    %There is at least one existing cExperiment file
    response=questdlg('There is already at least one cExperiment file associated with this dataset. Do you want to load an existing one or create a new one? If you create a new one the existing one will be unaffected.','cExperiment file exists','Load existing','Create new','Load existing');
    switch response
        case 'Load existing'
            %Dialogue to choose one of the existing cExperiments
            [s,v] = listdlg('PromptString','Select the cExperiment you want to open','SelectionMode','single','ListString',expNames);
            if v~=1
                % User cancelled the load
                disp('No dataset selected. Aborting...');
                return
            end
            
            % Load the selected cExperiment
            cExpGUI.cExperiment = dsStruct.OmeroDatabase.loadcExperiment(...
                dsStruct.dataset,fileAnnotations(s));
            
            % NB: do not need to download cTimelapses; these will be
            % updated as required via 
            % experimentTrackingOmero.returnTimelapse method
            
        case 'Create new'
            %Need to create a new cExperiment with a name different from
            %any of the existing ones.
            expName = omeroDB.getValidExpName(omeroDs,expNames); % get a valid name
            if ~expName, return; end % user cancelled
            cExpGUI.cExperiment = createNew(dsStruct.OmeroDatabase,...
                dsStruct.dataset,expName);
        otherwise
            % User cancelled
            disp('Aborting...');
            return
    end
end

%Rename the figure - date and experiment folder name.
set(cExpGUI.figure,'Name',[char(cExpGUI.cExperiment.omeroDs.getName.getValue) '  ' cExpGUI.cExperiment.OmeroDatabase.getDate(cExpGUI.cExperiment.omeroDs)])
set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);
set(cExpGUI.posList,'Value',1);

if ~cExpGUI.cExperiment.trapsPresent
    set(cExpGUI.selectTrapsToProcessButton,'Enable','off');
else
    set(cExpGUI.selectTrapsToProcessButton,'Enable','on');
end

set(cExpGUI.selectChannelButton,'String',cExpGUI.cExperiment.channelNames,'Value',1);
cExpGUI.channel = 1;

end

%% Helper functions

function cExperiment = createNew(omeroDB,omeroDs,expName)
%createNew Helper function to create a new experimentTrackingOmero object

% Create a new cExperiment from the Omero dataset
cExperiment=experimentTrackingOmero(omeroDs,...
    [],omeroDB,expName);
cExperiment.segmentationSource='Omero';%Data will be retrieved from the Omero database for segmentation

% createTimelapsePositions given with explicit arguments so that all
% positions are loaded.
cExperiment.createTimelapsePositions([],'all');

% Upload the cExperiment file to the database
cExperiment.saveExperiment;
end