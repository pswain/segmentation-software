function segmentACexperimental(cTimelapse,cCellVision,cCellMorph,FirstTimepoint,LastTimepoint,FixFirstTimePointBoolean,TrapsToUse)
%segmentACexperimental(cTimelapse,cCellVision,cCellMorph,FirstTimepoint,LastTimepoint,FixFirstTimePointBoolean,TrapsToUse)
%
% MAIN FUNCTION of the active contour based segmentation.
%
% Complete segmentation function that uses the cCellVision to identify cells
% and the active contour method to identify cell edges. 
%
% best description is in the associated paper.
%
%   INPUTS
% cTimelapse        - object of the cTimelapse class to be segment.
% cCellVision       - cCellVision cell identification model of the class cellVision.
% cCellMorph        - cCellMorph cell morphology model of the class
%                     cellMorphologyModel.
% FirstTimepoint    - time point at which to start. If 'start' will be the
%                     first timepoint to process. 
% LastTimepoint     - and to end. if 'end' will be the last timepoint to
%                     process.
% FixFirstTimePoint - optional : if this is true the software will not alter the first timepoint
%                     but will still use the information in finding cells.
% TrapsToUse        - optional : column vector [trapIndex] of which
%                     traps to segment.
%
%





if nargin<4 || isempty(FirstTimepoint) || strcmp(FirstTimepoint,'start')
    
    FirstTimepoint = min(cTimelapse.timepointsToProcess(:));
    
end


if nargin<5 || isempty(LastTimepoint) || strcmp(LastTimepoint,'end')
    
    LastTimepoint = max(cTimelapse.timepointsToProcess);
    
end



if nargin<6
    
    FixFirstTimePointBoolean = false;
    
end

if nargin<7|| isempty(TrapsToUse)
    TrapsToCheck = cTimelapse.defaultTrapIndices;
else
    TrapsToCheck = intersect(TrapsToUse(:,1),cTimelapse.defaultTrapIndices)';
end



%% %%%%%%%%%%%%%%%%%%%%%%%%%   EXTRACTING GENERAL PARAMETERS   %%%%%%%%%%%%%%%%%%%%%%%%%

% for any unspecified parameters use the default values.
ACParams = parse_struct(cTimelapse.ACParams,timelapseTraps.LoadDefaultACParams);

ACparameters = ACParams.ActiveContour;

% logical: whether to use the decision image to find the edge.
EdgeFromDecisionImage = cTimelapse.ACParams.ImageTransformation.EdgeFromDecisionImage;
% size of image used in AC edge identification. Set to just encompass the largest cell possible.
SubImageSize = 2*ACParams.ActiveContour.R_max + 1; 

% parameters for the motion prior. Passed to fspecial as smoothing
% parameters.
% first set for identifying new cells.
% second set for checking a cell is a tracked cell (so more stringent)
jump_parameters =  ACParams.CrossCorrelation.MotionPriorSmoothParameters;
jump_parameters_check = ACParams.CrossCorrelation.StrictMotionPriorSmoothParameters;

% size of probable cell location image
ProspectiveImageSize = max(jump_parameters(2),jump_parameters_check(2)); 

% value in probable location image cells must have before being identified.
CrossCorrelationValueThreshold = ACParams.CrossCorrelation.CrossCorrelationValueThreshold;

% maximum value tracked cells must have in the decision image to qualify as
% cells
CrossCorrelationDIMthreshold = ACParams.CrossCorrelation.CrossCorrelationDIMthreshold;%  -0.3; %decision image threshold above which cross correlated cells are not considered to be possible cells

% pixels by which a cells is dilated after identification for blotting in
% the probable location images and decision image.
PostCellIdentificationDilateValue = ACParams.CrossCorrelation.PostCellIdentificationDilateValue;% 2; %dilation applied to the cell outline to rule out new cell centres

% boundary in decision image for new cells negative is stricter, positive more lenient
TwoStageThreshold = ACParams.CrossCorrelation.twoStageThresh; 

% bwdist value of cell pixels which will not be allowed in the cell area (so inner (1-cellPixExcludeThresh) fraction will be ruled out of future other cell areas)
CellPixExcludeThresh = ACParams.ActiveContour.CellPixExcludeThresh;  

TrapPresentBoolean = cTimelapse.trapsPresent;

%object to provide priors for cell movement based on position and location.
if TrapPresentBoolean
    % if traps are present use the trained trap motion object
    CrossCorrelationPriorObject = ACMotionPriorObjects.FlowInTrapTrained(cCellVision,jump_parameters,cCellMorph.motion_model);
    % more stringent jump object for checking cell score
    CrossCorrelationPriorObjectCheck = ACMotionPriorObjects.FlowInTrapTrained(cCellVision,jump_parameters_check,cCellMorph.motion_model);
else
    % if traps are not present use a simple symmetric gaussian motion model.
    CrossCorrelationPriorObject = ACMotionPriorObjects.NoTrapSymmetric(cCellVision,jump_parameters);
    % more stringent jump object for checking cell score
    CrossCorrelationPriorObjectCheck = ACMotionPriorObjects.NoTrapSymmetric(cCellVision,jump_parameters_check);
end

%registers images and uses this to inform expected position. Useful in cases of big jumps like cycloheximide data sets.
PerformRegistration = ACParams.CrossCorrelation.PerformRegistration;
MaxRegistration = ACParams.CrossCorrelation.MaxRegistration;%50; %maximum allowed jump
if cTimelapse.trapsPresent
    %registration should be covered by tracking in the traps.
    PerformRegistration = false;
end


% lowest allowed probability for a cell shape and motion.
% selected rather arbitrarily from histogram of trained values.
threshold_probability = ACParams.CrossCorrelation.ThresholdCellProbability;

%throw away cells with a score higher than this.
threshold_score = ACParams.CrossCorrelation.ThresholdCellScore;

% probability that the trap edge (the part with value of 0.5 or greater) is
% a centre,edge or BG.
pTrapIsCentreEdgeBG = ACParams.ImageTransformation.pTrapIsCentreEdgeBG;

%variable assignments,mostly for convenience and parallelising.
TransformParameters = ACParams.ImageTransformation.TransformParameters;
TrapImageSize = size(cTimelapse.defaultTrapDataTemplate);

% this should only be used by the algorithm if it is not making the edge
% from the decision image.
if ~isempty(ACParams.ImageTransformation.ImageTransformFunction);
    ImageTransformFunction = str2func(['ACImageTransformations.' ACParams.ImageTransformation.ImageTransformFunction]);
end

NewCellStruct = cTimelapse.cellInfoTemplate;

Timepoints = FirstTimepoint:LastTimepoint;


%% %%%%%%%%%%%%%%%%%%%%%%%%%   GAUSSIAN SHAPE PRIOR PARAMETERS   %%%%%%%%%%%%%%%%%%%%%%%%%
 
% gaussian parameters for single curated cells

inverted_cov_1cell =...
    inv(cCellMorph.cov_new_cell_model);

mu_1cell = cCellMorph.mean_new_cell_model;


% gaussian parameters from pairs of curated cells.
inverted_cov_2cell_small =...
  inv(cCellMorph.cov_tracked_cell_model_small);
 
mu_2cell_small = ...
    cCellMorph.mean_tracked_cell_model_small;
 

log_det_cov_2cell_small = log(det(inverted_cov_2cell_small));

 
inverted_cov_2cell_large =...
   inv(cCellMorph.cov_tracked_cell_model_large);

mu_2cell_large = ...
    cCellMorph.mean_tracked_cell_model_large;

log_det_cov_2cell_large = log(det(inverted_cov_2cell_large));

threshold_radius = cCellMorph.thresh_tracked_cell_model;



%% %%%%%%%%%%%%%%%%%%%%%%%%%   PRE TP-LOOP SETUP   %%%%%%%%%%%%%%%%%%%%%%%%%


% set timepoint at which to start segmenting:
% if the first timepoint is suppose to be fixed it should not be segmented,
% so segmenting should only happen at FirstTimepoint + 1
if FixFirstTimePointBoolean
    TPtoStartSegmenting = FirstTimepoint+1;
else
    TPtoStartSegmenting = FirstTimepoint;
    
end


PreviousWholeImage = [];
PreviousTrapInfo = [];



%array to hold the maximum label used in each trap
if TPtoStartSegmenting == cTimelapse.timepointsToProcess(1)
    TrapMaxCell = zeros(1,length(cTimelapse.defaultTrapIndices));
else
    TrapMaxCell = cTimelapse.returnMaxCellLabel([],1:(TPtoStartSegmenting-1));
end


disp = cTrapDisplay(cTimelapse,[],[],true,ACParams.ActiveContour.ShowChannel,TrapsToCheck);

% gui\s for visualising outputs if that is desired.
if ACparameters.visualise
    guiDI = GenericStackViewingGUI;
    guiTransformed = GenericStackViewingGUI;
    guiOutline = GenericStackViewingGUI;
    guiTrapIM = GenericStackViewingGUI;
    guiEdge = GenericStackViewingGUI;
    guiEdge.title = 'P Edge';
    guiCentre = GenericStackViewingGUI;
    guiCentre.title = 'P Cell Centre';
    guiBG = GenericStackViewingGUI;
    guiBG.title = 'P Background';
end

% active contour code throws errors if asked to visualise in the parfor
% loop.
ACparametersPass = ACparameters;
ACparametersPass.visualise = 0;
                  

%% %%%%%%%%%%%%%%%%%%%%%%%%%   LOOP THROUGH TIMEPOINTS  %%%%%%%%%%%%%%%%%%%%%%%%%

for TP = Timepoints
    t_of_tic = tic;
    
    % Trigger the TimepointChanged event for experimentLogging
    experimentLogging.changeTimepoint(cTimelapse,TP);
    
    if TP>= TPtoStartSegmenting;
        
        %% GENERATE SEGMENTATION IMAGES
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        TrapInfo = cTimelapse.cTimepoint(TP).trapInfo;

        [DecisionImageStack, EdgeImageStack,TrapTrapImageStack,ACTrapImageStack,RawDecisionIms]...
            = cTimelapse.generateSegmentationImages(cCellVision,TP,TrapsToCheck,ACParams);

        have_raw_dims = ~isempty(RawDecisionIms);
        % calculate log P 's for each pixel type
        % correcting trap pixels if the correction value is non nan
        if have_raw_dims
            RawBgDIM = RawDecisionIms{1};
            RawCentreDIM = RawDecisionIms{2};
            
            PCentre =  -log(1 + exp(RawBgDIM)) -log(1 + exp(RawCentreDIM)) ;
            if ~any(isnan(pTrapIsCentreEdgeBG))
                PCentre(TrapTrapImageStack>=0.5) = log(pTrapIsCentreEdgeBG(1));
            end
            PCentre(TrapTrapImageStack==1) = min(PCentre(:));
            
            
            PEdge   =  RawCentreDIM -log(1 + exp(RawBgDIM)) -log(1 + exp(RawCentreDIM));
            if ~any(isnan(pTrapIsCentreEdgeBG))
                PEdge(TrapTrapImageStack>=0.5) = log(pTrapIsCentreEdgeBG(2));
            end
            PEdge(TrapTrapImageStack==1) = min(PEdge(:));
            
            
            PBG     = RawBgDIM - log(1 + exp(RawBgDIM));  
            if ~any(isnan(pTrapIsCentreEdgeBG))
                PBG(TrapTrapImageStack>=0.5) = log(pTrapIsCentreEdgeBG(3));
            end
            PBG(TrapTrapImageStack==1) = max(PBG(:));
            
            
            PTot = exp(PCentre) + exp(PEdge) + exp(PBG);
            
            % normalise
            PCentre = log(exp(PCentre)./PTot);
            PEdge = log(exp(PEdge)./PTot);
            PBG = log(exp(PBG)./PTot);
        else
            % to stop parfor loop bugging out.
            PCentre = zeros(size(DecisionImageStack));
            PEdge = PCentre;
            PBG = PCentre;
        end
        
        % for visualisation : definitions done outside if to keep parfor
        % loop well behaved.
        TransformedImagesVIS = cell(length(TrapInfo));
        OutlinesVIS = TransformedImagesVIS;
        CellStatsDebug = TransformedImagesVIS;
        if ACparameters.visualise
            guiEdge.stack = PEdge;
            guiEdge.LaunchGUI();
            guiCentre.stack = PCentre;
            guiCentre.LaunchGUI;
            guiBG.stack = PBG;
            guiBG.LaunchGUI;
            fprintf('\n\n please press enter when finished inspecting \n\n');
            pause;
        end
        
        % boolean of whether to identify tracked cells or new cells.
        CrossCorrelating = false(size(TrapsToCheck));
        
        %%  CONSTRUCT PREDICTED CELL LOCATIONS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % this section uses the motion priors, previous timpoint
        % information and cell decision images to generate the predicted
        % cell locations for cells at the current timepoint.
        PredictedCellLocationsAllCells = cell(size(TrapsToCheck));
        
        for TI = 1:length(TrapsToCheck)
            trap = TrapsToCheck(TI);
            TrapDecisionImage = DecisionImageStack(:,:,TI);
            
            if TP>FirstTimepoint
                PreviousCurrentTrapInfo = PreviousTrapInfo(trap);
            end
            
            if TP>FirstTimepoint && (PreviousCurrentTrapInfo.cellsPresent) && CrossCorrelationValueThreshold<Inf && ~isempty(PreviousCurrentTrapInfo.cell(1).cellCenter)
                
                % REGISTRATION
                % can be useful if doing slides and they shift alot (like
                % matec dishes).
                % register images and use to inform expected position
                % this is only done if there are no traps and if requested
                % in the segmentation parameters.
                % uses The first slice of the decision image stack. Not
                % ideal but only one that is certainly present.
                if PerformRegistration
                    reg_result = FindRegistrationForImageStack(cat(3,PreviousWholeImage(:,:,1),DecisionImageStack(:,:,1)),1,MaxRegistration);
                    reg_result = fliplr(reg_result(2,:));
                    %this is no the shift required in the current image -
                    % [x y] after fliplr - to make it match up with the
                    % Previous timepoint image, so is later subtracted from
                    % the expected position to get a better expected
                    % position estimate.
                else
                    reg_result = [0 0];
                    %needs to be initialised for parpool
                end
                
                % instantial the probable location image stack with a value
                % for which new cells will never be identified.
                PredictedCellLocationsAllCells{TI} = -2*abs(CrossCorrelationValueThreshold)*ones(TrapImageSize(1),TrapImageSize(2),length(PreviousCurrentTrapInfo.cell));
                
                for CI = 1:length(PreviousCurrentTrapInfo.cell)
                    
                    ExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).cellCenter;
                    
                    if PerformRegistration
                        ExpectedCellCentre = ExpectedCellCentre - reg_result;
                        % botch fix for error due to Expected centre being out of
                        % range should only be necessary when registration
                        % is performed.
                        % sets predicted location to a value for which it
                        % will not be identified anywhere
                        if ExpectedCellCentre(1)>TrapImageSize(2) ||ExpectedCellCentre(1)<1 || ExpectedCellCentre(2)>TrapImageSize(1) || ExpectedCellCentre(2)<1
                            PredictedCellLocationsAllCells{TI}(:,:,CI) =  -2*abs(CrossCorrelationValueThreshold)*ones(TrapImageSize);
                            continue
                        end
                        
                    end
                    

                    if ~isfield(PreviousCurrentTrapInfo.cell(CI),'cellRadii')
                        CellRadii = mean(PreviousCurrentTrapInfo.cell(CI).cellRadius);
                    else
                        CellRadii = mean(PreviousCurrentTrapInfo.cell(CI).cellRadii);
                    end
                    
                    %decision image is negative where cells are
                    %likely to be, so take the negative.
                    PredictedCellLocation = -ACBackGroundFunctions.get_cell_image(TrapDecisionImage,...
                        ProspectiveImageSize,...
                        ExpectedCellCentre,...
                        Inf);

                    % apply 'movement prior' provided by MotionPrior oject
                    ProbableMotionImage = CrossCorrelationPriorObject.returnPrior(ExpectedCellCentre,CellRadii);
                    
                    PredictedCellLocation = log(ProbableMotionImage)+PredictedCellLocation;
                    
                    % get the predicted location but shifted so that it
                    % lines up with the trap image
                    temp_im = ACBackGroundFunctions.get_cell_image(PredictedCellLocation,...
                        TrapImageSize,...
                        (ceil(ProspectiveImageSize/2)*[1 1] + ceil(fliplr(TrapImageSize)/2)) - ExpectedCellCentre,...
                        -2*abs(CrossCorrelationValueThreshold) );
                    
                    % set those pixels above the more lenient decision
                    % image threshold to a value for which they will
                    % never be identified as cells.
                    temp_im(TrapDecisionImage>CrossCorrelationDIMthreshold)  = -2*abs(CrossCorrelationValueThreshold);
                    PredictedCellLocationsAllCells{TI}(:,:,CI) = temp_im;
                    
                end
                
                % record that search over previous cells should be done for
                % this trap.
                CrossCorrelating(TI) = true;
            else
                CrossCorrelating(TI) = false;
                
            end %if timepoint> FirstTimepoint
            
            % make all definite trap pixels in the Decision image and the
            % PredictedCellLocation Images such that they will not be
            % identified as cells.
            if TrapPresentBoolean

                TrapTrapImage = TrapTrapImageStack(:,:,TI);
                
                TrapTrapLogical = TrapTrapImage >= 1;
                if CrossCorrelating(TI)
                    PredictedCellLocationsAllCells{TI}(repmat(TrapTrapLogical,[1,1,size(PredictedCellLocationsAllCells{TI},3)])) = -2*abs(CrossCorrelationValueThreshold);
                    
                end
                TrapDecisionImage(TrapTrapLogical) = 2*abs(TwoStageThreshold);
                DecisionImageStack(:,:,TI) = TrapDecisionImage;
            else
                TrapTrapLogical = false(TrapImageSize);
                TrapTrapImageStack = zeros([TrapImageSize length(TrapsToCheck)]);
                
            end
            
            
        end
        
        %% PREP FOR PARALLEL LOOP
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Variables need to be organised in a particular way for error free
        % and efficient parallelisation
        
        % this distinction is made so that some information can be written
        % for this function that will not be written to the final
        % cTimelapse object.
        SliceableTrapInfo = TrapInfo(TrapsToCheck);
        if TP>FirstTimepoint
            SliceablePreviousTrapInfo = PreviousTrapInfo(TrapsToCheck);
        else
            SliceablePreviousTrapInfo = ones(size(CrossCorrelating));
        end
        
        SliceableTrapMaxCell = TrapMaxCell(TrapsToCheck);
       
        cells_discarded = 0;
        cells_found = 0;
        
        
        
        %%  PARALLLEL LOOP 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        fprintf('CHANGE BACK TO PARFOR IN %s.%s\n',class(cTimelapse),mfilename)
        if length(TrapsToCheck)>1
            current_pool = gcp;
            pool_size = current_pool.NumWorkers;
        else
            pool_size = 0;
        end
        %parfor( TI = 1:length(TrapsToCheck),pool_size)
        for TI = 1:length(TrapsToCheck)
            
            %%%%%%%%%% unpack parallel variables
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
            PreviousCurrentTrapInfoPar = [];
            if CrossCorrelating(TI)
                PreviousCurrentTrapInfoPar = SliceablePreviousTrapInfo(TI);
            end
            
            PreviousTimepointRadii = [];
            TrapDecisionImage = DecisionImageStack(:,:,TI);
            TrapTrapImage = TrapTrapImageStack(:,:,TI);
            
            if have_raw_dims
                PCentreTrap = PCentre(:,:,TI);
                PEdgeTrap = PEdge(:,:,TI);
                PBGTrap = PBG(:,:,TI);
            else
                PCentreTrap = [];
                PEdgeTrap = [];
                PBGTrap = [];
            end
            
            ParCurrentTrapInfo = SliceableTrapInfo(TI);
            
            % used to exclude regions that contain cells once they are
            % found.
            AllCellPixels = zeros(size(TrapTrapLogical));
            
            ACTrapImage = ACTrapImageStack(:,:,TI);
            
            CellSearch = true;
            ProceedWithCell = false;
            NCI = 0;
            ParCurrentTrapInfo.cell = NewCellStruct;
            ParCurrentTrapInfo.cellsPresent = false;
            ParCurrentTrapInfo.cellLabel = [];
            ynewcell = 0;
            xnewcell = 0;
            CIpar = [];
            
            % for visualisation if debugging code
            TransformedImagesVISTrap = [];
            OutlinesVISTrap = [];
            CellStatsDebugTrap = [];

            
            %%%%%%%%%%% look for new cells
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            while CellSearch
                
                if CrossCorrelating(TI)
                    %look for cells based on cross correlation with
                    %previous timepoint
                    [value,Index] = max(PredictedCellLocationsAllCells{TI}(:));
                    value = value(1);
                    Index = Index(1);
                    if value>CrossCorrelationValueThreshold
                        [ynewcell,xnewcell,CIpar] = ind2sub(size(PredictedCellLocationsAllCells{TI}),Index);
                        ProceedWithCell = true;
                    else
                        ProceedWithCell = false;
                        CrossCorrelating(TI) = false;
                    end
                end
                
                if ~CrossCorrelating(TI)
                    %look for cells based based on SVM decisions matrix
                    [value,Index] = min(TrapDecisionImage(:));
                    value = value(1);
                    Index = Index(1);
                    if value<TwoStageThreshold
                        [ynewcell,xnewcell] = ind2sub(size(TrapDecisionImage),Index);
                        ProceedWithCell = true;
                    else
                        CellSearch = false;
                        ProceedWithCell = false;
                    end
                    
                    
                end
                %%%%%%%%%%% do active contour edge identification
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
                if ProceedWithCell
                    %do active contour
                    
                    NewCellCentre = [xnewcell ynewcell];
                    
                    NotCellsCell = ACBackGroundFunctions.get_cell_image(AllCellPixels,...
                        SubImageSize,...
                        [xnewcell ynewcell],...
                        false);
                    
                    CellTrapImage = ACBackGroundFunctions.get_cell_image(TrapTrapImage,...
                        SubImageSize, ...
                        NewCellCentre );
                    
                    if have_raw_dims && EdgeFromDecisionImage
                        % use the decision image result to get the edge
                        PCentreCell = ACBackGroundFunctions.get_cell_image(PCentreTrap,SubImageSize,NewCellCentre );
                        PEdgeCell = ACBackGroundFunctions.get_cell_image(PEdgeTrap,SubImageSize,NewCellCentre );
                        PBGCell = ACBackGroundFunctions.get_cell_image(PBGTrap,SubImageSize,NewCellCentre );
                        
                        
                        TransformedCellImage = -PEdgeCell + log(1-exp(PEdgeCell));
                        CellRegionImage = log(1-exp(PCentreCell))-PCentreCell; 
                    else
                        % use some function to pick out edge
                        CellImage = ACBackGroundFunctions.get_cell_image(ACTrapImage,...
                            SubImageSize,...
                            NewCellCentre );
                        
                        TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters,CellTrapImage);
                        
                        % subtraction of the median has been left in for
                        % legacy. Shouldn't effect procedure anymore.
                        TransformedCellImage = TransformedCellImage - median(TransformedCellImage(:));
                        CellRegionImage = zeros(size(TransformedCellImage));
                    end
                    % this region is (roughly) forcibly excluded, so that
                    % it cannot be included in the cell.
                    ExcludeLogical = (CellTrapImage>=1)| (NotCellsCell>=CellPixExcludeThresh);
                    
                    if ~any(ExcludeLogical(:))
                        ExcludeLogical = [];
                    end
                    
                    if CrossCorrelating(TI)
                        PreviousTimepointRadii = PreviousCurrentTrapInfoPar.cell(CIpar).cellRadii;
                        
                        [RadiiResult,AnglesResult,ACscore] = ...
                            ACMethods.PSORadialTimeStack(TransformedCellImage,ACparametersPass,PreviousTimepointRadii,ExcludeLogical,CellRegionImage,cCellMorph);
                    else
                        [RadiiResult,AnglesResult,ACscore] = ...
                            ACMethods.PSORadialTimeStack(TransformedCellImage,ACparametersPass,[],ExcludeLogical,CellRegionImage,cCellMorph);
                    end
                    
                    %%%%%%%%%%% check cell meets criteria
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
                    % check tracked cell meets criteria of shape change
                    if CrossCorrelating(TI)
                        reordered_radii = ACBackGroundFunctions.reorder_radii(cat(1,PreviousTimepointRadii,RadiiResult));
                        reordered_radii_norm = log(reordered_radii(2,:)./reordered_radii(1,:));
                        reordered_radii_1cell = reordered_radii(2,:);
                        
                        %calculate radii contribution (bayes factor of new and old cell for the found radii)
                        if mean(PreviousTimepointRadii)<threshold_radius
                            p_score = -(reordered_radii_norm - mu_2cell_small)*inverted_cov_2cell_small*((reordered_radii_norm - mu_2cell_small)') ...
                                - 0.5*log_det_cov_2cell_small - sum(reordered_radii_norm) + ...
                                (reordered_radii_1cell - mu_1cell)*inverted_cov_1cell*((reordered_radii_1cell - mu_1cell)');
                        else
                            p_score = -(reordered_radii_norm - mu_2cell_large)*inverted_cov_2cell_large*((reordered_radii_norm - mu_2cell_large)')...
                                - 0.5*log_det_cov_2cell_large - sum(reordered_radii_norm) + ...
                                (reordered_radii_1cell - mu_1cell)*inverted_cov_1cell*((reordered_radii_1cell - mu_1cell)');
                        
                        end
                        
                        % intended to supress matlab warnings
                        PreviousTimepointRadii = [];
                        % calculate movement contribution
                        old_cell_center = PreviousCurrentTrapInfoPar.cell(CIpar).cellCenter;
                        old_cell_radius = mean(PreviousCurrentTrapInfoPar.cell(CIpar).cellRadii);
                        
                        movement_prior = CrossCorrelationPriorObjectCheck.returnPrior(old_cell_center, old_cell_radius);
                        
                        relative_new_cell_loc = [xnewcell,ynewcell] - old_cell_center + fliplr(ceil(TrapImageSize/2)); 
                        
                        relative_new_cell_loc(relative_new_cell_loc<1) = 1;
                        relative_new_cell_loc(relative_new_cell_loc>TrapImageSize) = TrapImageSize(relative_new_cell_loc>TrapImageSize);
                        
                        p_movement = movement_prior(relative_new_cell_loc(2),relative_new_cell_loc(1));
                        p_score = p_score + log(p_movement);
                        
                        if p_score < log(threshold_probability) || ACscore> threshold_score
                            SegmentationBinary = ACBackGroundFunctions.get_outline_from_radii(RadiiResult',AnglesResult',[xnewcell ynewcell],TrapImageSize);
                            
                            SegmentationBinary = imfill(SegmentationBinary,[ynewcell xnewcell]);
                            % set that area so that it won't be found again
                            % as a tracked cell of the same cell.
                            temp_im = PredictedCellLocationsAllCells{TI}(:,:,CIpar);
                            temp_im(SegmentationBinary) = -2*abs(CrossCorrelationValueThreshold);
                            PredictedCellLocationsAllCells{TI}(:,:,CIpar) = temp_im;
                            %return to while loop on cells
                            cells_discarded = cells_discarded+1;
                            continue
                        end
                    else
                        % similar checks for untracked 'new' cells
                        if  ACscore> threshold_score
                            SegmentationBinary = ACBackGroundFunctions.get_outline_from_radii(RadiiResult',AnglesResult',[xnewcell ynewcell],TrapImageSize);
                            
                            SegmentationBinary = imfill(SegmentationBinary,[ynewcell xnewcell]);
                            % set that area so that it won't be found as a
                            % new cell again
                            
                            TrapDecisionImage(SegmentationBinary) = 2*abs(TwoStageThreshold);
                            %return to while loop on cells
                            cells_discarded = cells_discarded+1;
                            continue
                        end
                        p_score = 0;
                        
                    end
                    
                    %%%%%%%%%%% write new cell info
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    cells_found = cells_found+1;
                    NCI = NCI+1;
                    
                    ParCurrentTrapInfo.cell(NCI) = NewCellStruct;
                    
                    if CrossCorrelating(TI)
                        ParCurrentTrapInfo.cellLabel(NCI) = PreviousCurrentTrapInfoPar.cellLabel(CIpar);
                    else
                        ParCurrentTrapInfo.cellLabel(NCI) = SliceableTrapMaxCell(TI)+1;
                        SliceableTrapMaxCell(TI) = SliceableTrapMaxCell(TI)+1;

                    end
                    ParCurrentTrapInfo.cell(NCI).cellCenter = double([xnewcell ynewcell]);
                    ParCurrentTrapInfo.cellsPresent = true;
                    
                    %write active contour result and change cross
                    %correlation matrix and decision image.
                    
                    ParCurrentTrapInfo.cell(NCI).cellRadii = RadiiResult;
                    ParCurrentTrapInfo.cell(NCI).cellAngle = AnglesResult;
                    ParCurrentTrapInfo.cell(NCI).cellRadius = mean(RadiiResult);
                    
                    SegmentationBinary = ACBackGroundFunctions.get_outline_from_radii(RadiiResult',AnglesResult',double(ParCurrentTrapInfo.cell(NCI).cellCenter),TrapImageSize);
                    ParCurrentTrapInfo.cell(NCI).segmented = sparse(SegmentationBinary);
                    
                    if ACparameters.visualise
                        % store some visualisation results for after parfor
                        % loop.
                        TransformedImagesVISTrap = cat(3,TransformedImagesVISTrap,TransformedCellImage);
                        [pxVIS,pyVIS] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult',AnglesResult',round(size(TransformedCellImage)/2),size(TransformedCellImage));
                        SegmentationBinary = false(size(TransformedCellImage));
                        SegmentationBinary(pyVIS+size(TransformedCellImage,1)*(pxVIS-1))=true;
                        OutlinesVISTrap = cat(3,OutlinesVISTrap,SegmentationBinary);
                        CellStatsDebugTrap = cat(1,CellStatsDebugTrap,[ACscore p_score]);
                        
                    end
                    
                    % blot out images in other traps with a delated/eroded
                    % segmentation mask
                    SegmentationBinary = imfill(SegmentationBinary,'holes');
                    DilateSegmentationBinary = SegmentationBinary;
                    if PostCellIdentificationDilateValue>0
                        DilateSegmentationBinary = imdilate(SegmentationBinary,strel('disk',PostCellIdentificationDilateValue),'same');
                    elseif PostCellIdentificationDilateValue<0
                        DilateSegmentationBinary = imerode(SegmentationBinary,strel('disk',PostCellIdentificationDilateValue),'same');
                    
                    end
                    if CrossCorrelating(TI)
                        %remove cell that has been successfully cross
                        %correlated from cross correlation matrix
                        PredictedCellLocationsAllCells{TI}(:,:,CIpar) = -2*abs(CrossCorrelationValueThreshold);
                        
                        %ensure no cells are found overlapping identified cell
                        %complicated line but makes list of indices of cell
                        %pixels. Saves significant time when using large
                        %images (i.e. when there are no traps).
                        pixels_to_remove = find(DilateSegmentationBinary);
                        all_pixels_to_remove = kron(ones(1,size(PredictedCellLocationsAllCells{TI},3)),pixels_to_remove') ...
                            + kron(((0:(size(PredictedCellLocationsAllCells{TI},3)-1))*size(PredictedCellLocationsAllCells{TI},1)*size(PredictedCellLocationsAllCells{TI},2)),ones(1,length(pixels_to_remove)));
                        PredictedCellLocationsAllCells{TI}(all_pixels_to_remove) = -2*abs(CrossCorrelationValueThreshold);
                        
                    end
                    %remove pixels identified as cell pixels from
                    %decision image
                    TrapDecisionImage(DilateSegmentationBinary) = 2*abs(TwoStageThreshold)+1;
                    
                    %update AllCellPixels so that it includes all
                    %segmented cells
                    EdgeConfidenceImage = bwdist(~SegmentationBinary);
                    EdgeConfidenceImage = EdgeConfidenceImage./max(EdgeConfidenceImage(:));
                    AllCellPixels = AllCellPixels + EdgeConfidenceImage;

                end %if ProceedWithCell
                
            end %while cell search
            
            if ACparameters.visualise
                
                OutlinesVIS{TI} = OutlinesVISTrap;
                TransformedImagesVIS{TI} = TransformedImagesVISTrap;
                CellStatsDebug{TI} = CellStatsDebugTrap;
                
            end
            
            SliceableTrapInfo(TI) = ParCurrentTrapInfo;
            
            TransformedCellImage = [];
            
        end %end traps loop
        fprintf('%d cells of %d discarded\n',cells_discarded,(cells_found+cells_discarded));
        
        %% POST EDGE FINDING CLEANUP
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        TrapMaxCell(TrapsToCheck) = SliceableTrapMaxCell;
        
        %write results to cTimelapse
        cTimelapse.cTimepoint(TP).trapInfo(TrapsToCheck) = SliceableTrapInfo;
        cTimelapse.timepointsProcessed(TP) = true;
        
        TrapInfo(TrapsToCheck) = SliceableTrapInfo;
    else
        TrapInfo = cTimelapse.cTimepoint(TP).trapInfo;
    end
    

    %% PREP VARIABLES FOR NEXT LOOP ITERATION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    PreviousWholeImage = DecisionImageStack;
    PreviousTrapInfo = TrapInfo;
    TimeOfTimepoint = toc(t_of_tic);
    
    fprintf('timepoint analysed in %.2f seconds \n',TimeOfTimepoint);
    
    set(disp.slider,'Value',TP);
    disp.slider_cb;
    % if visualising, show all the identified outlines and their associated
    % forcing and score images.
    if ACparameters.visualise && TP>=TPtoStartSegmenting
        OutlinesStack = [];
        TransformedImagesStack =[];
        CellStats = [];
        for TI = 1:length(TrapInfo)
            if ~isempty(OutlinesVIS{TI})
                OutlinesStack = cat(3,OutlinesStack,OutlinesVIS{TI});
            end
            if ~isempty(TransformedImagesVIS{TI})
                TransformedImagesStack = cat(3,TransformedImagesStack,TransformedImagesVIS{TI});
            end
            if ~isempty(CellStatsDebug{TI})
                CellStats = cat(1,CellStats,CellStatsDebug{TI});
            end
        end
        guiDI.stack = DecisionImageStack;
        guiDI.title = 'Decision Images';
        guiDI.LaunchGUI;
        guiTransformed.stack = TransformedImagesStack;
        guiTransformed.title = 'Transformed images for AC';
        guiTransformed.LaunchGUI;
        guiOutline.stack = OutlinesStack;
        guiOutline.title = 'identified outlines';
        guiOutline.LaunchGUI;
        guiTrapIM.stack = cTimelapse.returnTrapsTimepoint(TrapsToCheck,TP,ACParams.ActiveContour.ShowChannel);
        guiTrapIM.title = 'trap image';
        guiTrapIM.LaunchGUI;
        for i=1:size(CellStats,1)
            % print scores of cells
            fprintf('cell %d  score %3.3g  shape score %3.3g \n',i,CellStats(i,1),CellStats(i,2));
            
        end
        fprintf('press enter to continue . . . . \n')
        pause;
        
    end
    drawnow;
end %end TP loop

close(disp.figure);

end



