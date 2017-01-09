classdef experimentTracking<handle
    % class for organising and numerous timelapseTraps objects, one for each
    % position in the experiment. Mostly used to apply identical processing
    % steps to each position, organise loading and saving of them, and
    % compile the data from all the separate positions in one location.
    % Indiviual timelapseTraps objects are created from the folders in the
    % rootFolder and saved, with the experimentTracking object, in the
    % saveFolder. 
    % A subclass (experimentTrackingOmero) is available to load/save/access images 
    % from the swainlab omeroDataBase.
    %
    % See also EXPERIMENTTRACKINGGUI,TIMELAPSETRAPS,EXPERIMENTTRACKINGOMERO
    
    properties
        rootFolder %folder where images are. When images are held in an Omero database this property is the suffix defining the filename: cExperiment_SUFFIX.mat
        creator%string, the user who created this object(obtained by getenv('USERNAME'))
        saveFolder %folder to save the timelapse objects
        dirs % cell array of directories in rootFolder. 
        posSegmented % logical array of position already segmented.
        posTracked %logical of positions tracked
        cellsToPlot % Doesn't actually seem to be used anywhere
        metadata % structure of meta data filled by experimentTracking.parseLogFile
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
        
        shouldLog %a parameter that tells the logger whether it should do things 
        
        channelNames %this has the list of the channel names  
        currentTimelapseFilename; %name of where the current timelapse was loaded from
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
                                
        OmeroDatabase %TODO delete this at end
        omeroDs %TODO delete this at end
                                
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
        
        function cExperiment=experimentTracking(rootFolder,saveFolder)
            %cExperiment=experimentTracking(rootFolder,saveFolder)
            % 
            % INPUTS 
            % rootFolder   -  EITHER :
            %                   - a boolean (true) indicating that a bare
            %                     experimentTracking object should be
            %                     created (used in loading and subclasses)
            %                 OR:
            %                   - a string with the full path to the root
            %                     folder (i.e. folder where all the
            %                     postition folders are). 
            %                 If empty, rootFolder is selected by user
            %                 input.
            % saveFolder   -  string. Full path to the folder where the
            %                 experimentTracking object and created
            %                 timelapseTraps objects should be saved.
            
            % Create a new logger to log changes for this cExperiment:
            %disp('Not generating log files now - to change open experimentTracking.m')
            cExperiment.shouldLog=true;
            cExperiment.logger = experimentLogging(cExperiment,cExperiment.shouldLog);
            
            % Initialise source (root folder) and save paths
            if nargin<1
                fprintf('\n   Select the Root of a single experimental set containing folders of multiple positions \n');
                rootFolder=uigetdir(pwd,'Select the Root of a single experimental set containing folders of multiple positions');
            elseif islogical(rootFolder) && rootFolder
                % if folder is true, cExperiment returned bare for load
                % function.
                return
            end
            
            if nargin<2
                fprintf('\n   Select the folder where data should be saved \n');
                saveFolder=uigetdir(rootFolder,'Select the folder where data should be saved');
            end            

            cExperiment.rootFolder=rootFolder;
            cExperiment.saveFolder=saveFolder;
            
            %Record the user who is creating the cExperiment
            if ispc
                cExperiment.creator=getenv('USERNAME');
            else
                [~, cExperiment.creator] = system('whoami');
            end
            %Initialize records of positions segmented and tracked
            cExperiment.posSegmented=0;
            cExperiment.posTracked=0;
            %Define the source folders (or Omero image names) for each
            %position

            tempdir=dir(cExperiment.rootFolder);

            cExperiment.dirs=cell(1);
            % created dirs - the list of positions - as the directories in
            % the rootFolder
                index=1;
                for i=1:length(tempdir)
                    if tempdir(i).isdir
                        if ~strcmp(tempdir(i).name(1),'.')
                            cExperiment.dirs{index}=tempdir(i).name;
                            index=index+1;
                        end

                    end
                end

            
            cExperiment.cellsToPlot=cell(1);
            cExperiment.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
            
            %Parse the microscope acquisition metadata and attach the structure to the
            %cExperiment object - this populates the metadata field of
            %cExperiment
            cExperiment.parseLogFile;
            
        end
        
    end
    
    methods(Static)

        function cExperiment = loadobj(LoadStructure)
            % cExperiment = loadobj(LoadStructure)
            % load function to help maintain back compatability and take
            % care of fiddly loading behaviour (such as logger)
            
            
            %% default loading method: DO NOT CHANGE
            
            FieldNames = fieldnames(LoadStructure);
            
            % back compatibility with when Omero type was just a multi
            % if'ed version of non-omero type
            if (ismember('OmeroDatabase',FieldNames) && ~isempty(LoadStructure.OmeroDatabase)) ||...
                    (ismember('omeroDs',FieldNames) && ~isempty(LoadStructure.omeroDs) )
                cExperiment = experimentTrackingOmero(true);
            else
                cExperiment = experimentTracking(true);
            end
            
            %only populate mutable fields occcuring in both the load object
            %and the cTimelapse object.
            FieldNames = intersect(FieldNames,fieldnames(cExperiment));
            
            for i = 1:numel(FieldNames)
                
                m = findprop(cExperiment,FieldNames{i});
                if ~ismember(m.SetAccess,{'immutable','none'})
                    cExperiment.(FieldNames{i}) = LoadStructure.(FieldNames{i});
                end
                
            end
            
            %% addtional stuff for back compatability etc.
            
            % Create a new experimentLogging object when loading:
            if ~cExperiment.shouldLog
                disp('Not generating log files now - to change open shouldLog property')
            end
            cExperiment.logger = experimentLogging(cExperiment,cExperiment.shouldLog);
            
            % back compatibility to put channel names into cExperiment
            % channelNames
            if isempty(cExperiment.channelNames)
                cTimelapse = cExperiment.loadCurrentTimelapse(1);
                cExperiment.channelNames = cTimelapse.channelNames;
            end
            
            
        end
                
        function cCellVision = loadDefaultCellVision
            file_path = mfilename('fullpath');
            filesep_loc = strfind(file_path,filesep);
            cellVision_path = fullfile(file_path(1:(filesep_loc(end-1)-1)),  'cCellVisionFiles', 'cCellVision_Brightfield_2_slices_default.mat');
            load(cellVision_path,'cCellVision');
        end
        
    end
end

