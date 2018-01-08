classdef timelapseTraps<handle
    % TIMELAPSETRAPS This is the central class used in processing images in
    % the swainlab segmentation software, with EXPERIMENTTRACKING
    % organisining on of these TIMELAPSETRAPS objects per positions. It
    % stores the location of the images for each channel at each timepoint,
    % processing parameters and all the segmentation results (which are
    % then compiled together in EXPERIMENTTRACKING). 
    % Each timepoint is stored as an entry in the cTimepoint structure
    % array. This contains:
    %
    % filename:      cell array of the names of the files associated with
    %                that timepoint
    %
    % after processing it also stores:
    %
    % trapLocations: the location of the traps. 
    % trapInfo:      a structure that holds all the information about the
    %                location, label and outline of each cell in each trap
    %
    % See also EXPERIMENTTRACKING
    
    properties
        fileSoure = 'swain-batman' %a string informing the software where the files came from. Informs the addSecondaryChannel method.
        timelapseDir %Location in which files are stored. set to 'ignore' to use absolute file names
        cTimepoint  %structure array. This contains:
                    %
                    %filename:      cell array of the names of the files associated with that timepoint
                    %
                    %after processing it also stores:
                    %
                    %trapLocations: the location of the traps.
                    %trapInfo:      a structure that holds all the information about the
                    %               location, label and outline of each cell in each trap
                    %trapMaxCell :  the maximum cell label for the cells in that trap
                    %
        cTrapSize % size of the trap image - set during the identifyTrapLocationsSingleTP method. 
                  % defines the size of the trap extracted in methods such
                  % as returnTrapsTimepoint/returnWholeTrapImage/returnTrapsFromImage etc.
                  % empty if there are not traps
        image_rotation % to ensure that it lines up with the trap images cCellVision Model
        imScale % used to scale down images if needed
                % this isn't used much so the GUI sets it to a default of
                % empty.
        magnification=60; % magnification of the objective used 
                          % used to generate a scaling factor in
                          % segmentCellDisplay/cTrapDisplayProcessing/identifyCellCentres
                          % (exercise caution, changes in magnification is
                          % very poorly maintained in the code) and as such
                          % the experiment Tracking GUI sets it to a default of 60.
                          
        trapsPresent % a boolean whether traps are present or not in the image
        pixelSize = 0.263; % the real size of pixels in the image. default of 0.263 is for swainlab microscopes at 60x.
        cellsToPlot %Array indicating which cells to extract data for. row = trap num, col is cell tracking number
        timepointsProcessed %a logical array of timepoints which have been processed
        timepointsToProcess %list of timepoints that should be processed (i.e. checked for cells and what not)
        extractedData %a structure array of sparse arrays of extracted statistics for the cell. One entry for each channel extracted, one row in the array for each cell with zeros where the cell is absent.
        channelNames % cell array of channel names. Used in selecting the file(s) to load when a particular channel is selected in returnImage method
        imSize %the size of the images after rotation.
        rawImSize % size of the images before any rescaling or rotation.
        scaledImSize % size of images after rescaling but before rotation.
        channelsForSegment = 1; %index of the channels to use in the centre finding segmentation .default to 1 (normally DIC)
        channelForTrapDetection = 1; %channel used in cTrapSelectDisplay to identify traps. Traps should appear the same in this channel as they do in cellVision.cTrap.trap1/trap2.
        lineageInfo %structure array to hold everything associated with daughter counting (namely, the birth times, mother labels, daughter labels etc.)
        %stuff Elco has added
        offset = [0 0] %a n x 2 offset of each channel compared to DIC. So [0 0; x1 y1; x2 y2]. Positive shifts left/up.
        BackgroundCorrection = {[]}; %correction matrix for image channels. If non empty, returnSingleTimepoint will '.multiply' the image by this matrix.
                                     %this is applied BEFORE rescaling, on the grounds that the background correction is generally found from the raw images. 
        BackgroundOffset = {[]}; %scalar offset to be used with BackgroundCorrection matrix. If non empty, returnSingleTimepoint will subtract this offset 
                                 %before multiplying by the correction matrix, then add it back after applying
                                 %the correction matrix. This is to stop the flatfield correction inflating the noise
                                 %where readings are low.
                                 %Adding back is mostly to keep things compatible with older data. 
        ErrorModel = {[]}; % an object of the error model class that returns an error based on pixel intensity to give a shot noise 
                           %estimate for the cell.
        extractionParameters = timelapseTraps.defaultExtractParameters;
        %parameters for the extraction of cell Data, a function handle and
        %a parameter structure which the function makes use of.
        ACParams = []; % active contour parameters.
        ActiveContourObject = []; % there for legacy reasons. Will be removed soon but difficult to reprocess old data sets once it is.
        
        metadata = [];
       
    end
    
    properties(Dependent = true)
        % not real properties,calculated from other data.
        defaultTrapDataTemplate % a sparse array of the right size for holding semgmentation data
        cellInfoTemplate % template for the cellInfo structure.
        trapInfoTemplate % template for the trapInfo structure
        cTimepointTemplate % template for the cTimepoint structure.
        trapImSize % uses the cTrapSize property to give the size of the image.
    end
    
    properties(SetAccess = immutable)
        
    end
    
    properties(Constant)
        %TODO - want parfor as standard extraction?
    defaultExtractParameters = struct('extractFunction',@extractCellDataStandardParfor,...
        'functionParameters',struct('type','max','channels','all','nuclearMarkerChannel',NaN,'maxPixOverlap',5,'maxAllowedOverlap',25));
    
    end
    
    properties (Transient)
        % Transient properties won't be saved
        logger; % *optional* handle to an experimentLogging object to keep a log
        temporaryImageStorage=struct('channel',-1,'images',[]); %this is to store the loaded images from a single channel (ie BF) into memory
        %This allows the cell tracking and curating things to happen a
        %whole lot faster and easier. This way you can just modify the
        %returnTimepoint file to check to see if something is loaded.
        % - channel
        % - images
        kill_logger = false; % convenience property for test functions. Allows me to make the logger return nothing so that I can test differences (Elco).
                             % transient because most code now breaks of you
                             % don't have the logger operational.
        cCellVision % cellVision object for selecting new cells
        cCellMorph % cellMorphologyModel object for selecting new cells.
    end
    
   
    
    events
        LogMsg
        TimepointChanged
    end
    
    methods
        
        function cTimelapse=timelapseTraps(folder,varargin)
            % cTimelapse=timelapseTraps(folder,varargin)
            % instantiate a timelapseTraps object from a folder containing
            % images. If folder is empty it is requested by uigetdir, and
            % it becomes the timelapseDir.
            % 
            % varargin{1} can be a logical that will make the constructor
            % run nothing if it is true. this was done to be able to write
            % nice load functions.
            %
            % Most of the actual setting up is done by
            % TIMELAPSETRAPS.LOADTIMELAPSE
            %
            % See also, TIMELAPSETRAPS.LOADTIMELAPSE
            
            if nargin>=2 && islogical(varargin{1})
                NoAction = varargin{1};
            else
                NoAction = false;
            end
            
            if ~NoAction
                if nargin<1 || isempty(folder)
                    folder=uigetdir(pwd,'Select the folder containing the images associated with this timelapse');
                    fprintf('\n    Select the folder containing the images associated with this timelapse\n');
                end
                cTimelapse.timelapseDir=folder;
                cTimelapse.cellsToPlot=sparse(100,1e3);
            end
        end
            
        function name = getName(cTimelapse)
            % name = getName(cTimelapse)
            % sometimes you want to have an identifiable name for a timelapseTraps
            % object, for figure names and such.
            try
                if strcmp(cTimelapse.timelapseDir,'ignore')
                    name = cTimelapse.cTimepoint(1).filename{1};
                else
                    name = [cTimelapse.timelapseDir '/'];
                end
                
                % get section of this path between second to last /|\ and
                % last /|\ in a reasonably robust way.
                locs = regexp(name,'[\\|/]','start');
                name = name(max(locs(max(length(locs)-2,1))+1,1):max(locs(end)-1,1));
                
            catch
                name = [];
            end
        end
        
        
        function cTimelapseOUT = copy(cTimelapseIN)
        %cTimelapseOUT = copy(cTimelapseIN)
        % make a new cTimelapse object with all the same field values. 
        % care has been taken here to also copy the
        % timelapseTrapsActiveContour object which is a handle object.
            cTimelapseOUT = timelapseTraps([],true);
            
            FieldNames = fields(cTimelapseIN);
            
            for i = 1:numel(FieldNames)
                m = findprop(cTimelapseIN,FieldNames{i});
                if ~ismember(m.SetAccess,{'immutable','none'}) || m.Dependent
                    cTimelapseOUT.(FieldNames{i}) = cTimelapseIN.(FieldNames{i});
                end
            end

            
        end
        
        function trapInfo_struct = createTrapInfoTemplate(cTimelapse,data_template)
            % trapInfo_struct =
            % createTrapInfoTemplate(cTimelapse,data_template)
            %
            % create strandard empty trapInfo structure for use in
            % intialising trapInfo.
            %
            % data template is optional. should be a sparse array. If not
            % it throws an error. default is spares of size cTrapSize. If
            % this is empty it juse uses an empty array.
            
            if nargin<2
                data_template = cTimelapse.defaultTrapDataTemplate;
            elseif ~issparse(data_template)
                error('data_template should be a sparse array')
                
            end
            trapInfo_struct = cTimelapse.trapInfoTemplate;
            trapInfo_struct.cell = cTimelapse.cellInfoTemplate;
            trapInfo_struct.segCenters = data_template;
            trapInfo_struct.segmented = data_template;
            trapInfo_struct.trackLabel = data_template;
            trapInfo_struct.cell.segmented = data_template;
            
        end
        
        function default_trap_indices = defaultTrapIndices(cTimelapse,tp)
            % default_trap_indices = defaultTrapIndices(cTimelapse,tp=1)
            % return the default trap indices to run anything over.
            if nargin<2
                tp = cTimelapse.timepointsToProcess(1);
            end
            default_trap_indices = 1:length(cTimelapse.cTimepoint(tp).trapInfo);
        end
        
        function data_template = get.defaultTrapDataTemplate(cTimelapse)
            % data_template = defaultTrapDataTemplate(cTimelapse)
            % returns a sparse array of the default size for populating
            % cell and trapInfo structures. Used at various points in the
            % code where these things need to be populated.
            % for trap containing cTimelapses, this is the trapSize.
            % for those without traps, it is the image size.
            data_template_size = cTimelapse.trapImSize;
            if ~isempty(data_template_size)
                data_template = spalloc(data_template_size(1),data_template_size(2),...
                    ceil(data_template_size(1)*data_template_size(2)/8));
            else
                data_template =(sparse([]));
            end
            
        end
        
        function trapImSize = get.trapImSize(cTimelapse)
            % size of the trap if traps present or imSize if not.
            trapImSize = [];
            if ~isempty(cTimelapse.trapsPresent)
                if cTimelapse.trapsPresent &&  ~isempty(cTimelapse.cTrapSize)
                    trapImSize = 2*[cTimelapse.cTrapSize.bb_height cTimelapse.cTrapSize.bb_width] + 1;
                elseif   ~cTimelapse.trapsPresent &&  ~isempty(cTimelapse.imSize)
                    trapImSize = cTimelapse.imSize;
                end
            end
        end
        
        function cTimelapse = set.trapImSize(cTimelapse,input)    
            % do nothing, just to stop errors
            %fprintf('\n\n trapImSize cannot be set. change cTrapSize instead\n\n')
        end
        
        function cTimelapse = set.defaultTrapDataTemplate(cTimelapse,input)    
            % do nothing, just to stop errors
            %fprintf('\n\n trapImSize cannot be set. change cTrapSize instead\n\n')
        end

        function cTimelapse = set.cellInfoTemplate(cTimelapse,input)
            % do nothing, just to stop errors
            %fprintf('\n\n trapImSize cannot be set. change cTrapSize instead\n\n')
        end
        
        function cTimelapse = set.trapInfoTemplate(cTimelapse,input)
             % do nothing, just to stop errors
            %fprintf('\n\n trapImSize cannot be set. change cTrapSize instead\n\n')
        end
        function cTimelapse = set.cTimepointTemplate(cTimelapse,input)
             % do nothing, just to stop errors
            %fprintf('\n\n trapImSize cannot be set. change cTrapSize instead\n\n')
        end
        
        function cellInfoTemplate = get.cellInfoTemplate(cTimelapse)
            
            
             segTemplate = cTimelapse.defaultTrapDataTemplate;
            
             cellInfoTemplate = struct('cellCenter',[],...
                       'cellRadius',[],...
                       'segmented',segTemplate,...
                       'cellRadii',[],...
                       'cellAngle',[]);
        end
        
        function trapInfoTemplate = get.trapInfoTemplate(cTimelapse)
            
            trapInfoTemplate = struct('segCenters',[],...
                'cell',cTimelapse.cellInfoTemplate, ...
                'cellsPresent',0,'cellLabel',[],'segmented',[],'trackLabel',[]);
            
        end
        
        function cTimepointTemplate =get.cTimepointTemplate(cTimelapse)
            
            cTimepointTemplate = struct('filename',[],'trapLocations',[],...
                            'trapInfo',cTimelapse.trapInfoTemplate,'trapMaxCell',[]); %template for the cTimepoint structure

        end
        function val = get.logger(cTimelapse)
            if cTimelapse.kill_logger
                val = [];
                return
            end
            val = cTimelapse.logger;
        end

    end
    
    methods (Access={?timelapseTraps,?timelapseTrapsOmero,?OmeroDatabase})
        function propNames = copyprops(cTimelapse,TemplateTimelapse,omit)
            %COPYPROPS Copy all properties from a cTimelapse into this one
            %   This function can copy both public and private properties.
            %   Use OMIT to specify a cellstr of properties that will not
            %   be copied. This function gets used in the loadobj method
            %   and also by the convertSegmented method of the 
            %   OmeroDatabase class.
            
            if nargin<3 || isempty(omit), omit = {}; end
            if ~iscellstr(omit)
                error('The "omit" argument must be a cellstr.');
            end
            
            % Only populate copyable fields occuring in both this object
            % and the template object:
            propNames = intersect(...
                getCopyableProperties(cTimelapse,'timelapseTraps'),...
                getCopyableProperties(TemplateTimelapse,'timelapseTraps'));
            % Omit requested properties
            propNames = setdiff(propNames,omit);
            
            % Copy all properties/fields to this cTimelapse:
            for f = 1:numel(propNames)
                cTimelapse.(propNames{f}) = TemplateTimelapse.(propNames{f});
            end
        end
    end
    
    methods (Static)
        
        function help_string = helpOnActiveContourParameters
            help_string = HelpHoldingFunctions.active_contour_parameters()
        end
        
        function cTimelapse = loadobj(LoadStructure)
            
            %% default loading method: DO NOT CHANGE
            
            % LoadStructure could be of class 'timelapseTraps',
            % 'timelapseTrapsOmero', or a 'struct'. The following 
            % returns fieldnames of a struct or public properties of an
            % object:
            FieldNames = fieldnames(LoadStructure);
            
            % if OmeroDatabase is present, then this should be an Omero
            % type timelapse. Little ugly but keeps back compatability.
            if (ismember('OmeroDatabase',FieldNames) && ~isempty(LoadStructure.OmeroDatabase)) ||...
                    (ismember('omeroImage',FieldNames) && ~isempty(LoadStructure.omeroImage))
                cTimelapse = timelapseTrapsOmero([],true);
            else
                cTimelapse = timelapseTraps([],true);
            end
            
            cTimelapse.copyprops(LoadStructure);
            
            %% back compatibility checks and what not
            %when a new field is added this load operation should be
            %updated to populate the field appropriately and maintain back
            %compatibility.
            
            if isempty(cTimelapse.timepointsToProcess)
                
                cTimelapse.timepointsToProcess = 1:length(cTimelapse.cTimepoint);
                
            end
            
            if length(cTimelapse.BackgroundCorrection)==1 && isempty(cTimelapse.BackgroundCorrection{1})
                cTimelapse.BackgroundCorrection = {};
                cTimelapse.BackgroundCorrection(1:length(cTimelapse.channelNames)) = {[]};
            end
            
            if length(cTimelapse.ErrorModel)==1 && isempty(cTimelapse.ErrorModel{1})
                cTimelapse.ErrorModel = {};
                cTimelapse.ErrorModel(1:length(cTimelapse.channelNames)) = {[]};
            end
            
            if size(cTimelapse.offset,1)<length(cTimelapse.channelNames)
                cTimelapse.offset(end+1:length(cTimelapse.channelNames),:) = 0;
            end
            
            
            if isprop(LoadStructure,'ActiveContourObject') && ~isempty(LoadStructure.ActiveContourObject)
                cTimelapse.ACParams = LoadStructure.ActiveContourObject.Parameters;
                cTimelapse.ActiveContourObject = [];
            end
            
            if isempty(cTimelapse.channelForTrapDetection)
                cTimelapse.channelForTrapDetection = 1;
            end
            
            if isempty(cTimelapse.scaledImSize)
                cTimelapse.scaledImSize = cTimelapse.imSize;
            end

        end
        
        function cTimelapse_save = saveobj(cTimelapse_in)
            
            cTimelapse_save = cTimelapse_in.copy;
            
        end
        
        function DefaultParameters = LoadDefaultACParams
            % LoadDefaultParameters
            % Load the default parameters for the active contour method,
            % which are saved in default_active_contour_parameters.mat
            % inside the timelapseTraps folder.
            DefaultParameterMatFileLocation = mfilename('fullpath');
            FileSepLocation = regexp(DefaultParameterMatFileLocation,filesep);
            DefaultParameterMatFileLocation = fullfile(DefaultParameterMatFileLocation(1:FileSepLocation(end)),'default_active_contour_parameters.mat');
            if exist(DefaultParameterMatFileLocation,'file')
                load(DefaultParameterMatFileLocation,'Parameters');
            else
                % make the 'core parameters' provided with the software the
                % default.
                CoreParameterLocation = fullfile(DefaultParameterMatFileLocation(1:FileSepLocation(end)),'core_default_active_contour_parameters.mat');
                load(CoreParameterLocation,'Parameters');
                timelapseTraps.SaveDefaultACParams(Parameters)
            end
            DefaultParameters = Parameters;
        end
        
        function SaveDefaultACParams(Parameters)
            % SaveDefaultParameters
            % save provided structure as the default parameters for the active contour method,
            % which are saved in default_active_contour_parameters.mat
            % inside the timelapseTraps folder.
            % if this was a mistake, can always replace them with
            % parameters from:
            % core_default_active_contour_parameters.mat
            DefaultParameterMatFileLocation = mfilename('fullpath');
            FileSepLocation = regexp(DefaultParameterMatFileLocation,filesep);
            DefaultParameterMatFileLocation = fullfile(DefaultParameterMatFileLocation(1:FileSepLocation(end)),'default_active_contour_parameters.mat');
            save(DefaultParameterMatFileLocation,'Parameters');
        end
    end
end

