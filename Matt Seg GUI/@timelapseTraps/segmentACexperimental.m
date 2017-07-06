function segmentACexperimental(cTimelapse,cCellVision,FirstTimepoint,LastTimepoint,FixFirstTimePointBoolean,TrapsToUse)
%segmentACexperimental(cTimelapse,cCellVision,FirstTimepoint,LastTimepoint,FixFirstTimePointBoolean,TrapsToUse)
%
% MAIN FUNCTION of the active contour based segmentation.
%
% Complete segmentation function that uses the cCellVision to identify cells
% and the active contour 
%
%   INPUTS
% FirstTimepoint    - time point at which to start
% LastTimepoint     - and to end
% FixFirstTimePoint - optional : if this is true the software will not alter the first timepoint
%                     but will still use the information in finding cells.
% TrapsToUse        - optional (array) column vector [trapIndex] of which
%                     traps to segment.
%
%





if nargin<3 || isempty(FirstTimepoint)
    
    FirstTimepoint = min(cTimelapse.timepointsToProcess(:));
    
end

if nargin<4 || isempty(LastTimepoint)
    
    LastTimepoint = max(cTimelapse.timepointsToProcess);
    
end

if nargin<5
    
    FixFirstTimePointBoolean = false;
    
end

if nargin<6|| isempty(TrapsToUse)
    TrapsToCheck = cTimelapse.defaultTrapIndices;
else
    TrapsToCheck = intersect(TrapsToUse(:,1),cTimelapse.defaultTrapIndices)';
end

ACparameters = cTimelapse.ACParams.ActiveContour;

% size of image used in AC edge identification. Set to just encompass the largest cell possible.
SubImageSize = 2*cTimelapse.ACParams.ActiveContour.R_max + 1; 

% parameters for the motion prior. Passed to fspecial as smoothing
% parameters.
% first set for identifying new cells.
% second set for checking a cell is a tracked cell (so more stringent)
jump_parameters =  cTimelapse.ACParams.CrossCorrelation.MotionPriorSmoothParameters;
jump_parameters_check =cTimelapse.ACParams.CrossCorrelation.StrictMotionPriorSmoothParameters;

% size of probable cell location image
ProspectiveImageSize = max(jump_parameters(2),jump_parameters_check(2)); 

% value in probable location image cells must have before being identified.
CrossCorrelationValueThreshold = cTimelapse.ACParams.CrossCorrelation.CrossCorrelationValueThreshold;

% maximum value tracked cells must have in the decision image to qualify as
% cells
CrossCorrelationDIMthreshold = cTimelapse.ACParams.CrossCorrelation.CrossCorrelationDIMthreshold;%  -0.3; %decision image threshold above which cross correlated cells are not considered to be possible cells

% pixels by which a cells is dilated after identification for blotting in
% the probable location images and decision image.
PostCellIdentificationDilateValue = cTimelapse.ACParams.CrossCorrelation.PostCellIdentificationDilateValue;% 2; %dilation applied to the cell outline to rule out new cell centres


RadMeans = (cTimelapse.ACParams.ActiveContour.R_min:cTimelapse.ACParams.ActiveContour.R_max)';%(2:15)';
RadRanges = [RadMeans-0.5 RadMeans+0.5];

TwoStageThreshold = cTimelapse.ACParams.CrossCorrelation.twoStageThresh; % boundary in decision image for new cells negative is stricter, positive more lenient

% pixels which cannot be classified as centres
TrapPixExcludeThreshCentre = cTimelapse.ACParams.CrossCorrelation.TrapPixExcludeThreshCentre;
% trap pixels which will not be allowed within active contour areas
TrapPixExcludeThreshAC = cTimelapse.ACParams.ActiveContour.TrapPixExcludeThreshAC;
% bwdist value of cell pixels which will not be allowed in the cell area (so inner (1-cellPixExcludeThresh) fraction will be ruled out of future other cell areas)
CellPixExcludeThresh = cTimelapse.ACParams.ActiveContour.CellPixExcludeThresh;  

TrapPresentBoolean = cTimelapse.trapsPresent;

%object to provide priors for cell movement based on position and location.
if TrapPresentBoolean
    CrossCorrelationPriorObject = ACMotionPriorObjects.FlowInTrapTrained(cTimelapse,cCellVision,jump_parameters);
    % more stringent jump object for checking cell score
    CrossCorrelationPriorObjectCheck = ACMotionPriorObjects.FlowInTrapTrained(cTimelapse,cCellVision,jump_parameters_check);
else
    CrossCorrelationPriorObject = ACMotionPriorObjects.NoTrapSymmetric(cTimelapse,cCellVision,jump_parameters);
    % more stringent jump object for checking cell score
    CrossCorrelationPriorObjectCheck = ACMotionPriorObjects.NoTrapSymmetric(cTimelapse,cCellVision,jump_parameters_check);
end

%registers images and uses this to inform expected position. Useful in cases of big jumps like cycloheximide data sets.
PerformRegistration = cTimelapse.ACParams.CrossCorrelation.PerformRegistration;
MaxRegistration = cTimelapse.ACParams.CrossCorrelation.MaxRegistration;%50; %maximum allowed jump
if cTimelapse.trapsPresent
    PerformRegistration = false; %registration should be covered by tracking in the traps.
end

if TrapPresentBoolean
    % default trapOutline used for normalisation.
    DefaultTrapOutline = 1*cCellVision.cTrap.trapOutline;
end

Recentering =false;%true; %recalcluate the centre of the cells each time as the average ofthe outline

% lowest allowed probability for a cell shape and motion.
% selected rather arbitrarily from histogram of trained values.
threshold_probability = cTimelapse.ACParams.CrossCorrelation.ThresholdCellProbability;

%throw away cells with a score higher than this.
threshold_score = cTimelapse.ACParams.CrossCorrelation.ThresholdCellScore;

% probability that the trap edge (the part with value of 0.5 or greater) is
% a centre,edge or BG.
pTrapIsCentreEdgeBG = cTimelapse.ACParams.ImageTransformation.pTrapIsCentreEdgeBG;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for trained cell trakcing rubbish

% for trained time change punishment

% gaussian parameters for single curated cells

inverted_cov_1cell =...
    [0.9568   -0.9824    0.2210   -0.3336    0.2061   -0.1774
   -0.9824    2.3140   -0.7398    0.3936   -0.2683   -0.6752
    0.2210   -0.7398    1.4997   -0.9595    0.4939   -0.3992
   -0.3336    0.3936   -0.9595    1.5773   -1.0942    0.4536
    0.2061   -0.2683    0.4939   -1.0942    1.6916   -0.9590
   -0.1774   -0.6752   -0.3992    0.4536   -0.9590    1.9724];

mu_1cell = [9.1462    8.0528    6.7623    6.1910    6.0670    6.8330];


% gaussian parameters from pairs of curated cells.
inverted_cov_2cell_small =...
  [150.0532  -55.6032    5.8445   12.8486    8.1765  -17.8547
  -55.6032  109.4672  -14.8512    0.0212    4.8178  -12.1094
    5.8445  -14.8512   47.9182  -10.1944   11.3427   14.3080
   12.8486    0.0212  -10.1944   37.7482  -10.2208   -1.6160
    8.1765    4.8178   11.3427  -10.2208   48.5290   -6.9169
  -17.8547  -12.1094   14.3080   -1.6160   -6.9169   61.7951];
 
mu_2cell_small = ...
    [0.0388    0.0422   -0.0020   -0.0234    0.0017    0.0340];
 

log_det_cov_2cell_small = log(det(inverted_cov_2cell_small));

 
inverted_cov_2cell_large =...
    [228.3962  -55.5536   12.3227   21.5177   22.8732    1.4406
  -55.5536  199.8526    3.9693   17.2392   19.9806   -4.4419
   12.3227    3.9693   82.6106  -18.6513   19.5364   28.0344
   21.5177   17.2392  -18.6513   74.3356  -19.7211   18.4087
   22.8732   19.9806   19.5364  -19.7211   70.1115  -16.8373
    1.4406   -4.4419   28.0344   18.4087  -16.8373  109.5118 ];

mu_2cell_large = ...
    [ 0.0245    0.0264   -0.0137   -0.0488   -0.0349    0.0079];

log_det_cov_2cell_large = log(det(inverted_cov_2cell_large));

threshold_radius = 6;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%variable assignments,mostly for convenience and parallelising.
TransformParameters = cTimelapse.ACParams.ImageTransformation.TransformParameters;
TrapImageSize = size(cTimelapse.defaultTrapDataTemplate);

ImageTransformFunction = str2func(['ACImageTransformations.' cTimelapse.ACParams.ImageTransformation.ImageTransformFunction]);

if TrapPresentBoolean
    TrapWidth = cTimelapse.cTrapSize.bb_width;
    TrapHeight = cTimelapse.cTrapSize.bb_height;
end

NewCellStruct = cTimelapse.cellInfoTemplate;


%FauxCentersStack is just a filler for the PSO optimisation that takes centers
%(because in this code the centers are always at the centers of the image).
%Better to assign it here than every time in the loop.
FauxCentersStack = round(SubImageSize/2)*ones(1,2);

Timepoints = FirstTimepoint:LastTimepoint;

%% set TP at which to start segmenting

% if the first timepoint is suppose to be fixed it should not be segmented,
% so segmenting should only happen at FirstTimepoint + 1
if FixFirstTimePointBoolean
    TPtoStartSegmenting = FirstTimepoint+1;
else
    TPtoStartSegmenting = FirstTimepoint;
    
end


PreviousWholeImage = [];
PreviousTrapInfo = [];


%visualising trackin

if cTimelapse.ACParams.ActiveContour.visualise;
    cc_gui = GenericStackViewingGUI;
end


%array to hold the maximum label used in each trap
if TPtoStartSegmenting == cTimelapse.timepointsToProcess(1)
    TrapMaxCell = zeros(1,length(cTimelapse.defaultTrapIndices));
else
    TrapMaxCell = cTimelapse.returnMaxCellLabel([],1:(TPtoStartSegmenting-1));
end


disp = cTrapDisplay(cTimelapse,[],true,cTimelapse.ACParams.ActiveContour.ShowChannel,TrapsToCheck);

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

% apply more computaitonal power to cells found for the first time.
ACparametersPassFirstFind = ACparametersPass;
ACparametersPassFirstFind.seeds_for_PSO = 2*ACparametersPassFirstFind.seeds_for_PSO;
ACparametersPassFirstFind.seeds = 2*ACparametersPassFirstFind.seeds;


ACImageChannel = cTimelapse.ACParams.ImageTransformation.channel;
    
DecisionImageChannel = cTimelapse.channelsForSegment;

if TrapPresentBoolean
    TrapRefineChannel = cTimelapse.ACParams.TrapDetection.channel;
    if isempty(TrapRefineChannel)
        TrapRefineChannel = cTimelapse.channelForTrapDetection;
    end
    TrapRefineFunction =  str2func(['ACTrapFunctions.' cTimelapse.ACParams.TrapDetection.function]);
    TrapRefineParameters = cTimelapse.ACParams.TrapDetection.functionParams;
    if isempty(TrapRefineParameters.starting_trap_outline);
        TrapRefineParameters.starting_trap_outline = cCellVision.cTrap.trapOutline;
    end
    TrapRefineFunction = @(stack) TrapRefineFunction(stack,TrapRefineParameters);
else
    TrapRefineChannel = [];
end
CrossCorrelationMethod = 'just_DIM';
                    

%% loop through timepoints
for TP = Timepoints
    tic;
    
    % fprintf('timepoint %d \n',TP)
    % Trigger the TimepointChanged event for experimentLogging
    experimentLogging.changeTimepoint(cTimelapse,TP);
    
    % collect all channels used so that they are only loaded once. 
    AllChannelsToLoad = unique(abs([ACImageChannel TrapRefineChannel DecisionImageChannel]));
    
    CCImage = [];
    %ensure images are only loaded once even if used in various parts of
    %the code.
    for chi = 1:length(AllChannelsToLoad)
        channel = AllChannelsToLoad(chi);
        TempIm = double(cTimelapse.returnSingleTimepoint(TP,channel));
        
        
        if chi==1
            %preallocate images for speed. DIMImage is stack rather than
            %single image.
            CCImage = zeros(size(TempIm));
            ACImage = CCImage;
            TrapRefineImage = CCImage;            
            DIMImage = zeros([size(TempIm) length(DecisionImageChannel)]);

        end
        
        % sum images into a single 2D image
        if ismember(channel,abs(ACImageChannel))
            ACImage = ACImage + sign(ACImageChannel(channel==abs(ACImageChannel))) * TempIm;
        end
        
        % sum images into a single 2D image
        if TrapPresentBoolean &&    ismember(channel,abs(TrapRefineChannel))
            TrapRefineImage = TrapRefineImage + sign(TrapRefineChannel(channel==abs(TrapRefineChannel))) * TempIm;
        end
        
        % in this case images are stacked
        if ismember(channel,DecisionImageChannel)
            DIMImage(:,:,channel==DecisionImageChannel) = TempIm;
        end
    end
    
    ACImage = IMnormalise(ACImage);
    
    if TrapPresentBoolean
        %for holding trap images of trap pixels.
        TrapTrapImageStack = cTimelapse.returnTrapsFromImage(TrapRefineImage,TP,TrapsToCheck);
        TrapTrapImageStack = TrapRefineFunction(TrapTrapImageStack);
        
        % since this WholeTrapImage (a logical of all traps in the image)
        % is used for normalisation we don't want to use only the traps
        % being checked. So fill in unchecked traps with default outline
        % from cCellVision.
        DefaultTrapIndices = cTimelapse.defaultTrapIndices(TP);
        DefaultTrapImageStack = repmat(DefaultTrapOutline,[1,1,length(DefaultTrapIndices)]);
        for trapi = 1:length(TrapsToCheck)
            trap = TrapsToCheck(trapi);
            DefaultTrapImageStack(:,:,trap) = TrapTrapImageStack(:,:,trapi);
        end
        WholeTrapImage = cTimelapse.returnWholeTrapImage(DefaultTrapImageStack,TP,DefaultTrapIndices);
        
    else
        WholeTrapImage = zeros([size(CCImage,1), size(CCImage,2)]);
        TrapTrapImageStack = zeros([size(CCImage,1), size(CCImage,2),length(TrapsToCheck)]);
    end
    
    % normalise AC image by gradient at traps
    % seemed to produce the most consistent behaviour.
    TrapMask = WholeTrapImage>0;
    if any(TrapMask(:))
        [ACImageGradX,ACImageGradY] = gradient(ACImage);
        ACImage = ACImage/mean(sqrt(ACImageGradX(TrapMask).^2 + ACImageGradY(TrapMask).^2  ));
    end

    TrapLocations = cTimelapse.cTimepoint(TP).trapLocations;
    
    if TP>= TPtoStartSegmenting;
        
        %get decision image for each trap from SVM
        %If the traps have not been previously segmented this also initialises the trapInfo field
        
        TrapInfo = cTimelapse.cTimepoint(TP).trapInfo;

        % this calculates the decision image
        % though methods exist in the cellVision class to do this more
        % directly, it was pulled ou to avoid loading the image multiple
        % times if they are used for both active contour and decision
        % image.
        [ SegmentationStackArray ] = processSegmentationTrapStack( cTimelapse,DIMImage,TrapsToCheck,TP,cCellVision.imageProcessingMethod);
        
        DecisionImageStack = zeros(size(TrapTrapImageStack));
        EdgeImageStack = DecisionImageStack;
        RawBgDIM = DecisionImageStack;
        RawCentreDIM = DecisionImageStack;
        have_raw_dims = false(1,size(TrapTrapImageStack,3));
        %fprintf('change back to parfor in DIM calculation\n')
        parfor k=1:length(TrapsToCheck)
            [~, d_im_temp,~,raw_dims]=cCellVision.classifyImage2Stage(SegmentationStackArray{k},TrapTrapImageStack(:,:,k));
            DecisionImageStack(:,:,k)=d_im_temp(:,:,1);
            if size(d_im_temp,3)>1
                % Matt at some point started returning a second slice for
                % the decision image that was an edge probability. This
                % code doesn't use that, but I keep it here to be robust
                % against it.
                EdgeImageStack(:,:,k)=d_im_temp(:,:,2);
            end
            if ~isempty(raw_dims)
                have_raw_dims(k) = true;
                RawBgDIM(:,:,k) = raw_dims(:,:,1);
                RawCentreDIM(:,:,k) = raw_dims(:,:,2);
            end
        end
        have_raw_dims = all(have_raw_dims);
        
        % calculate log P 's for each pixel type
        % correcting trap pixels if the correction value is non nan
        if have_raw_dims
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
        
        % stored to add to forcing image later
        CrossCorrelating = false(size(TrapsToCheck));
        
        PredictedCellLocationsAllCells = cell(size(TrapsToCheck));
        
        reg_result = [0 0];
        
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
                
                
                % instantial the probable location image stack.
                PredictedCellLocationsAllCells{TI} = -2*abs(CrossCorrelationValueThreshold)*ones(TrapImageSize(1),TrapImageSize(2),length(PreviousCurrentTrapInfo.cell));
                
                for CI = 1:length(PreviousCurrentTrapInfo.cell)
                    
                    %ugly piece of code. If a cells is added by hand (not
                    %by this program) it may not have a cell label. This if
                    %statement is suppose to give it a cellLabel and
                    %thereby prevent errors down the line.
                    if CI>length(PreviousCurrentTrapInfo.cellLabel)
                        cTimelapse.cTimepoint(TP).trapInfo(trap).cellLabel(CI) = cTimelapse.returnMaxCellLabel(trap)+1;
                    end
                    
                    % further in the program the previous cell location was
                    % enriched
                    if isfield(PreviousCurrentTrapInfo.cell(CI),'ExpectedCentre')
                        ExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).ExpectedCentre;
                    else
                        ExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).cellCenter;
                    end
                    
                    if PerformRegistration
                        ExpectedCellCentre = ExpectedCellCentre - reg_result;
                        % botch fix for error over Exzpected centre being out of
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
                    
                    % get the predicted location but shifted so it fits
                    % so that it lines up with the trap image
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
            
            if TrapPresentBoolean

                TrapTrapImage = TrapTrapImageStack(:,:,TI);
                
                TrapTrapLogical = TrapTrapImage > TrapPixExcludeThreshCentre;
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
        
        %begin prep for parallelised slow section
        
        SliceableTrapInfo = TrapInfo(TrapsToCheck);
        SliceableTrapInfoToWrite = SliceableTrapInfo;
        if TP>FirstTimepoint
            SliceablePreviousTrapInfo = PreviousTrapInfo(TrapsToCheck);
        else
            SliceablePreviousTrapInfo = ones(size(CrossCorrelating));
        end
        
        SliceableTrapLocations = TrapLocations(TrapsToCheck);
        SliceableTrapMaxCell = TrapMaxCell(TrapsToCheck);
        
        if TrapPresentBoolean
            ACTrapImageStack = ACBackGroundFunctions.get_cell_image(ACImage,...
                TrapImageSize,...
                [[SliceableTrapLocations(:).xcenter]' [SliceableTrapLocations(:).ycenter]']);
            
        else
            ACTrapImageStack = ACImage;
        end

        cells_discarded = 0;
        cells_found = 0;
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
                %%%%%%%%%%%%%%% PARALLLEL LOOP %%%%%%%%%%%%%%% 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        
        
        
        
        
        %parfor actually looking for cells
        %fprintf('CHANGE BACK TO PARFOR IN %s.%s\n',class(cTimelapse),mfilename)
        parfor TI = 1:length(TrapsToCheck)
            
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
            
            NotCells = TrapTrapLogical;
            AllCellPixels = zeros(size(NotCells));
            
            ACTrapImage = ACTrapImageStack(:,:,TI);
            
            CellSearch = true;
            ProceedWithCell = false;
            NCI = 0;
            NewCells = [];
            OldCells = [];
            NewCrossCorrelatedCells = [];
            ParCurrentTrapInfo.cell = NewCellStruct;
            ParCurrentTrapInfo.cellsPresent = false;
            ParCurrentTrapInfo.cellLabel = [];
            value = 0;
            ynewcell = 0;
            xnewcell = 0;
            CellTrapImage = [];
            CIpar = [];
            
            % for visualising if debugging code
            TransformedImagesVISTrap = [];
            OutlinesVISTrap = [];
            CellStatsDebugTrap = [];

            
            %look for new cells
            while CellSearch
                
                if CrossCorrelating(TI)
                    %look for cells based on cross correlation with
                    %previous timepoint
                    [value,Index] = max(PredictedCellLocationsAllCells{TI}(:));
                    %[Index] = find(PredictedCellLocationsAllCells{TI}==value,1);
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
                    value = min(TrapDecisionImage(:));
                    [Index] = find(TrapDecisionImage==value,1);
                    if value<TwoStageThreshold
                        [ynewcell,xnewcell] = ind2sub(size(TrapDecisionImage),Index);
                        ProceedWithCell = true;
                    else
                        CellSearch = false;
                        ProceedWithCell = false;
                    end
                    
                    
                end
                
                if ProceedWithCell
                    %do active contour
                    
                    NewCellCentre = [xnewcell ynewcell];
                    
                    
                    CellImage = ACBackGroundFunctions.get_cell_image(ACTrapImage,...
                        SubImageSize,...
                        NewCellCentre );
                    
                    NotCellsCell = ACBackGroundFunctions.get_cell_image(AllCellPixels,...
                        SubImageSize,...
                        [xnewcell ynewcell],...
                        false);
                    
                    
                    if TrapPresentBoolean
                        CellTrapImage = ACBackGroundFunctions.get_cell_image(TrapTrapImage,...
                                                                             SubImageSize, ...
                                                                             NewCellCentre );
                        
                        
                        if have_raw_dims
                            PCentreCell = ACBackGroundFunctions.get_cell_image(PCentreTrap,SubImageSize,NewCellCentre );
                            PEdgeCell = ACBackGroundFunctions.get_cell_image(PEdgeTrap,SubImageSize,NewCellCentre );
                            PBGCell = ACBackGroundFunctions.get_cell_image(PBGTrap,SubImageSize,NewCellCentre );
                            
                            
                            TransformedCellImage = -PEdgeCell + log(1-exp(PEdgeCell));%  ImageTransformFunction(PEdgeCell,TransformParameters,CellTrapImage) - PEdgeCell;%  TransformFromDIMS(PCentreCell,PEdgeCell,PBGCell);
                            %CellRegionImage = zeros(size(TransformedCellImage));
                            CellRegionImage = log(1-exp(PCentreCell))-PCentreCell;% - PCentreCell;%log(1-exp(PCentreCell)) - PCentreCell;%   ones(size(PEdgeCell));%  log(1-exp(PCentreCell));%PBGCell;% log( exp(-PBGCell) +  exp(-PEdgeCell)) ;
                        else
                            %TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters,CellTrapImage+NotCellsCell);
                            CellDecisionImage = ACBackGroundFunctions.get_cell_image(TrapDecisionImage,...
                        SubImageSize,...
                        NewCellCentre );
                            
                            TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters,CellTrapImage);
                            %TransformedCellImage = zeros(size(SubImageSize));
                            TransformedCellImage = TransformedCellImage - median(TransformedCellImage(:));
                            %CellRegionImage =CellDecisionImage;
                            CellRegionImage = zeros(size(TransformedCellImage));
                        end
                    else
                        %TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters,NotCellsCell);
                        TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters);
                        TransformedCellImage = TransformedCellImage - median(TransformedCellImage(:));
                        CellRegionImage = zeros(size(TransformedCellImage));
                    end
                    
                    %COME BACK TO LATER. NEED TO DO THE TRAP REMOVAL AGAIN
                    %FOR THIS TO WORK
                    %%%%%%  cheeky little temporary addition - add a
                    %%%%%%  proportion of the cell image to the transformed
                    %%%%%%  image.
                    
                    
                    
                    %take cell decision image, isolate those parts which
                    %are above TwoStageThreshold(and therefore a partof
                    %cell centres) and add it to the TransformedCellImage,
                    %multiplying by the 75th percentile of the
                    %TransformedCellImage for scaling.
                    
                    %TransformedCellImage = TransformedCellImage + DIMproportion*(CellDecisionImage*iqr(TransformedCellImage(:)));
                    %%%%
                    
                    if TrapPresentBoolean
                        %ExcludeLogical = (CellTrapImage>=TrapPixExcludeThreshAC) | (NotCellsCell>=CellPixExcludeThresh);
                        ExcludeLogical = (imerode(CellTrapImage>=TrapPixExcludeThreshAC,strel('disk',3),'same')| (NotCellsCell>=CellPixExcludeThresh));
                    else
                        ExcludeLogical = NotCellsCell>=CellPixExcludeThresh;
                    end
                    
                    if ~any(ExcludeLogical(:))
                        ExcludeLogical = [];
                    end
                    
                    if CrossCorrelating(TI)
                        PreviousTimepointRadii = PreviousCurrentTrapInfoPar.cell(CIpar).cellRadii;
                        
                        [RadiiResult,AnglesResult,ACscore] = ...
                            ACMethods.PSORadialTimeStack(TransformedCellImage,ACparametersPass,FauxCentersStack,PreviousTimepointRadii,PreviousTimepointRadii,ExcludeLogical,CellRegionImage);
                    else
                        [RadiiResult,AnglesResult,ACscore] = ...
                            ACMethods.PSORadialTimeStack(TransformedCellImage,ACparametersPassFirstFind,FauxCentersStack,[],[],ExcludeLogical,CellRegionImage);
                        
                    end
                    
                    if Recentering
                        %somewhat crude, hope that it will keep cells
                        %reasonably centred.
                        [px,py] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult',AnglesResult',double([xnewcell ynewcell]),TrapImageSize);
                        
                        xnewcell = round(mean(px));
                        ynewcell = round(mean(py));
                        
                        SegmentationBinary = false(TrapImageSize);
                        SegmentationBinary(py+TrapImageSize(1,1)*(px-1))=true;

                        RadiiResult = ACBackGroundFunctions.initialise_snake_radial(1*(~imfill(SegmentationBinary,[ynewcell xnewcell])),OptPoints,xnewcell,ynewcell,ACparameters.R_min,ACparameters.R_max,[]);
                        RadiiResult = RadiiResult';
                        
                    end
                    
                    % check tracked cell meets criteria of shape change
                    if CrossCorrelating(TI)
                        reordered_radii = ACBackGroundFunctions.reorder_radii(cat(1,PreviousTimepointRadii,RadiiResult));
                        reordered_radii_norm = log(reordered_radii(2,:)./reordered_radii(1,:));
                        reordered_radii_1cell = reordered_radii(2,:);
                        
                        % TODO = switch this off and make it just
                        % probability, not the bayes factor
                        % also, adjust probability threshold accordingly.
                        %calculate radii contribution (bayes factor of new and old cell for the found radii)
                        if mean(PreviousTimepointRadii)<threshold_radius;
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
                            %cells_discarded = cells_discarded+1;
                            continue
                        end
                    else
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
                    
                    %write new cell info
                    
                    cells_found = cells_found+1;
                    NCI = NCI+1;
                    
                    ParCurrentTrapInfo.cell(NCI) = NewCellStruct;
                    
                    if CrossCorrelating(TI)
                        ParCurrentTrapInfo.cellLabel(NCI) = PreviousCurrentTrapInfoPar.cellLabel(CIpar);
                        OldCells = [OldCells CIpar];
                        NewCrossCorrelatedCells = [NewCrossCorrelatedCells NCI];
                    else
                        NewCells = [NewCells NCI];
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
                    
                    [px,py] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult',AnglesResult',double(ParCurrentTrapInfo.cell(NCI).cellCenter),TrapImageSize);
                    
                    if ACparameters.visualise>1
                        
                        TransformedImagesVISTrap = cat(3,TransformedImagesVISTrap,TransformedCellImage);
                        [pxVIS,pyVIS] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult',AnglesResult',round(size(TransformedCellImage)/2),size(TransformedCellImage));
                        SegmentationBinary = false(size(TransformedCellImage));
                        SegmentationBinary(pyVIS+size(TransformedCellImage,1)*(pxVIS-1))=true;
                        OutlinesVISTrap = cat(3,OutlinesVISTrap,SegmentationBinary);
                        CellStatsDebugTrap = cat(1,CellStatsDebugTrap,[ACscore p_score])
                        
                    end
                    
                    SegmentationBinary = false(TrapImageSize);
                    SegmentationBinary(py+TrapImageSize(1,1)*(px-1))=true;
                    
                    
                    ParCurrentTrapInfo.cell(NCI).segmented = sparse(SegmentationBinary);
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
                    %PCentreTrap(SegmentationBinary) =  median_PCentreTrap;
                    
                    %update trap image so that it includes all
                    %segmented cells
                    NotCells = NotCells | SegmentationBinary;
                    EdgeConfidenceImage = bwdist(~SegmentationBinary);
                    EdgeConfidenceImage = EdgeConfidenceImage./max(EdgeConfidenceImage(:));
                    AllCellPixels = AllCellPixels + EdgeConfidenceImage;
                    
                end %if ProceedWithCell
                
            end %while cell search
            
            if ACparameters.visualise>1
                
                OutlinesVIS{TI} = OutlinesVISTrap;
                TransformedImagesVIS{TI} = TransformedImagesVISTrap;
                CellStatsDebug{TI} = CellStatsDebugTrap;
                
            end
            
            %create this new variable for writing before adding superflous
            %rubbis to ParCurrenttrapInfo which is only used in
            %this function.
            SliceableTrapInfoToWrite(TI) = ParCurrentTrapInfo;
            
            %calculated expected CellCentre as the simple sum of current
            %location and distance moved in previous timepoint.
            %for new cells it is simply their current location
            for CI = 1:length(NewCrossCorrelatedCells);
                CellMove = (ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).cellCenter - PreviousCurrentTrapInfoPar.cell(OldCells(CI)).cellCenter);
                
                if PerformRegistration
                    % so as not to confuse jumps in registration (which
                    % will be added anyway) with cell specific movement.
                    CellMove = CellMove + reg_result;
                end
                if any(abs(CellMove)>4) || Recentering
                    %more than 4, probably a jump, cell movement not related to previous timepoint
                    %if recentering then cells jump around anyway.
                    CellMove = [0 0];
                end
                
                %didn't like cell move code anymore, temp fix
                
                CellMove = [0 0];
                
                %CellMove = sign(CellMove) .* min(abs(CellMove),[2 2]); %allow a predicted move of no more than two - stops crazy jumps
                ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre = ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).cellCenter + CellMove;
                if ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(1) > TrapImageSize(2);
                    ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(1) = TrapImageSize(2);
                elseif ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(1) < 1;
                    ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(1) = 1;
                end
                
                if ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(2) >TrapImageSize(1);
                    ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(2) = TrapImageSize(1);
                elseif ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(2) < 1;
                    ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(2) = 1;
                end
                
                %ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).TPpresent = PreviousCurrentTrapInfoPar.cell(OldCells(CI)).TPpresent+1;
                
            end
            
            for CI = 1:length(NewCells);
                ParCurrentTrapInfo.cell(NewCells(CI)).ExpectedCentre = ParCurrentTrapInfo.cell(NewCells(CI)).cellCenter;
                ParCurrentTrapInfo.cell(NewCells(CI)).TPpresent = 1;
            end
            
            
            
            
            
            %write results to internal variables
            SliceableTrapInfo(TI) = ParCurrentTrapInfo;
            
            
            TransformedCellImage = [];
            
        end %end traps loop
        fprintf('%d cells of %d discarded\n',cells_discarded,(cells_found+cells_discarded));
        
        TrapMaxCell(TrapsToCheck) = SliceableTrapMaxCell;
        
        %write results to cTimelapse
        cTimelapse.cTimepoint(TP).trapInfo(TrapsToCheck) = SliceableTrapInfoToWrite;
        cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapMaxCell = TrapMaxCell;
        cTimelapse.timepointsProcessed(TP) = true;
        
        TrapInfo(TrapsToCheck) = SliceableTrapInfo;
    else
        TrapInfo = cTimelapse.cTimepoint(TP).trapInfo;
        
        % initialise since these are used later.
        for TI = 1:length(TrapInfo)
            for CI = 1:length(TrapInfo(TI).cell);
                TrapInfo(TI).cell(CI).ExpectedCentre = TrapInfo(TI).cell(CI).cellCenter;
                TrapInfo(TI).cell(CI).TPpresent = 1;
            end
        end
    end
    
    switch CrossCorrelationMethod
        case 'new_elco'
            for trapi = TrapsToCheck
                
                %fix later - just need to get absolute cell locations
                
                AbsoluteCellCentres = cTimelapse.returnCellCentresAbsolute(trapi,TP);
                for CI = 1:size(AbsoluteCellCentres,1)
                    %this is a vector taken from the correlation image at the
                    %current timepoint which will hopefully be very similar for
                    %this same cells at the next timepoint.
                    TrapInfo(trapi).cell(CI).CorrelationVector = squeeze(WholeImageElcoHoughNormalised(AbsoluteCellCentres(CI,2),AbsoluteCellCentres(CI,1),:));
                end
            end
    end
    
    PreviousWholeImage = ACImage;
    PreviousTrapInfo = TrapInfo;
    
    TimeOfTimepoint = toc;
    fprintf('timepoint analysed in %.2f seconds \n',TimeOfTimepoint);
    
    set(disp.slider,'Value',TP);
    disp.slider_cb;
    if ACparameters.visualise>1 && TP>=TPtoStartSegmenting
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
        guiDI.LaunchGUI;
        guiTransformed.stack = TransformedImagesStack;
        guiTransformed.LaunchGUI;
        guiOutline.stack = OutlinesStack;
        guiOutline.LaunchGUI;
        guiTrapIM.stack = cTimelapse.returnTrapsTimepoint(TrapsToCheck,TP,cTimelapse.ACParams.ActiveContour.ShowChannel);
        guiTrapIM.LaunchGUI;
        for i=1:size(CellStats,1)
            
            fprintf('cell %d  score %3.3g  shape score %3.3g \n',i,CellStats(i,1),CellStats(i,2));
            
        end
        fprintf('press enter to continue . . . . \n')
        pause;
        
    end
    drawnow;
end %end TP loop

close(disp.figure);

end

function WholeImage = IMnormalise(WholeImage)

WholeImage = double(WholeImage);
WholeImage = WholeImage - median(WholeImage(:));
IQ = iqr(WholeImage(:));
if IQ>0
    WholeImage = WholeImage./iqr(WholeImage(:));
end

end

