classdef experimentTracking<handle
    
    properties
        rootFolder
        dirs
        posSegmented
        posTracked
        cellsToPlot
        currentDir
        searchString;
        pixelSize
        magnification
        trapsPresent;
        image_rotation;
        cTimelapse;
        cellInf
        experimentInformation
        timepointsToLoad
    end
    
    methods
        
        function cExperiment=experimentTracking(folder)
            %% Read filenames from folder
            if nargin<1
                folder=uigetdir(pwd,'Select the Root of a single experimental set containing folders of multiple positions');
            end
            
            cExperiment.rootFolder=folder;
            cExperiment.posSegmented=0;
            cExperiment.posTracked=0;
            tempdir=dir(cExperiment.rootFolder);
            cExperiment.dirs=cell(1);
            index=1;
            for i=1:length(tempdir)
                if tempdir(i).isdir
                    if index>2
                        cExperiment.dirs{index-2}=tempdir(i).name;
                    end
                    index=index+1;
                end
            end
            cExperiment.cellsToPlot=zeros(length(cExperiment.dirs),50,500)>0;
        end
            
        %functions for loading data and then processing to identify and
        %track the traps
        createTimelapsePositions(cExperiment,searchString,positionsToLoad,magnification,image_rotation,trapsPresent,timepointsToLoad);
        identifyTrapsTimelapses(cExperiment,cCellVision,positionsToIdentify);
        segmentCellsDisplay(cExperiment,cCellVision,positionsToSegment);
        visualizeSegmentedCells(cExperiment,cCellVision,positionsToShow);
        trackCells(cExperiment,positionsToTrack,cellMovementThresh)       
        
        selectCellsToPlot(cExperiment,cCellVision,position);
        selectCellsToPlotAutomatic(cExperiment,positionsToCheck,params);
        
        correctSkippedFramesInf(cExperiment);
        
        extractCellInformation(cExperiment,positionsToExtract);
        compileCellInformation(cExperiment,positions);
        
        cTimelapse=returnTimelapse(cExperiment,timelapseNum);
        saveTimelapseExperiment(cExperiment,currentPos);
        saveExperiment(cExperiment);
        plotCellInformation(cExperiment,position);
    end
end

