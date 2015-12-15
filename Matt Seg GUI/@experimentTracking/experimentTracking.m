classdef experimentTracking<handle
    %class for organising and numerous timelapseTraps objects, one for each
    %position in the experiment. Mostly used to apply identical processing
    %steps to each position, organise loading and saving of them, and
    %compile the data from all the separate positions in one location.
    %Indiviual timelapseTraps objects are created either from local files
    %or from the omero database.
    
    properties
        rootFolder %folder where images are. When images are held in an Omero database this property is the suffix defining the filename: cExperiment_SUFFIX.mat
        omeroDs%Omero dataset object - alternative source to rootFolder
        OmeroDatabase%Omero database object
        creator%string, the user who created this object(obtained by getenv('USERNAME'))
        saveFolder %folder to save the timelapse objects
        dirs % cell array of directories in rootFolder. 
        posSegmented % logical array of position already segmented.
        posTracked %logical of positions tracked
        cellsToPlot % Doesn't actually seem to be used anywhere
        %currentDir 
        %the following all match their equivalents in timelapseTraps and
        %are popualted and used to populate the timelapseTrap fields when calling
        %loadTimelapse
        searchString; 
        pixelSize
        magnification
        trapsPresent;
        image_rotation;
        timepointsToLoad
        timepointsToProcess
        trackTrapsOverwrite
        imScale
        
        cTimelapse; %populated when loadCurrentTimelapse is used, and the cTimelapse saved when saveCurrentTimelapse is called.
        cellInf % cell data compuled from extractedData in each of the individual timelapseTrap objects
        experimentInformation %currently not really used
        cellVisionThresh % used to overwrite the twoStageThresh of cellVision in 
                         %      experimentTrackingGUI.identifyCells
                         %importantly, not used in the experimentTracking
                         %method:
                         %  segmentCellDisplay.
        
        lineageInfo %for all of the cell births and stuff that occure during the timelapse
        
        cCellVision; % cellvision model applied throughout the segmentation, 
                     % particularly in segmentCellDisplay and
                     % identifyTrapsTimelapses.
        ActiveContourParameters % parameters used in the ActiveContour 
                                % methods, copied to each timelapseTraps
                                % object when this is run (if parameters
                                % selected appropriately)
        
    end
    
    methods
        
        function cExperiment=experimentTracking(folder,saveFolder, OmeroDatabase,  expName)
            %% Folder input is a string with the full path to the root folder or an Omero dataset object (in that case the OmeroDatabase object must also be input)
            %Optional inputs 2-4 only used when creating objects using the
            %Omero database: OmeroDatabase - object of class OmeroDatabase
            %expName, a unique name for this cExperiment
            
            % Read filenames from folder
            if nargin<1
                fprintf('\n   Select the Root of a single experimental set containing folders of multiple positions \n');
                folder=uigetdir(pwd,'Select the Root of a single experimental set containing folders of multiple positions');
            end
            if nargin<2
                fprintf('\n   Select the folder where data should be saved \n');
                saveFolder=uigetdir(folder,'Select the folder where data should be saved');
            end
            
            if ischar(folder)
                cExperiment.rootFolder=folder;
                cExperiment.saveFolder=saveFolder;
            else
                if nargin>3
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
            
        
    end
end

