classdef timelapseTraps<handle
    
    properties
        timelapseDir
        cTimepoint
        cTrapsLabelled
        cTrapSize
        image_rotation
        magnification
        trapsPresent
        pixelSize
        cellsToPlot
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
        identifyTrapLocations(cTimelapse,cCellVision,display,num_frames)
        [trapLocations trap_mask]=identifyTrapLocationsSingleTP(cTimelapse,timepoint,cTrap,trapLocations)
        trackTrapsThroughTime(cTimelapse);
        trackCells(cTimelapse,cellMovementThresh);
        
        %%
        addSecondaryTimelapseChannel(cTimelapse,searchString)
        
        %updated processing cell function
        identifyCellCenters(cTimelapse,cCellVision,timepoint,channel, method)
        d_im=identifyCellCentersTrap(cTimelapse,cCellVision,timepoint,trap,channel, method,trap_image,old_d_im)
        addRemoveCells(cTimelapse,cCellVision,timepoint,trap,selection,pt, method, channel)
        identifyCellObjects(cTimelapse,cCellVision,timepoint,traps,channel, method,bw,trap_image)
        identifyCellBoundaries(cTimelapse,cCellVision,timepoint,traps,channel, method,bw)
        
        %functions to process individual cells within each of the traps
        identifyCells(cTimelapse, cCellVision,traps, channel, method)
        separateCells(cTimelapse,traps, channel, method)
%         trackCells(cTimelapse,traps, channel, method)
        
        % functions for displaying data
        displayTimelapse(cTimelapse,channel,pause_duration)
        displaySingleTrapTimepoint(cTimelapse,trap_num_to_show,timepoint,channel)
        displaySingleTrapTimelapse(cTimelapse,trap_num_to_show,channel,pause_duration)
        displayTrapsTimelapse(cTimelapse,traps,channel,pause_duration)
        
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

