classdef timelapseTraps<handle
    
    properties
        timelapseDir
        cTimepoint
%         cTrapsLabelled
        cTrapSize
        image_rotation % to ensure that it lines up with the cCellVision Model
        magnification=60;
        trapsPresent
        pixelSize
        cellsToPlot %row = trap num, col is cell tracking number
        timepointsProcessed
        extractedData
        channelNames
        imSize
        
        lineageInfo
        %stuff Elco has added
        offset = [0 0] %a n x 2 offset of each channel compared to DIC. So [0 0; x1 y1; x2 y2]. Positive shifts left/down.
        BackgroundCorrection = {[]}; %correction matrix for image channels. If non empty, returnSingleTimepoint will '.multiply' the image by this matrix.
    end
    
    methods
        
        function cTimelapse=timelapseTraps(folder)
            %% Read filenames from folder
            if nargin<1
                folder=uigetdir(pwd,'Select the root of a timelapse experiment with multiple positions');
            end
            cTimelapse.timelapseDir=folder;
            cTimelapse.cellsToPlot=sparse(100,2e3);
        end
            
        %functions for loading data and then processing to identify and
        %track the traps
        loadTimelapse(cTimelapse,searchString,pixelSize,image_rotation,timepointsToLoad);
        loadTimelapseScot(cTimelapse,timelapseObj);
        
        [trapLocations trap_mask trapImages]=identifyTrapLocationsSingleTP(cTimelapse,timepoint,cCellVision,trapLocations,trapImagesPrevTp)
        trackTrapsThroughTime(cTimelapse,cCellVision,timepoints);
        trackCells(cTimelapse,cellMovementThresh);
        [histCellDist bins]=trackCellsHistDist(cTimelapse,cellMovementThresh);
        motherIndex=findMotherIndex(cTimelapse);
        
        %%
        addSecondaryTimelapseChannel(cTimelapse,searchString)
        new=addTimepoints(cTimelapse)
        extractCellData(cTimelapse);
        extractCellParamsOnly(cTimelapse)
        automaticSelectCells(cTimelapse,params);
        
        correctSkippedFramesInf(cTimelapse);
        
        %updated processing cell function
        identifyCellCenters(cTimelapse,cCellVision,timepoint,channel, method)
        d_im=identifyCellCentersTrap(cTimelapse,cCellVision,timepoint,trap,channel, method,trap_image,old_d_im)
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
        timepoint=returnSingleTimepoint(cTimelapse,timepoint,channel)
        trapTimepoint=returnTrapsTimepoint(cTimelapse,traps,timepoint,channel)
        trapsTimelapse=returnTrapsTimelapse(cTimelapse,traps,channel)

        timelapse=returnTimelapse(cTimelapse,channel)

    end
end

