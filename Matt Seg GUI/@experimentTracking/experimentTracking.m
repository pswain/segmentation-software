classdef experimentTracking<handle
    
    properties
        rootFolder %folder where images are. When images are held in an Omero database this property is the suffix defining the filename: cExperiment_SUFFIX.mat
        omeroDs%Omero dataset object - alternative source to rootFolder
        OmeroDatabase%Omero database object
        creator%string, the user who created this object(obtained by getenv('USERNAME'))
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
        
        function cExperiment=experimentTracking(folder, OmeroDatabase,  expName)
            %% Folder input is a string with the full path to the root folder or an Omero dataset object (in that case the OmeroDatabase object must also be input)
            %Optional inputs 2-4 only used when creating objects using the
            %Omero database: OmeroDatabase - object of class OmeroDatabase
            %expName, a unique name for this cExperiment
            
            % Read filenames from folder
            if nargin<1
                fprintf('\n   Select the Root of a single experimental set containing folders of multiple positions \n');
                folder=uigetdir(pwd,'Select the Root of a single experimental set containing folders of multiple positions');
                fprintf('\n   Select the folder where data should be saved \n');
                saveFolder=uigetdir(folder,'Select the folder where data should be saved');
            end
            
            if ischar(folder)
                cExperiment.rootFolder=folder;
                cExperiment.saveFolder=saveFolder;
            else
                if nargin>2
                    if iscell(expName)
                        expName=expName{:};
                    end
                    cExperiment.rootFolder=expName;
                else
                    cExperiment.rootFolder='001';%default experiment name
                end
                if ismac
                    cExperiment.saveFolder=['/Users/' char(java.lang.System.getProperty('user.name')) '/Documents/OmeroTemp'];
                    
                else
                    cExperiment.saveFolder=['C:\Users\' getenv('USERNAME') '\OmeroTemp'];
                end
                if ~exist(cExperiment.saveFolder,'dir')
                    
                    
                    
                    
                    mkdir(cExperiment.saveFolder);
                end
                delete([cExperiment.saveFolder '/*']);
                cExperiment.omeroDs=folder;
                cExperiment.OmeroDatabase=OmeroDatabase;
            end
            cExperiment.creator=getenv('USERNAME');
            cExperiment.posSegmented=0;
            cExperiment.posTracked=0;
            if isempty(cExperiment.OmeroDatabase)
                tempdir=dir(cExperiment.rootFolder);
            else
                tempdir=[];
            end
            cExperiment.dirs=cell(1);
            if isempty(cExperiment.OmeroDatabase)
                index=1;
                for i=1:length(tempdir)
                    if tempdir(i).isdir
                        if ~strcmp(tempdir(i).name(1),'.')
                            cExperiment.dirs{index}=tempdir(i).name;
                            index=index+1;
                        end

                    end
                end
            else
                %Position list consists of the Omero image names
                oImages=cExperiment.omeroDs.linkedImageList;
                for i=1:oImages.size
                    cExperiment.dirs{i}=char(oImages.get(i-1).getName.getValue);
                end
                cExperiment.dirs=sort(cExperiment.dirs);
            end
            cExperiment.cellsToPlot=cell(1);
            cExperiment.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
            
        end
            
        %functions for loading data and then processing to identify and
        %track the traps
        createTimelapsePositions(cExperiment,searchString,positionsToLoad,magnification,image_rotation,trapsPresent,timepointsToLoad);
        identifyTrapsTimelapses(cExperiment,cCellVision,positionsToIdentify,TrackFirstTimepoint,ClearTrapInfo);
        segmentCellsDisplay(cExperiment,cCellVision,positionsToSegment);
        visualizeSegmentedCells(cExperiment,cCellVision,positionsToShow);
        trackCells(cExperiment,positionsToTrack,cellMovementThresh)       
        selectTPToProcess(cExperiment,positions);
        combineTracklets(cExperiment,positions,params);
        
        selectCellsToPlot(cExperiment,cCellVision,position,channel);
        selectCellsToPlotAutomatic(cExperiment,positionsToCheck,params);
        
        correctSkippedFramesInf(cExperiment,type);
        
        extractCellInformation(cExperiment,positionsToExtract,type,channels,cellSegType);
        compileCellInformation(cExperiment,positions);
        compileCellInformationParamsOnly(cExperiment,positions);
        
        cTimelapse=returnTimelapse(cExperiment,timelapseNum);
        saveTimelapseExperiment(cExperiment,currentPos,saveCE);
        saveExperiment(cExperiment,fileName);
        plotCellInformation(cExperiment,position);
    end
end

