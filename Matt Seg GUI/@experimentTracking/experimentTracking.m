classdef experimentTracking<handle
    %class for organising and numerous timelapseTraps objects, one for each
    %position in the experiment. Mostly used to apply identical processing
    %steps to each position, organise loading and saving of them, and
    %compile the data from all the separate positions in one location.
    %Indiviual timelapseTraps objects are created either from local files
    %or from the omero database.
    
    properties
        rootFolder %folder where images are. When images are held in an Omero database this property is the suffix defining the filename: cExperiment_SUFFIX.mat
        omeroDs%Omero dataset object - alternative source to rootFolder
        OmeroDatabase%Omero database object
        creator%string, the user who created this object(obtained by getenv('USERNAME'))
        saveFolder %folder to save the timelapse objects
        dirs % cell array of directories in rootFolder. 
        posSegmented % logical array of position already segmented.
        posTracked %logical of positions tracked
        cellsToPlot % Doesn't actually seem to be used anywhere
        %currentDir 
        %the following all match their equivalents in timelapseTraps and
        %are popualted and used to populate the timelapseTrap fields when calling
        %loadTimelapse
        searchString; 
        pixelSize
        magnification
        trapsPresent;
        image_rotation;
        timepointsToLoad
        timepointsToProcess
        trackTrapsOverwrite
        imScale
        
        cTimelapse; %populated when loadCurrentTimelapse is used, and the cTimelapse saved when saveCurrentTimelapse is called.
        cellInf % cell data compuled from extractedData in each of the individual timelapseTrap objects
        experimentInformation %used by omero to store channel information; fields are .channels and .microscopeChannels
        cellVisionThresh % used to overwrite the twoStageThresh of cellVision in 
                         %      experimentTrackingGUI.identifyCells
                         %importantly, not used in the experimentTracking
                         %method:
                         %  segmentCellDisplay.
        
        lineageInfo %for all of the cell births and stuff that occure during the timelapse
        
        cCellVision; % cellvision model applied throughout the segmentation, 
                     % particularly in segmentCellDisplay and
                     % identifyTrapsTimelapses.
        ActiveContourParameters % parameters used in the ActiveContour 
                                % methods, copied to each timelapseTraps
                                % object when this is run (if parameters
                                % selected appropriately)
    end
    
    properties (Transient)
        % Transient properties won't be saved
        logger; % handle to an experimentLogging object to keep a log
    end
    
    events
        PositionChanged
        LogMsg
    end
    
    methods
        
        function cExperiment=experimentTracking(folder,saveFolder, OmeroDatabase,  expName)
            %% Folder input is a string with the full path to the root folder or an Omero dataset object (in that case the OmeroDatabase object must also be input)
            %Optional inputs 2-4 only used when creating objects using the
            %Omero database: OmeroDatabase - object of class OmeroDatabase
            %expName, a unique name for this cExperiment
                                               
            % Create a new logger to log changes for this cExperiment:
            cExperiment.logger = experimentLogging(cExperiment);
            
            % Read filenames from folder
            if nargin<1
                fprintf('\n   Select the Root of a single experimental set containing folders of multiple positions \n');
                folder=uigetdir(pwd,'Select the Root of a single experimental set containing folders of multiple positions');
            end
            if nargin<2
                fprintf('\n   Select the folder where data should be saved \n');
                saveFolder=uigetdir(folder,'Select the folder where data should be saved');
            end
            
            if ischar(folder)
                cExperiment.rootFolder=folder;
                cExperiment.saveFolder=saveFolder;
            else%Experiment is being initialized from an Omero dataset - folder is an omero.model.DatasetI object
                if nargin>3
                    if iscell(expName)
                        expName=expName{:};
                    end
                    cExperiment.rootFolder=expName;
                else
                    cExperiment.rootFolder='001';%default experiment name
                end
                if ismac
                    cExperiment.saveFolder=['/Users/' char(java.lang.System.getProperty('user.name')) '/Documents/OmeroTemp'];
                    
                else
                    cExperiment.saveFolder=['C:\Users\' getenv('USERNAME') '\OmeroTemp'];
                end
                if ~exist(cExperiment.saveFolder,'dir')
                    
                    
                    
                    
                    mkdir(cExperiment.saveFolder);
                end
                delete([cExperiment.saveFolder '/*']);
                cExperiment.omeroDs=folder;
                cExperiment.OmeroDatabase=OmeroDatabase;
            end
            if ispc
                cExperiment.creator=getenv('USERNAME');
            else
                [~, cExperiment.creator] = system('whoami');
            end
            cExperiment.posSegmented=0;
            cExperiment.posTracked=0;
            if isempty(cExperiment.OmeroDatabase)
                tempdir=dir(cExperiment.rootFolder);
            else
                tempdir=[];
            end
            cExperiment.dirs=cell(1);
            if isempty(cExperiment.OmeroDatabase)
                index=1;
                for i=1:length(tempdir)
                    if tempdir(i).isdir
                        if ~strcmp(tempdir(i).name(1),'.')
                            cExperiment.dirs{index}=tempdir(i).name;
                            index=index+1;
                        end

                    end
                end
            else
                %Position list consists of the Omero image names
                oImages=cExperiment.omeroDs.linkedImageList;
                for i=1:oImages.size
                    cExperiment.dirs{i}=char(oImages.get(i-1).getName.getValue);
                end
                cExperiment.dirs=sort(cExperiment.dirs);
            end
            cExperiment.cellsToPlot=cell(1);
            cExperiment.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
            
            %Set the channels
            if ~isempty(cExperiment.OmeroDatabase)                
                %Set the channels field - add a separate channel for each section in case
                %they are required for data extraction or segmentation:
                %Get the number of Z sections
                sizeZ=OmeroDatabase.MetaData.z.numSections;
                %Get the list of channels from the microscope log
                origChannels=cExperiment.OmeroDatabase.getChannelNames(cExperiment.omeroDs,cExperiment.OmeroDatabase.MetaData);
                cExperiment.OmeroDatabase.MicroscopeChannels = origChannels;
                cExperiment.experimentInformation.MicroscopeChannels=origChannels;
                %The first entries in
                %cExperiment.experimentInformation.channels are the
                %original channels - then followed by a channel for each
                %section.
                cExperiment.experimentInformation.Channels=origChannels;
                if sizeZ>1
                    for ch=1:length(origChannels)
                        if cExperiment.OmeroDatabase.MetaData.channels(ch).zSectioning
                            for z=1:sizeZ
                                cExperiment.OmeroDatabase.Channels{length(cExperiment.OmeroDatabase.Channels)+1}=[origChannels{ch} '_' num2str(z)];
                            end
                        end
                    end
                end
                cExperiment.experimentInformation.channels=cExperiment.OmeroDatabase.Channels;

            end
            
        end
        
    end
    
    methods(Static)

        function cExperiment = loadobj(obj)
            cExperiment = obj;
            % Create a new experimentLogging object when loading:
            cExperiment.logger = experimentLogging(cExperiment);
        end
                
        function cCellVision = loadDefaultCellVision
            file_path = mfilename('fullpath');
            filesep_loc = strfind(file_path,filesep);
            cellVision_path = fullfile(file_path(1:(filesep_loc(end-1)-1)),  'cCellVisionFiles', 'cCellVision_Brightfield_2_slices_default.mat');
            load(cellVision_path,'cCellVision');
        end
        
    end
end

