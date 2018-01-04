classdef experimentTrackingOmero < experimentTracking
    % EXPERIMENTTRACKINGOMERO a subclass of experimentTracking to hold
    % cExperiments that access data, and are stored on, the swain lab OMERO
    % data base.
    % requires the repository OmeroCode from the swain lab skye repository.
    %
    % See also EXPERIMENTTRACKING,EXPERIMENTTRACKINGGUI,TIMELAPSETRAPS
    
    properties
         omeroDs%Omero dataset object - alternative source to rootFolder
         OmeroDatabase%Omero database object
         fileAnnotation_id%id number of the file annotation used to save the experimentTrackingOmero object in the database
         logFileAnnotation_id%id number of the file annotation used to save the experimentTrackingOmero log file in the database
         segmentationSource='';%Flag to determine where the source data was obtained during segmentation, can be 'Omero', 'Folder' or empty (if not segmented). Data segemented from a file folder must be flipped both vertically and horizontally to match the segmentation results
         archivedChannelNames = {};%Channel names from folder cExperiment; empty unless converted from folder cExperiment
    end
    
    methods
        function cExperimentOmero = experimentTrackingOmero(OmeroDataSet,OmeroDataPath, OmeroDatabase,  expName)
            %experimentTrackingOmero Create a new experimentTrackingOmero object
            %   If OmeroDataSet is a char, then it specifies the root 
            %   directory that this experiment is being loaded from and
            %   then OmeroDataPath specifies the save directory.
            %   Otherwise, OmeroDataSet must be an Omero Dataset object and
            %   OmeroDataPath is ignored.
            
            % cExperimentOmero = experimentTrackingOmero(OmeroDataSet,OmeroDataPath, OmeroDatabase,  expName)
            % cExpGUI.cExperiment=experimentTrackingOmero(dsStruct(1).dataset,[],dsStruct.OmeroDatabase,inputName);
 
            % Code written by Ivan but edited (ignorantly) by Elco -
            % should go over together.
            % variables named according to call in
            %   experimentTrackingGUI.createFromOmero
            % 
            % 
            % Folder input is a string with the full path to the root folder or an Omero dataset object (in that case the OmeroDatabase object must also be input)
            %Optional inputs 2-4 only used when creating objects using the
            %Omero database: OmeroDatabase - object of class OmeroDatabase
            %expName, a unique name for this cExperiment
            % if folder is the logical true then this is a queue to loada
            % 'bare' cExperiment (i.e. with no defined fields) or user
            % inputs. Used in loadobj method.
            
            % call super class constructor such that it does not initialise
            % anything.
            cExperimentOmero@experimentTracking(true);
            
            % If initialised with single input true, make an empty object
            % (used in load function)
            if nargin==1 && islogical(OmeroDataSet) && OmeroDataSet
                % if folder is true, cExperiment returned bare for load
                % function.
                return
            end
            
            % Default to enabling logging:
            cExperimentOmero.shouldLog=true;
            % NB: constructor no longer needs to instantiate the logger
            % property, see experimentTracking
            
            if ischar(OmeroDataSet)%cExperiment is being initialised from a folder
                cExperimentOmero.rootFolder=OmeroDataSet;
                cExperimentOmero.saveFolder=OmeroDataPath;
            else%Experiment is being initialized from an Omero dataset - folder is an omero.model.DatasetI object
                if nargin>3
                    if iscell(expName)
                        expName=expName{:};
                    end
                    cExperimentOmero.rootFolder=expName;
                else
                    cExperimentOmero.rootFolder='001';%default experiment name
                end
                cExperimentOmero.saveFolder = OmeroDatabase.downloadDir(OmeroDataSet);
                %Define the Omero properties of cExperiment
                cExperimentOmero.omeroDs=OmeroDataSet;
                cExperimentOmero.OmeroDatabase=OmeroDatabase;
            end
            %Record the user who is creating the cExperiment
            if ispc
                cExperimentOmero.creator=getenv('USERNAME');
            else
                [~, cExperimentOmero.creator] = system('whoami');
            end
            %Initialize records of positions segmented and tracked
            cExperimentOmero.posSegmented=0;
            cExperimentOmero.posTracked=0;
            
            %Position list consists of the Omero image names
            %Make sure the image list is loaded
            cExperimentOmero.omeroDs=getDatasets(OmeroDatabase.Session,cExperimentOmero.omeroDs.getId.getValue, true);
            %Get the image list
            oImages=cExperimentOmero.omeroDs.linkedImageList;
            for i=1:oImages.size
                cExperimentOmero.dirs{i}=char(oImages.get(i-1).getName.getValue);
            end
            cExperimentOmero.dirs=sort(cExperimentOmero.dirs);
            
            cExperimentOmero.cellsToPlot=cell(1);
            cExperimentOmero.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
            
            %Parse the microscope acquisition metadata and attach the structure to the
            %cExperiment object - this populates the metadata field of
            %cExperiment
            
            %need to ensure that the log and acq files from the database 
            %are downloaded before parsing
            expName=char(OmeroDataSet.getName.getValue);
            logName=[expName(1:end-3) 'log.txt'];
            acqName=[expName(1:end-3) 'Acq.txt'];
            logPath=cExperimentOmero.OmeroDatabase.downloadFile(OmeroDataSet,logName);
            cExperimentOmero.OmeroDatabase.downloadFile(OmeroDataSet,acqName);
            
            %Parse the microscope acquisition metadata and attach the 
            %structure to the cExperiment object - this populates the 
            %metadata field of cExperiment. Only the meta data is collected
            %at this stage; the full log file can be parsed at extraction
            %since this can take an annoyingly long time with lots of
            %positions/timepoints...
            parseFailed = cExperimentOmero.parseLogFile(logPath,'meta_only');
            
            %Set the channels field - add a separate channel for each section in case
            %they are required for data extraction or segmentation:
            %Get the number of Z sections
            im=oImages.get(0);%the first image - assumes all images have the same dimensions
            pixels=im.getPrimaryPixels;
            sizeZ=pixels.getSizeZ.getValue;
            %Get the list of channels from the microscope log
            % if parseFailed, the parseLogFile method was not able to find
            % the acq file or the log file, and so the channel names are
            % unknown.
            if ~parseFailed
                origChannels=cExperimentOmero.metadata.acq.channels.names;
            else
                numChannels=pixels.getSizeC.getValue;
                origChannels = cell(1,numChannels);
                for nc = 1:numChannels
                    origChannels{nc} = sprintf('CH_%d',nc);
                end
            end
            
            cExperimentOmero.OmeroDatabase.MicroscopeChannels = origChannels;
            cExperimentOmero.experimentInformation.MicroscopeChannels=origChannels;
            cExperimentOmero.OmeroDatabase.Channels=origChannels;
           
            %The first entries in
            %cExperiment.experimentInformation.channels are the
            %original channels - then followed by a channel for each
            %section.
            %First create a record for which of the channel names in
            %cExperiment relate to which microscope channels
            cExperimentOmero.metadata.microscopeChannelIndices=1:length(cExperimentOmero.experimentInformation.MicroscopeChannels);
            if sizeZ>1
                for ch=1:length(origChannels)
                    if parseFailed || cExperimentOmero.metadata.acq.channels.zsect(ch)==1%Does the channel do z sectioning?
                        for z=1:sizeZ
                            cExperimentOmero.OmeroDatabase.Channels{end+1}=...
                                                            [origChannels{ch} '_' num2str(z)];
                            cExperimentOmero.metadata.microscopeChannelIndices(end+1)=ch;                   
                        end
                    end
                    
                end
            end
            cExperimentOmero.experimentInformation.channels = cExperimentOmero.OmeroDatabase.Channels;
            
            %TODO - check this works.
            cExperimentOmero.channelNames = cExperimentOmero.experimentInformation.channels;
            
           % this will check the scaling of the new cCellVision is
            % different from that of the old cCellVision.
            addlistener(cExperimentOmero,'cCellVision','PreSet',@(eventData,propertyData)cCellVisionPreSet(cExperimentOmero,eventData,propertyData));
            addlistener(cExperimentOmero,'cCellVision','PostSet',@(eventData,propertyData)checkCellVisionScaling(cExperimentOmero,eventData,propertyData));
            
            
        end
    end
    
    methods (Access={?experimentTracking,?experimentTrackingOmero,?OmeroDatabase})
        function propNames = copyprops(cExperiment,TemplateExperiment,omit)
            %COPYPROPS Copy all properties from a cExperiment into this one
            %   This function can copy both public and private properties.
            %   Use OMIT to specify a cellstr of properties that will not
            %   be copied. This function gets used in the loadobj method
            %   and also by the convertSegmented method of the 
            %   OmeroDatabase class.
            
            if nargin<3 || isempty(omit), omit = {}; end
            if ~iscellstr(omit)
                error('The "omit" argument must be a cellstr.');
            end
            
            copied = copyprops@experimentTracking(cExperiment,TemplateExperiment,omit);
            
            % Only populate copyable fields occuring in both this object
            % and the template object:
            propNames = intersect(...
                getCopyableProperties(cExperiment,'experimentTrackingOmero'),...
                getCopyableProperties(TemplateExperiment,'experimentTrackingOmero'));
            % Omit requested properties:
            propNames = setdiff(propNames,omit);
            
            % Omit properties copied by parent:
            copyNames = setdiff(propNames,copied);
            
            % Copy all properties/fields to this cExperiment:
            for f = 1:numel(copyNames)
                cExperiment.(copyNames{f}) = TemplateExperiment.(copyNames{f});
            end
        end
    end
    
    methods (Static)
        
        function cExperimentOmero = loadobj(load_structure)
            % currently just calls experimentTracking load function, but
            % could be modified to be omero specific.
            % has the nice property that it will load a non omero
            % experimentTracking object if there is no omeroDs or
            % OmeroDatabase (I think - Elco)
            cExperimentOmero = loadobj@experimentTracking(load_structure);
            
        end
        
    end
    
end

