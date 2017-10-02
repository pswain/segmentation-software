classdef cellVision<handle
    
    properties
        cTrap
        % complex structure of trap information. Only populated if the timelapse has traps.
          % trapOutline      - filled and dilated image of the traps 
          % contour          - just the edge of the trap
         
        cPatchParameters %used by Matt in Hog feature set
        % various SVM models
        SVMModel
        SVMModelLinear
        SVMModelCellToOuterLinear
        SVMModelInnerToEdgeLinear
        SVMModelGPU
        twoStageThresh % in some old code, the threshold at which a pixel is condidered a centre 
        scaling % set of parameters for scaling features to all lie in a similar range.
        trainingData % structure with the fields features (Nxnum_features array) and class (length N array)
        trainingParams
        negativeSamplesPerImage
        radiusSmall %smallest radius (in pixels) used to identify and track cells
        radiusLarge % largest radius (in pixels) used to identify and track cells
        pixelSize
        training_channels = {'DIC'} %the names of the channels in the ctimepoint object used to train the SVM.
        filterFunction = 'full' %either a string or a function handle indicating which set of filters was used in training the SVM.
        TrainDataGenerationDate = []; %date on which training data was generated (for comaprison to when it the function was edited).
        TrainData = []; %date on which cCellVision was trained.
        se
        method % string with the type of classification used in identifyCellCentresTrap:
               %    linear - just linear segmentation
               %    twoStage - linear followed by SVM with radial basis
               %               function
               %    wholeTrap  - stitches traps together into a strip and
               %                 does twoStage on whole image. Good for GPU
               %                 based stuff.
               %    wholeTrap - uses the whole image without dividing it
               %                into traps (though usuall then divides it
               %                into traps for storing and tracking, so
               %                final result is the same)
        radiusKeepTracking=9;  % trackUpdateObjects method, timelapseTraps method used for 
                               % identifying cell objects, uses this as a
                               % radius above which it assumes the cells will
                               % be present at the next timepoint and adjusts
                               % cell object identification accordingly.
        imageProcessingMethod = []  % used by timelapseTraps.returnSegmentationTrapStack
                                    % generally the same as method but
                                    % allows some processing.
linearToTwoStageParams = struct('threshold',Inf,... threshold of distance from twoStageThresh before twoStageModel is applied
                                'upperBoundType','fraction',... either 'fraction' (fraction of total image size) or 'absolute' (absolute number of pixels) determining an upper bound of the number of pixels to apply the twoStage threshold to.
                                'upperBound',0.015) % upper bound. Either the percentage or the total number of pixels to use.
                                % default structure is chosen to maintain
                                % default behaviour from before parameter
                                % structure was imposed.
                                trainingImageExample = [] ; %example of images used to train cellVision.

    end
    
    methods
        
        function cCellSVM=cellVision(do_nothing)
            % cCellSVM=cellVision(do_nothing)
            % do_nothing    :    boolean that allows construction without field
            %                    population for loading purposes. default false.
            if nargin<1 || isempty(do_nothing)
                do_nothing = false;
            end
            
            if ~do_nothing
            %% Read filenames from folder
            cCellSVM.scaling=struct('min',[],'max',[]);
            cCellSVM.trainingData=struct('features',[],'class',[],'kernel_features',[],'kernel_class',[]);
            cCellSVM.trainingParams=struct('cost',[],'gamma',[]);
            cCellSVM.negativeSamplesPerImage=500;
            cCellSVM.radiusSmall=5;
            cCellSVM.radiusLarge=17;
            cCellSVM.twoStageThresh=.1;
            cCellSVM.se.se4=strel('disk',4);
            cCellSVM.se.se3=strel('disk',3);
            cCellSVM.se.se2=strel('disk',2);
            cCellSVM.se.se1=strel('disk',1);
            cCellSVM.method='linear';
            end
        end
         
        function saveCellVision(cCellVision,location)
            % saveCellVision(cCellVision,location)
            % to save a cellVision model, by GUi if necessary.
            % save as a variable called cCellVision (the norm in our code).
            
            if nargin<2 || isempty(location)
                [file,path] = uiputfile('','Please select a location to save the cellVision','cCellVision.mat');
                location = fullfile(path,file);
            end
            save(location,'cCellVision');
        end
    end
    
    methods (Static)
            % to instantiate a cellVision model using and image from a
            % cExperiment.
            cCellVision = createCellVisionFromExperiment(cExperiment,pos);
        
        function cCellVision = loadobj(LoadStructure)
            % load method
            % allows checks for back compatibility and what not when you
            % add new features or want to change their default value.
            %% default loading method: DO NOT CHANGE
            cCellVision = cellVision(true);
            
            FieldNames = fieldnames(LoadStructure);
            %only populate mutable fields occcuring in both the load object
            %and the cCellVision object.
            FieldNames = intersect(FieldNames,fieldnames(cCellVision));
            
            for i = 1:numel(FieldNames)
                
                m = findprop(cCellVision,FieldNames{i});
                if ~strcmp(m.SetAccess,'immutable')
                    cCellVision.(FieldNames{i}) = LoadStructure.(FieldNames{i});
                end
                
            end
            
            %% back compatibility checks and what not
            %when a new field is added this load operation should be
            %updated to populate the field appropriately and maintain back
            %compatibility.
            
            if isempty(cCellVision.radiusKeepTracking)
                cCellVision.radiusKeepTracking = 9;
            end
            
            if isempty(cCellVision.imageProcessingMethod)
                cCellVision.imageProcessingMethod = cCellVision.method;
            end
            
            %set pixelSize to default for swain 60x experiments if empty.
            if isempty(cCellVision.pixelSize)
                cCellVision.pixelSize = 0.263;
            end
        end
    end
    
end

