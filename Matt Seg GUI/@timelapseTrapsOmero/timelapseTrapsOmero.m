classdef timelapseTrapsOmero<timelapseTraps
    % TIMELAPSETRAPSOMERO A subclass of timelapseTraps to process images
    % coming from Omero Database via Ivan's OmeroCode.
    % See also EXPERIMENTTRACKINGOMERO, TIMELAPSETRAPS
    
    properties
        microscopeChannels%cell array of channel names as defined by the microscope software.
        
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
            
            if nargin>=2 && islogical(varargin{1})
                NoAction = varargin{1};
            else
                NoAction = false;
            end
            if ~NoAction
                
                cTimelapseOmero.omeroImage=omeroImage;
                cTimelapseOmero.OmeroDatabase=varargin{1};
                cTimelapseOmero.channelNames=varargin{1}.Channels;
                cTimelapseOmero.microscopeChannels=varargin{1}.MicroscopeChannels;
                
                cTimelapseOmero.cellsToPlot=sparse(100,1e3);
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
