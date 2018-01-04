classdef timelapseTrapsOmero<timelapseTraps
    % TIMELAPSETRAPSOMERO A subclass of timelapseTraps to process images
    % coming from Omero Database via Ivan's OmeroCode.
    % See also EXPERIMENTTRACKINGOMERO, TIMELAPSETRAPS
    
    properties
        
        %TODO reinstate when have finished decoupling omero.
        %microscopeChannels%cell array of channel names as defined by the microscope software.
        
        
        %stuff Ivan has added
        omeroImage%The (unloaded - no data) omero image object in which the raw data is stored (or empty if the object is created from a folder of images).
        OmeroDatabase%OmeroDatabase object representing the database that the omeroImage comes from.
        microscopeChannels
        segmentationSource='';%Flag to determine where the source data was obtained during segmentation, can be 'Omero', 'Folder' or empty (if not segmented). Data segemented from a file folder must be flipped both vertically and horizontally to match the segmentation results
        archivedChannelNames={};%Channel names from folder cTimelapse; empty unless converted from folder cTimelapse
        fileAnnotation_id%id number of the file annotation used to save the timelapseTrapsOmero object in the database

    end
    properties (Transient)
        
        %temporaryImageStorage=struct('channel',-1,'images',[]); %this is to store the loaded images from a single channel (ie BF) into memory
        %This allows the cell tracking and curating things to happen a
        %whole lot faster and easier. This way you can just modify the
        %returnTimepoint file to check to see if something is loaded.
        % - channel
        % - images
    end
    
    methods
        

        function cTimelapseOmero=timelapseTrapsOmero(omeroImage,varargin)
            % cTimelapseOmero=timelapseTrapsOmero(omeroImage,varargin)
            % instantiate cTimelapseOmero from omeroImage.
            %
            % varargin{1} can be a logical that will make the constructor
            % run nothing if it is true. this was done to be able to write
            % nice load functions.
            %
            % Most of the actual setting up is done by
            % TIMELAPSETRAPSOMERO.LOADTIMELAPSE
            %
            % See also, TIMELAPSETRAPSOMERO.LOADTIMELAPSE
            
            if nargin>=2 && islogical(varargin{1}) && varargin{1}
                NoAction = varargin{1};
            else
                NoAction = false;
                cExperiment=varargin{1};
            end
            
            % call timelapseTraps constructor as though loading (i.e. to
            % make a bare object).
            cTimelapseOmero@timelapseTraps([],true);
            
            if ~NoAction
                
                cTimelapseOmero.omeroImage=omeroImage;
                cTimelapseOmero.OmeroDatabase=varargin{1}.OmeroDatabase;
                cTimelapseOmero.microscopeChannels=varargin{1}.experimentInformation.MicroscopeChannels;
                
                %%%%%% WARNING %%%%%%
                % The following code has a number of unresolved bugs:
                % - posNum should be the *log file* posNum; consider using
                %   a posName argument instead
                % - varargin{2} is used for multiple variables; consider
                %   using inputParser
                % - metadata.logExposureTimes will be inaccurate if
                %   parseLogFile is called with 'metaonly' flag and one of 
                %   the channels has skip defined; use of 
                %   metadata.acq.positions table would be preferable (this
                %   table also contains position names); use in conjunction
                %   with metadata.acq.channels.names
                % - What is the purpose of the cellsToPlot argument?
                % - Should the code be more careful in matching
                %   MicroscopeChannels with acq.channels.names?
                
                %To define the channels - need to know which channels are 
                %used at this position (i.e. have non-zero exposure times)
                posNum=varargin{2};
                expos=struct2table(cExperiment.metadata.logExposureTimes);
                usedMicroscopeChannels=table2array(expos(posNum,:))~=0;%Logical array indexing the microscope channels (ie members of cExperiment experimentInformation.microscopeChannels) used by this position
                usedChannels=ismember(cExperiment.metadata.microscopeChannelIndices,find(usedMicroscopeChannels));%Index to the channels (including single section channels) used by this position
                cTimelapseOmero.channelNames=cExperiment.channelNames(usedChannels);
                if nargin<4
                    cTimelapseOmero.cellsToPlot=sparse(100,1e3);
                else
                    cTimelapseOmero.cellsToPlot=varargin{2};
                end
            end
        end
        
        function name = getName(cTimelapseOmero)
            % name = getName(cTimelapse)
            % sometimes you want to have an identifiable name for a timelapseTraps
            % object, for figure names and such.
            name = char(cTimelapseOmero.omeroImage.getName.getValue);
        end
    end
    
    methods (Access={?timelapseTraps,?timelapseTrapsOmero,?OmeroDatabase})
        function propNames = copyprops(cTimelapse,TemplateTimelapse,omit)
            %COPYPROPS Copy all properties from cTimelapse into this one
            %   This function can copy both public and private properties.
            %   Use OMIT to specify a cellstr of properties that will not
            %   be copied. This function gets used in the loadobj method
            %   and also by the convertSegmented method of the 
            %   OmeroDatabase class.
            
            if nargin<3 || isempty(omit), omit = {}; end
            if ~iscellstr(omit)
                error('The "omit" argument must be a cellstr.');
            end
            
            copied = copyprops@timelapseTraps(cTimelapse,TemplateTimelapse,omit);
            
            % Only populate copyable fields occuring in both this object
            % and the template object:
            propNames = intersect(...
                getCopyableProperties(cTimelapse,'timelapseTrapsOmero'),...
                getCopyableProperties(TemplateTimelapse,'timelapseTrapsOmero'));
            % Omit properties copied by parent:
            propNames = setdiff(propNames,copied);
            % Omit requested properties:
            propNames = setdiff(propNames,omit);
            
            % Copy all properties/fields to this cTimelapse:
            for f = 1:numel(propNames)
                cTimelapse.(propNames{f}) = TemplateTimelapse.(propNames{f});
            end
        end
    end
    
    methods (Static)
        function cTimelapseOmero = loadobj(load_structure)
            % cTimelapseOmero = loadobj(load_structure)
            % currently just runs TIMELAPSETRAPS loadobj method, but could
            % be modified to do different things.
            cTimelapseOmero = loadobj@timelapseTraps(load_structure);
            
            
        end
        function cTimelapseOmero_save = saveobj(cTimelapseOmero_in)
            % cTimelapse_save = saveobj(cTimelapseOmero_in)
            % currently just runs TIMELAPSETRAPS saveobj method, but could
            % be modified to do different things.
            
            cTimelapseOmero_save = saveobj@timelapseTraps(cTimelapseOmero_in);
            
        end
    end
end

