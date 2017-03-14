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
        pixelSize;
        trapsPresent;
        image_rotation;
        timepointsToLoad;
        timepointsToProcess;
        trackTrapsOverwrite;
        
        shouldLog; %a parameter that tells the logger whether it should do things 
        
        channelNames; %this has the list of the channel names  
        cellInf; % cell data compuled from extractedData in each of the individual timelapseTrap objects
        experimentInformation; %used by omero to store channel information; fields are .channels and .microscopeChannels
        cellVisionThresh; % used to overwrite the twoStageThresh of cellVision in 
                         %      experimentTrackingGUI.identifyCells
                         %importantly, not used in the experimentTracking
                         %method:
                         %  segmentCellDisplay.
        
        lineageInfo %for all of the cell births and stuff that occure during the timelapse
        
        OmeroDatabase %TODO delete this at end
        omeroDs %TODO delete this at end
                                
    end
    
    properties (Transient)
        % Transient properties won't be saved
        cTimelapse; % populated when loadCurrentTimelapse is used, and the cTimelapse saved when saveCurrentTimelapse is called.
        currentPos; % populated when loadCurrentTimelapse is called. Defaultfor where to then save the timelapse.
        kill_logger = false; % convenience property for test functions. Allows me to make the logger return nothing so that I can test differences (Elco).
                             % transient because most code now breaks of you
                             % don't have the logger operational.
    end
    
    properties (Dependent)
        id; % A unique ID that links this experiment to Omero (filled by experimentTracking.parseLogFile); cannot be set
        logger; % handle to an experimentLogging object to keep a log
    end
    
    properties (Access=private)
        id_val = '' % This should never be updated if non-empty
    end
    
    properties (Transient,Access=private)
        logger_val = []
    end
    
    properties (SetObservable, AbortSet)
        % properties for which set events can be written
        % AbortSet means they will not be triggered if the setting changes
        % nothing.
        cCellVision; % cellvision model applied throughout the segmentation, 
                     % particularly in segmentCellDisplay and
                     % identifyTrapsTimelapses.
        ActiveContourParameters; % parameters used in the ActiveContour 
                                 % methods, copied to each timelapseTraps
                                 % object when this is run (if parameters
                                 % selected appropriately)
                                
        
    end
    
    properties (Hidden=true)
        % these properties are not visible to the user
        oldcCellVisionPixelSize = []; %used to keep track of if Pixel Size has changed and warn user that results will be weird.
        clearOldTrapInfo = []; % if this is true, when reselecting the taps through IdentifyTrapsTimelapses it will clear trapInfo first.
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
            
            
            % Initialise source (root folder) and save paths
            if nargin<1
                fprintf('\n   Select the Root of a single experimental set containing folders of multiple positions \n');
                rootFolder=uigetdir(pwd,'Select the Root of a single experimental set containing folders of multiple positions');
            elseif islogical(rootFolder) && rootFolder
                % if folder is true, cExperiment returned bare for load
                % function.
                return
            end
            
            % Default to enabling logging:
            cExperiment.shouldLog=true;
            
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
            
            %TODO - update this to remove timelapseTrapsActiveContour
            cExperiment.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
            
            %Parse the microscope acquisition metadata and attach the 
            %structure to the cExperiment object - this populates the 
            %metadata field of cExperiment. Only the meta data is collected
            %at this stage; the full log file can be parsed at extraction
            %since this can take an annoyingly long time with lots of
            %positions/timepoints...
            cExperiment.parseLogFile([],'meta_only');
            
            % this will check the scaling of the new cCellVision is
            % different from that of the old cCellVision.
            addlistener(cExperiment,'cCellVision','PreSet',@(eventData,propertyData)cCellVisionPreSet(cExperiment,eventData,propertyData));
            addlistener(cExperiment,'cCellVision','PostSet',@(eventData,propertyData)checkCellVisionScaling(cExperiment,eventData,propertyData));
            
        end
        
        function cCellVisionPreSet(cExperiment,eventData,propertyData)
            % cCellVisionPreSet(cExperiment,eventData,propertyData)
            % set the oldcCellVisionPixelSize so it can be used for
            % comparison in the postSetMethod
            if ~isempty(cExperiment.cCellVision) && isa(cExperiment.cCellVision,'cellVision')
                cExperiment.oldcCellVisionPixelSize = cExperiment.cCellVision.pixelSize;
            end
        end
        
        function checkCellVisionScaling(cExperiment,eventData,propertyData)
            % checkCellVisionScaling(cExperiment,eventData,propertyData)
            % check if the new pixelSize is the same as the old pixelSize,
            % and warn if not.
            if ~isempty(cExperiment.cCellVision) && isa(cExperiment.cCellVision,'cellVision')
                if ~isempty(cExperiment.oldcCellVisionPixelSize) && ...
                        cExperiment.oldcCellVisionPixelSize ~= cExperiment.cCellVision.pixelSize;
                    warndlg({'WARNING!!'...
                            ;'the cellVision model you have just loaded has a different pixel size from the one you were using to analyze this experiment. This may lead to errors and strange results.'...
                            ;''...
                            ;'It is STRONGLY recommended you reselect traps'});
                end
            end
        end
        
        function set.cCellVision(cExperiment,cCellVision)
            %TODO - populate this to recaluclate rescale values when
            %cellVision is loaded.
            if isempty(cCellVision) || isa(cCellVision,'cellVision')
                if isa(cCellVision,'cellVision') && isa(cExperiment.cCellVision,'cellVision')
                    % if the cTrap properties (which has all the traps
                    % defining features) is false
                    if ~isequaln(cCellVision.cTrap,cExperiment.cCellVision.cTrap) || ...
                        cCellVision.pixelSize ~= cExperiment.cCellVision.pixelSize
                        % this is not very good code (see matlab warning)
                        % but given that it is only set true if cCellVision
                        % is being changed for another cCellVision I don't
                        % think it will be a problem (like in the load,
                        % where cCellVision would replace an empty field).
                        cExperiment.clearOldTrapInfo = true(size(cExperiment.dirs));
                    end
                end
                cExperiment.cCellVision = cCellVision; 
            else
                warndlg({'WARNING! experimentTracking.cCellVision mut be empty or a cellVision object.';'Not setting cCellVision property';'(if you wih to change this change the set.cCellVision method of experimentTracking)'})
                return
            end
                
        end
        
        function set.cTimelapse(cExperiment,cTimelapse)
            
            %though this is bad code, since both properties are transient
            %it shouldn't be a problem.
            if ~isequal(cExperiment.cTimelapse,cTimelapse)
                cExperiment.currentPos = [];
            end
            cExperiment.cTimelapse = cTimelapse;
        end
        
        function val = get.id(cExperiment)
            if isempty(cExperiment.id_val)
                % The ID will only be missing if the latest parseLogFile 
                % function has not yet been run on the experiment
                if isempty(cExperiment.metadata) || ~isfield(cExperiment.metadata,'acqFile')
                    fail_flag = cExperiment.parseLogFile([],'meta_only');
                    if fail_flag
                        val = '';
                    else
                        cExperiment.saveExperiment; % Save changes made by parseLogFile
                        val = cExperiment.id_val; % Updated by parseLogFile script
                    end
                else
                    val = cExperiment.parseAcqFileIntoID(cExperiment.metadata.acqFile);
                    cExperiment.id_val = val;
                    cExperiment.saveExperiment; % Save the new id into the cExperiment
                end
            else
                val = cExperiment.id_val;
            end
        end
        function set.id(cExperiment,val)
            % currently does nothing, just stops warnings.
            % fprintf('setting id has no effect. It is a dependent property.')
        end
        
        function val = get.logger(cExperiment)
            
            % put in temporarily by Elco. Logger is breaking my test
            % scripts.
            if cExperiment.kill_logger
                val = [];
                return
            end
            
            if isempty(cExperiment.logger_val)
                % Create a new logger to log changes for this cExperiment:
                cExperiment.logger_val = experimentLogging(cExperiment);
            end
            % Always ensure that the 'shouldLog' state of the logger 
            % matches that of the cExperiment:
            cExperiment.logger_val.shouldLog = cExperiment.shouldLog;
            val = cExperiment.logger_val;
        end
        function set.logger(cExperiment,val)
            % just to stop bugs and warnings on load.
            % fprintf('setting logger has no effect. It is a dependent property.')
        end
    end
    
    methods (Static,Access=private)
        function val = parseAcqFileIntoID(acqfile)
            [acqdir,~,~] = fileparts(acqfile);
            val = regexprep(acqdir,...
                ['^.*AcquisitionData(?<mic>[^/\\]+)[/\\]',... % Microscope ID
                'Swain Lab[/\\](?<user>[^/\\]+)[/\\]RAW DATA[/\\]',... % User ID
                '(?<year>\d+)[/\\](?<month>\w+)[/\\](?<day>\d+)',... % Date
                '[^/\\]*[/\\](?<name>.*)$'],... % Experiment name
                '$<user>_$<mic>_$<year>_$<month>_$<day>_$<name>'); % Replacement string
        end
    end
    
    methods(Static)

        function cExperiment = loadobj(LoadStructure)
            % cExperiment = loadobj(LoadStructure)
            % load function to help maintain back compatability and take
            % care of fiddly loading behaviour
            
            
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
            
            % this will check the scaling of the new cCellVision is
            % different from that of the old cCellVision.
            addlistener(cExperiment,'cCellVision','PreSet',@(eventData,propertyData)cCellVisionPreSet(cExperiment,eventData,propertyData));
            addlistener(cExperiment,'cCellVision','PostSet',@(eventData,propertyData)checkCellVisionScaling(cExperiment,eventData,propertyData));
            
            
            %% addtional stuff for back compatability etc.
            
            % Warn the user when loading if shouldLog is false
            if ~cExperiment.shouldLog
                warning('Logging is not active. To change, set "cExperiment.shouldLog = true"');
            end
            
            % back compatibility to put channel names into cExperiment
            % channelNames
            if isempty(cExperiment.channelNames)
                cTimelapse = cExperiment.loadCurrentTimelapse(1);
                cExperiment.channelNames = cTimelapse.channelNames;
            end
            
            if isempty(cExperiment.clearOldTrapInfo)
                cExperiment.clearOldTrapInfo = false(size(cExperiment.dirs));
            end
            
            if isempty(cExperiment.posSegmented)
                cExperiment.posSegmented = false(size(cExperiment.dirs));
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

