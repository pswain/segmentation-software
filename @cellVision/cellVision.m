classdef cellVision<handle
    
    properties
        cTrap
        cPatchParameters
        SVMModel
        SVMModelLinear
        twoStageThresh
        scaling
        trainingData
        trainingParams
        negativeSamplesPerImage
        radiusSmall
        radiusLarge
        pixelSize
        
        
        se
        method
    end
    
    methods
        
        function cCellSVM=cellVision()
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
         
        % Basic trap procssing functions
        selectTrapTemplate(cCellSVM,cTimelapse,cTrapFileName)
        identifyTrapOutline(cCellSVM,cTimelapse,cCellVision,trapNum);
        
        %functions for processing the dictionary and training the SVM
        generateTrainingSet(cCellSVM,cDictionary);
        generateTrainingSet2Stage(cCellSVM,cDictionary,frame_ss);
        generateTrainingSetAll(cCellSVM,cDictionary,frame_ss);
        generateTrainingSetTimelapse(cCellSVM,cDictionary,frame_ss);
        trainSVM(cCellSVM,ss,cmd);
        trainSVM2Stage(cCellSVM,ss,decval,cmd1,cmd2);
        trainSVMLinear(cCellSVM,ss,cmd);
        runGridSearch(cCellSVM,ss,cmd);
        runGridSearch2Stage(cCellSVM,ss,cmd);
        runGridSearchLinear(cCellSVM,cmd)
        
        %to classify an image
        [predicted_im decision_im filtered_image]=classifyImage(cCellSVM,image);
        [predicted_im decision_im filtered_image]=classifyImageLinear(cCellSVM,image);
        [predicted_im decision_im filtered_image]=classifyImage2Stage(cCellSVM,image);
        filt_feat=createImFilterSetCellTrap(cCellSVM,image);
        filt_feat=createImFilterSetCellAsic(cCellSVM,image);
        [block cell]=createHOGFeaturesTraps(cCellSVM,image);
        
        %saving/loading functions
        loadDictionary(cDictionary)
        saveClassificationTraining(cCellSVM);
        saveClassificationOnly(cCellSVM);
        
    end
    
end

