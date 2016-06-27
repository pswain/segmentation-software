classdef timelapseTraps<handle
    % class used to do the processing of the images for a particular
    % positions. Each timepoint is stored as an entry in the cTimepoint
    % structure array. This contains:
    %
    %filename:      cell array of the names of the files associated with that timepoint
    %
    %after processing it also stores:
    %
    %trapLocations: the location of the traps.
    %trapInfo:      a structure that holds all the information about the
    %               location, label and outline of each cell in each trap
    %trapMaxCell :  the maximum cell label for the cells in that trap
    
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
        trapImSize % uses the cTrapSize property to give the size of the image.
        image_rotation % to ensure that it lines up with the cCellVision Model
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
        pixelSize % the real size of pixels in the image (again, exercise caution in changing this)
        cellsToPlot %Array indicating which cells to extract data for. row = trap num, col is cell tracking number
        timepointsProcessed %a logical array of timepoints which have been processed
        timepointsToProcess %list of timepoints that should be processed (i.e. checked for cells and what not)
        extractedData %a structure array of sparse arrays of extracted statistics for the cell. One entry for each channel extracted, one row in the array for each cell with zeros where the cell is absent.
        channelNames % cell array of channel names. Used in selecting the file(s) to load when a particular channel is selected in returnImage method
        microscopeChannels%cell array of channel names as defined by the microscope software.
        imSize %the size of the images before rotation (i.e. raw images).
        channelsForSegment = 1; %index of the channels to use in the centre finding segmentation .default to 1 (normally DIC)
        lineageInfo %structure array to hld everything associated with daughter counting (namely, the birth times, mother labels, daughter labels etc.)
        %stuff Elco has added
        offset = [0 0] %a n x 2 offset of each channel compared to DIC. So [0 0; x1 y1; x2 y2]. Positive shifts left/up.
        BackgroundCorrection = {[]}; %correction matrix for image channels. If non empty, returnSingleTimepoint will '.multiply' the image by this matrix.
        ErrorModel = {[]}; % an object of the error model class that returns an error based on pixel intensity to give a shot noise estimate for the cell.
        extractionParameters = timelapseTraps.defaultExtractParameters;
        %parameters for the extraction of cell Data, a function handle and
        %a parameter structure which the function makes use of.
        ACParams = []; % active contour parameters.
        
        cellInfoTemplate % template for the cellInfo structure.
        trapInfoTemplate % template for the trapInfo structure
        cTimepointTemplate % template for the cTimepoint structure.
        
        temporaryImageStorage=struct('channel',-1,'images',[]); %this is to store the loaded images from a single channel (ie BF) into memory
        %This allows the cell tracking and curating things to happen a
        %whole lot faster and easier. This way you can just modify the
        %returnTimepoint file to check to see if something is loaded.
        % - channel
        % - images
        
        %stuff Ivan has added
        omeroImage%The (unloaded - no data) omero image object in which the raw data is stored (or empty if the object is created from a folder of images).
        OmeroDatabase%OmeroDatabase object representing the database that the omeroImage comes from.
        
    end
    
    properties(SetAccess = immutable)
        
    end
    
    properties(Constant)
    defaultExtractParameters = struct('extractFunction',@extractCellDataStandardParfor,...
        'functionParameters',struct('type','max','channels','all','nuclearMarkerChannel',NaN,'maxPixOverlap',5,'maxAllowedOverlap',25));
    
    end
    
    properties (Transient)
        % Transient properties won't be saved
        logger; % *optional* handle to an experimentLogging object to keep a log
    end
    
    events
        LogMsg
        TimepointChanged
    end
    
    methods
        

        function cTimelapse=timelapseTraps(folder,varargin)
            % Read filenames from folder or Omero
            % varargin{1} is a logical that will make the constructor run
            % nothing if it is true. this was done to be able to write nice
            % load functions.
            if size(varargin,2)>=1 && islogical(varargin{1})
                NoAction = varargin{1};
            else
                NoAction = false;
            end
            if ~NoAction
                if nargin<1 || isempty(folder)
                    folder=uigetdir(pwd,'Select the folder containing the images associated with this timelapse');
                    fprintf('\n    Select the folder containing the images associated with this timelapse\n');
                end
                if ischar(folder)
                    cTimelapse.timelapseDir=folder;
                else
                    cTimelapse.omeroImage=folder;
                    cTimelapse.OmeroDatabase=varargin{1};
                    cTimelapse.channelNames=varargin{1}.Channels;
                    cTimelapse.microscopeChannels=varargin{1}.MicroscopeChannels;
                end
                cTimelapse.cellsToPlot=sparse(100,1e3);
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
                if ~ismember(m.SetAccess,{'immutable','none'})
                    cTimelapseOUT.(FieldNames{i}) = cTimelapseIN.(FieldNames{i});
                end
            end
            
            if ~isempty(cTimelapseIN.ActiveContourObject)
                cTimelapseIN.ActiveContourObject.TimelapseTraps = [];
                cTimelapseOUT.ActiveContourObject = cTimelapseIN.ActiveContourObject.copy;
                cTimelapseIN.ActiveContourObject.TimelapseTraps = cTimelapseIN;
                cTimelapseOUT.ActiveContourObject.TimelapseTraps = cTimelapseOUT;
                
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
                if cTimelapse.trapsPresent &&  ~isempty(cTimelapse.cTrapSize)
                    data_template = sparse(false(2*[cTimelapse.cTrapSize.bb_height cTimelapse.cTrapSize.bb_width] + 1));
                elseif   ~cTimelapse.trapsPresent &&  ~isempty(cTimelapse.imSize)
                    data_template = sparse(false(cTimelapse.imSize));
                else
                    data_template = [];
                end
            elseif ~issparse(data_template)
                error('data_template should be a sparse array')
                
            end
            trapInfo_struct = cTimelapse.trapInfoTemplate;
            trapInfo_struct.cell = cTimelapse.cellInfoTemplate;
            trapInfo_struct.segCenters = data_template;
            trapInfo_struct.segmented = data_template;
            trapInfo_struct.trackLabel = data_template;
            trapInfo_struct.cell.segmented = data_template;
            trapInfo_struct.refinedTrapPixelsInner = [];
            trapInfo_struct.refinedTrapPixelsBig = [];
            
        end
        
        function default_trap_indices = defaultTrapIndices(cTimelapse)
            % default_trap_indices = defaultTrapIndices(cTimelapse)
            % return the default trap indices to run anything over.
            default_trap_indices = 1:length(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo);
        end
        
        function trapImSize = get.trapImSize(cTimelapse)
            
            trapImSize = 2*[cTimelapse.cTrapSize.bb_height cTimelapse.cTrapSize.bb_width] + 1;
        end
        
        function cTimelapse = set.trapImSize(cTimelapse,input)
            
            fprintf('\n\n trapImSize cannot be set. change cTrapSize instead\n\n')
        end
        
        function cellInfoTemplate = get.cellInfoTemplate(cTimelapse)
            
             cellInfoTemplate = struct('cellCenter',[],...
                       'cellRadius',[],...
                       'segmented',sparse(false(cTimelapse.trapImSize)),...
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
                            'trapInfo',[],'trapMaxCell',[]); %template for the cTimepoint structure

        end
        
    end
    
    
    methods (Static)
        function cTimelapse = loadobj(LoadStructure)
            
            %% default loading method: DO NOT CHANGE
            cTimelapse = timelapseTraps([],true);
            
            FieldNames = fieldnames(LoadStructure);
            %only populate mutable fields occcuring in both the load object
            %and the cTimelapse object.
            FieldNames = intersect(FieldNames,fieldnames(cTimelapse));
            
            for i = 1:numel(FieldNames)
                
                m = findprop(cTimelapse,FieldNames{i});
                if ~ismember(m.SetAccess,{'immutable','none'})
                    cTimelapse.(FieldNames{i}) = LoadStructure.(FieldNames{i});
                end
                
            end
            
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
                cTimelapse.offset(end+1:length(cTimelapse.channelNames)) = 0;
            end
            
            
            if isfield(LoadStructure,'ActiveContourObject')
                cTimelapse.ACParams = LoadStructure.ActiveContourObject.Parameters;
            end
        end
        
        function cTimelapse_save = saveobj(cTimelapse_in)
            
            cTimelapse_save = cTimelapse_in.copy;
            
        end
    end
end

