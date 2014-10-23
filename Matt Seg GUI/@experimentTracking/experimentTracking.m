classdef experimentTracking<handle
    
    properties
        rootFolder %folder where images are
        saveFolder %folder to save the timelapse objects
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
        timepointsToProcess
        trackTrapsOverwrite
        cellVisionThresh
        imScale
        
        lineageInfo %for all of the cell births and stuff that occure during the timelapse
        
        cCellVision;
        ActiveContourParameters
    end
    
    methods
        
        function cExperiment=experimentTracking(folder)
            %% Read filenames from folder
            if nargin<1
                fprintf('\n   Select the Root of a single experimental set containing folders of multiple positions \n');
                folder=uigetdir(pwd,'Select the Root of a single experimental set containing folders of multiple positions');
                fprintf('\n   Select the folder where data should be saved \n');
                saveFolder=uigetdir(folder,'Select the folder where data should be saved');
            end
            
            cExperiment.rootFolder=folder;
            cExperiment.saveFolder=saveFolder;
            cExperiment.posSegmented=0;
            cExperiment.posTracked=0;
            tempdir=dir(cExperiment.rootFolder);
            cExperiment.dirs=cell(1);
            index=1;
            for i=1:length(tempdir)
                if tempdir(i).isdir
                    if ~strcmp(tempdir(i).name(1),'.')
                        cExperiment.dirs{index}=tempdir(i).name;
                        index=index+1;
                    end
                    
                end
            end
            cExperiment.cellsToPlot=cell(1);
            cExperiment.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
        end
            
        %functions for loading data and then processing to identify and
        %track the traps
        createTimelapsePositions(cExperiment,searchString,positionsToLoad,magnification,image_rotation,trapsPresent,timepointsToLoad);
        identifyTrapsTimelapses(cExperiment,cCellVision,positionsToIdentify);
        segmentCellsDisplay(cExperiment,cCellVision,positionsToSegment);
        visualizeSegmentedCells(cExperiment,cCellVision,positionsToShow);
        trackCells(cExperiment,positionsToTrack,cellMovementThresh)       
        selectTPToProcess(cExperiment,positions);
        combineTracklets(cExperiment,positions);
        
        selectCellsToPlot(cExperiment,cCellVision,position);
        selectCellsToPlotAutomatic(cExperiment,positionsToCheck,params);
        
        correctSkippedFramesInf(cExperiment,type);
        
        extractCellInformation(cExperiment,positionsToExtract,type);
        compileCellInformation(cExperiment,positions);
        compileCellInformationParamsOnly(cExperiment,positions);
        
        cTimelapse=returnTimelapse(cExperiment,timelapseNum);
        saveTimelapseExperiment(cExperiment,currentPos);
        saveExperiment(cExperiment);
        plotCellInformation(cExperiment,position);
    end
end

