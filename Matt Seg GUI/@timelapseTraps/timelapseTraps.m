classdef timelapseTraps<handle
%%TimelapseTraps: Functions and analysis used by the timelapseTraspsGUI object
%-------------------------------------------------------
%   SYNOPSIS:   


    properties
        fileSoure = 'swain-batman' %a string informing the software where the files came from. Informs the addSecondaryChannel method.
        timelapseDir %set to 'ignore' to use absolute file names
        cTimepoint
%         cTrapsLabelled
        cTrapSize
        image_rotation % to ensure that it lines up with the cCellVision Model
        imScale %used to scale down images if needed
        magnification=60;
        trapsPresent
        pixelSize
        cellsToPlot %row = trap num, col is cell tracking number
        timepointsProcessed
        timepointsToProcess %list of timepoints that should be processed (i.e. checked for cells and what not)
        extractedData
        channelNames
        imSize
        channelsForSegment = 1; %index of the channels to use in the centre finding segmentation .default to 1 (normally DIC)
        
        lineageInfo
        %stuff Elco has added
        offset = [0 0] %a n x 2 offset of each channel compared to DIC. So [0 0; x1 y1; x2 y2]. Positive shifts left/down.
        BackgroundCorrection = {[]}; %correction matrix for image channels. If non empty, returnSingleTimepoint will '.multiply' the image by this matrix.
        ActiveContourObject %an object of the TimelapseTrapsActiveContour class associated with this timelapse.
        %stuff Ivan has added
        omeroDs%The id number of the omero dataset from which the raw data was donwloaded. If the object was created from a folder of images this is zero.
    end
    
    methods
        

        function cTimelapse=timelapseTraps(folder,varargin)
            %% Read filenames from folder or Omero
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
                cTimelapse.timelapseDir=folder;
                cTimelapse.cellsToPlot=sparse(100,1e3);
            end
        end
            
        %functions for loading data and then processing to identify and
        %track the traps
        loadTimelapse(cTimelapse,searchString,pixelSize,image_rotation,trapsPresent,timepointsToLoad);
        loadTimelapseScot(cTimelapse,timelapseObj);
        
        %[trapLocations trap_mask trapImages]=identifyTrapLocationsSingleTP(cTimelapse,timepoint,cCellVision,trapLocations,trapImagesPrevTp)
        trackTrapsThroughTime(cTimelapse,cCellVision,timepoints);
        trackCells(cTimelapse,cellMovementThresh);
        [histCellDist bins]=trackCellsHistDist(cTimelapse,cellMovementThresh);
        motherIndex=findMotherIndex(cTimelapse);
        
        %%
        addSecondaryTimelapseChannel(cTimelapse,searchString)
        new=addTimepoints(cTimelapse)
        extractCellData(cTimelapse,type);
        extractCellParamsOnly(cTimelapse)
        automaticSelectCells(cTimelapse,params);
        
        correctSkippedFramesInf(cTimelapse);
        
        %updated processing cell function
        identifyCellCenters(cTimelapse,cCellVision,timepoint,channel, method)
        d_im=identifyCellCentersTrap(cTimelapse,cCellVision,timepoint,trap,trap_image,old_d_im)
        addRemoveCells(cTimelapse,cCellVision,timepoint,trap,selection,pt, method, channel)
        identifyCellObjects(cTimelapse,cCellVision,timepoint,traps,channel, method,bw,trap_image)
        identifyCellBoundaries(cTimelapse,cCellVision,timepoint,traps,channel, method,bw)
        identifyCells(cTimelapse, cCellVision,traps, channel, method)
        
        
        
        
        
        identifyTrapLocations(cTimelapse,cCellVision,display,num_frames)
        %I don't think the below functions work anymore
        %functions to process individual cells within each of the traps
        
%         separateCells(cTimelapse,traps, channel, method)
%         trackCells(cTimelapse,traps, channel, method)
        
        % functions for displaying data
%         displayTimelapse(cTimelapse,channel,pause_duration)
%         displaySingleTrapTimepoint(cTimelapse,trap_num_to_show,timepoint,channel)
%         displaySingleTrapTimelapse(cTimelapse,trap_num_to_show,channel,pause_duration)
%         displayTrapsTimelapse(cTimelapse,traps,channel,pause_duration)
        
        % functions for saving the timelapse
        savecTimelapse(cTimelapse)
        savecTimelapseVision(cTimelapse,cCellVision)
        loadcTimelapse(cTimelapse)
        setMagnification(cTimelapse,cCellVision);
        
        % functions for returning data
        trapTimepoint=returnSingleTrapTimepoint(cTimelapse,trap_num_to_show,timepoint,channel)
        trapTimelapse=returnSingleTrapTimelapse(cTimelapse,trap_num_to_show,channel)
        timepoint=returnSingleTimepoint(cTimelapse,timepoint,channel,type)
        trapTimepoint=returnTrapsTimepoint(cTimelapse,traps,timepoint,channel,type)
        trapsTimelapse=returnTrapsTimelapse(cTimelapse,traps,channel)

        timelapse=returnTimelapse(cTimelapse,channel)
    
        function cTimelapseOUT = copy(cTimelapseIN)
            
            cTimelapseOUT = timelapseTraps([],true);
            
            FieldNames = fields(cTimelapseIN);
            
            for i = 1:numel(FieldNames)
                
                cTimelapseOUT.(FieldNames{i}) = cTimelapseIN.(FieldNames{i});
                
            end
            
        end
    end
    
    
    methods (Static)
        function cTimelapse = loadobj(LoadStructure)
            
            %% default loading method: DO NOT CHANGE
            cTimelapse = timelapseTraps([],true);
            
            FieldNames = fieldnames(LoadStructure);
            
            for i = 1:numel(FieldNames)
                
                cTimelapse.(FieldNames{i}) = LoadStructure.(FieldNames{i});
                
            end
            
            %% back compatibility checks and what not
            
            if isempty(cTimelapse.timepointsToProcess)
                
                cTimelapse.timepointsToProcess = 1:length(cTimelapse.cTimepoint);
                
            end
        end
    end
end

