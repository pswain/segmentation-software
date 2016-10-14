classdef LinkedData < handle
    %LinkedData Manage setting and retrieval of linked data sets
    %   This class is designed to be integrated within other objects (for
    %   example a cExperiment object)
    
    properties (Dependent)
        metaInfo % Used to access or set a linked MetaInfo object (from the AnalysisToolbox)
        imageCaches % Used to access or set linked ImageCache objects (from the SegmentationToolbox)
        segCaches % Used to access or set linked SegmentationCache objects (from the SegmentationToolbox)
        cellResults % Used to access or set linked cellResults objects (from the AnalysisToolbox)
        baseDataDir % Set or get the current base directory where linked data is stored
    end
    
    events
        LinksUpdated % Event triggered when links are modified; used to notify parent objects to re-save
    end
    
    properties (Access=private)
        baseDir = ''
        metaInfoFile = []
        imCacheFiles = []
        segImageFiles = []
        cellResultsFiles = []
        groupnames = {}
    end
    
    properties(Constant,Access=private)
        linksgrouped = struct(...
            'metaInfoFile',false,...
            'imCacheFile',true,...
            'segImageFile',true,...
            'cellResultsFile',true)
    end
    
    properties (Transient,Access=private)
        % Handles to loaded objects are cached in the following properties:
        cExperiment = []
        metaInfoObj = []
        imCacheObj = []
        segImageObj = []
        cellResultsObj = []
    end
    
    properties (Constant)
        % Error message types that get raised by this class
        errBadParams = 'MattSegGUI:LinkedData:badParams';
        errMissingClass = 'MattSegGUI:LinkedData:missingClass';
        errMissingFile = 'MattSegGUI:LinkedData:missingFile';
        errCorruptData = 'MattSegGUI:LinkedData:corruptData';
        errUserCancel = 'MattSegGUI:LinkedData:userCancel';
    end
    
    methods
        function this = LinkedData(cExperiment)
            if nargin<1 || isempty(cExperiment)
                cExperiment = [];
            end
            this.cExperiment = cExperiment;
        end
        
        function baseDataDir.set(this,value)
            %LinkedData.baseDataDir.set Change the data directory
            
            % Check the parameters:
            if ~ischar(value)
                error(LinkedData.errBadParams,...
                    'The base data directory must be specified as a string');
            end
            
            % Check that the new directory exists:
            if ~isdir(value)
                error(LinkedData.errMissingFile,...
                    'The specified base data directory does not exist');
            end
            
            this.baseDir = value;
        end
        
        function value = metaInfo.get(this)
            %LinkedData.metaInfo.get Get MetaInfo object
            %   Get a handle to a linked MetaInfo object, or create a new
            %   one if it doesn't yet exist
            
            % If a cached object hasn't been loaded, attempt to load one
            if isempty(this.metaInfoObj)
                % First check that the MetaInfo class exists:
                if ~exist('MetaInfo','class')
                    error(LinkedData.errMissingClass,...
                        'Install the AnalysisToolbox to access meta information.');
                end
                
                % Check if a linked meta info file has already been saved:
                if ~isempty(this.metaInfoFile)
                    try
                        this.metaInfoObj = ...
                            LinkedData.loadObject(this.baseDir,this.metaInfoFile,'MetaInfo');
                    catch err
                        if any(strcmp({LinkedData.errMissingFile,...
                                LinkedData.errCorruptData},err.identifier))
                            % If the file doesn't exist, ask the user 
                            % whether they want to specify an alternative
                            % base directory or file location:
                            try
                                this.metaInfoFile = this.uiUpdateDir(this.metaInfoFile);
                            catch uiErr
                                if strcmp
                                end
                            end
                        end
                    end
                else
                    
                end
            end
            
            % Once loaded, a cached handle to the MetaInfo object is now 
            % stored in this.metaInfoObj:
            value = this.metaInfoObj;
        end
        
        function metaInfo.set(this,value)
        end
    end
    
    methods (Access=private)
        function obj = loadObject(this,filevar,otype)
            %loadObject Safely load a linked object
            %   NB: this function assumes that 'filename' is not an empty
            %   string.
            
            % The error message becomes non-empty if loading the object 
            % fails the first time:
            errmsg = '';
            errid = LinkedData.errUserCancel; % Default error ID
            updated = false;
            
            % Run an infinite loop until the correct file has been found or
            % the user cancels:
            while true
                % If we are repeating due to an error, prompt the user:
                if ~isempty(errmsg)
                    title = 'Update Linked Data';
                    msg = [errmsg,' Would you like to:'];
                    answers = {'Update Data Directory','Update File','Cancel'};
                    answer = questdlg(msg,title,answers{1},answers{2},answers{3},answers{1});
                    switch answer
                        case answers{1}
                            % Update the base directory
                            newdir = uigetdir('',answers{1});
                            if newdir==0
                                % User cancelled so raise as error
                                error(errid,errmsg);
                            else
                                % If there is no error, then directory is
                                % guaranteed to exist:
                                this.baseDir = newdir;
                                updated = true;
                            end
                        case answers{2}
                            % Update the filename
                            [newfile,newpath] = uigetfile('*.mat',answers{2});
                            if newfile==0
                                % User cancelled so raise as error
                                error(errid,errmsg);
                            else
                                % If there is no error, then file is
                                % guaranteed to exist:
                                this.(filevar) = newfile;
                                updated = true;
                            end
                        otherwise
                            % User cancelled so raise as error
                            error(errid,errmsg);
                    end
                end
                
                fn = fullfile(this.baseDir,this.(filevar));
                
                if ~exist(fn,'file')
                    % The file doesn't exist: set errmsg and try again
                    errid = LinkedData.errMissingFile;
                    errmsg = sprintf(...
                        'The linked file "%s" could not be found.',fn);
                    continue
                end
                
                loaded_struct = load(fn,'-mat');
                vars = fieldnames(loaded_struct);
                % Take only the first loaded variable in the .mat file
                obj = loaded_struct.(vars(1));
                
                if isa(obj,otype)
                    % We have loaded the object correctly, so break from
                    % the current while loop:
                    break
                else
                    % The loaded object is of the wrong class: set errmsg
                    % and try again
                    errid = LinkedData.errCorruptData;
                    errmsg = sprintf(...
                        'The linked data in "%s" is not of class "%s"',fn,otype);
                    continue
                end
            end
            if updated
                % If updates to the class have occurred, trigger the
                % LinksUpdated event:
                notify(this,'LinksUpdated');
            end
        end
    end
end