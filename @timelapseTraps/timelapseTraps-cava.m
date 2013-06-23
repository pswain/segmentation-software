classdef timelapseTraps<handle
    
    properties
        timelapseDir
        cTimepoint
        cTrapsLabelled
        cTrapSize
        image_rotation
        magnification
    end
    
    methods
        
        function cTimelapse=timelapseTraps(folder)
            %% Read filenames from folder
            if nargin<1
                folder=uigetdir(pwd,'Select the root of a timelapse experiment with multiple positions');
            end
            cTimelapse.timelapseDir=folder;
        end
            
        %functions for loading data and then processing to identify and
        %track the traps
        loadTimelapse(cTimelapse,searchString,image_rotation);
        identifyTrapLocations(cTimelapse,cCellVision,display,num_frames)
        trackTrapsThroughTime(cTimelapse);
        
        
        %%
        addSecondaryTimelapseChannel(cTimelapse,searchString)
        
        %functions to process individual cells within each of the traps
        identifyCells(cTimelapse, cCellVision,traps, channel, method)
        identifyCellObjects(cTimelapse,cCellVision,traps,channel,method);
        separateCells(cTimelapse,traps, channel, method)
        trackCells(cTimelapse,traps, channel, method)
        
        % functions for displaying data
        displayTimelapse(cTimelapse,channel,pause_duration)
        displaySingleTrapTimepoint(cTimelapse,trap_num_to_show,timepoint,channel)
        displaySingleTrapTimelapse(cTimelapse,trap_num_to_show,channel,pause_duration)
        displayTrapsTimelapse(cTimelapse,traps,channel,pause_duration)
        
        % functions for saving the timelapse
        savecTimelapse(cTimelapse)
        savecTimelapseVision(cTimelapse,cCellVision)
        loadcTimelapse(cTimelapse)
        
        % functions for returning data
        trapTimepoint=returnSingleTrapTimepoint(cTimelapse,trap_num_to_show,timepoint,channel)
        trapTimelapse=returnSingleTrapTimelapse(cTimelapse,trap_num_to_show,channel)
        timepoint=returnSingleTimepoint(cTimelapse,timepoint,channel)
        trapTimepoint=returnTrapsTimepoint(cTimelapse,traps,timepoint,channel)
        trapsTimelapse=returnTrapsTimelapse(cTimelapse,traps,channel)

        timelapse=returnTimelapse(cTimelapse,channel)

    end
end

