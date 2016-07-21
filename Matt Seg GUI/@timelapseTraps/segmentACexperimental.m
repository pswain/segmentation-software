function segmentACexperimental(cTimelapse,cCellVision,FirstTimepoint,LastTimepoint,FixFirstTimePointBoolean,TrapsToUse)
%segmentACexperimental(cTimelapse,FirstTimepoint,LastTimepoint,FixFirstTimePointBoolean,CellsToUse)
%
%Complete segmentation function that uses the cCellVision and cross correlation to find images of
%cells and performs the active contour to get the edges.
%
%not yet parallelised
%
%   INPUTS
% FirstTimepoint    - time point at which to start
% LastTimepoint     - and to end
% FixFirstTimePoint - optional : if this is true the software will not alter the first timepoint
%                     but will still use the information in finding cells.
% CellsToUse        - optional (array) of type [trapIndex cellLabel]
%                     specifying which cells should be
%                     segmented. can also just be the
%                     column vector [trapIndex] - currently only this
%                     second form works.
%
%
%outline
%
% loop timepoints:
%     loop traps:
%         cross correlate all cells in trap at previous timepoint
%         loop:
%             get max above threshold
%             make that centre of that cell at the new timepoint
%             do active contour
%             set those pixels to -Inf in cross correlation
%         get d_im
%         set all cell and trap pixels to Inf
%         loop:
%             find max below two stage threshold
%             Set as centre
%             give new cell label and do active contour
%
% has cTimelapse referecences - remove later if necessary





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
SubImageSize = cTimelapse.ACParams.ImageSegmentation.SubImageSize;%61;

ProspectiveImageSize =cTimelapse.ACParams.CrossCorrelation.ProspectiveImageSize;% 81; %image which will be searched for next cell
CrossCorrelationChannel = cTimelapse.ACParams.CrossCorrelation.CrossCorrelationChannel; % 2; %cTimelapse.ACParams.ImageTransformation.channel;
CrossCorrelationValueThreshold = cTimelapse.ACParams.CrossCorrelation.CrossCorrelationValueThreshold; %0.5; % value normalised cross correlation must be above to consitute continuation of cell from previous timepoint
CrossCorrelationDIMthreshold = cTimelapse.ACParams.CrossCorrelation.CrossCorrelationDIMthreshold;%  -0.3; %decision image threshold above which cross correlated cells are not considered to be possible cells
PostCellIdentificationDilateValue = cTimelapse.ACParams.CrossCorrelation.PostCellIdentificationDilateValue;% 2; %dilation applied to the cell outline to rule out new cell centres


RadMeans = (cTimelapse.ACParams.ActiveContour.R_min:cTimelapse.ACParams.ActiveContour.R_max)';%(2:15)';
RadRanges = [RadMeans-0.5 RadMeans+0.5];

TwoStageThreshold = cTimelapse.ACParams.CrossCorrelation.twoStageThresh; % boundary in decision image for new cells negative is stricter, positive more lenient

TrapPixExcludeThreshCentre = cTimelapse.ACParams.CrossCorrelation.TrapPixExcludeThreshCentre;%0.5; %pixels which cannot be classified as centres
TrapPixExcludeThreshAC = cTimelapse.ACParams.ActiveContour.TrapPixExcludeThreshAC;% 1; %trap pixels which will not be allowed within active contour areas
CellPixExcludeThresh = cTimelapse.ACParams.ActiveContour.CellPixExcludeThresh; %0.8; %bwdist value of cell pixels which will not be allowed in the cell area (so inner (1-cellPixExcludeThresh) fraction will be ruled out of future other cell areas)

OptPoints = cTimelapse.ACParams.ActiveContour.opt_points;

% cross correlation prior constructed from two parts:
% a tight gaussian gaussian centered at the center spot (width JumpSize1)
% a broader gaussian constrained to not go beyond front of the cell (width JumpSize2, truncated at JumpSize1)


%object to provide priors for cell movement based on position and location.
%CrossCorrelationPriorObject = ACMotionPriorObjects.FlowInTrapTrained(cTimelapse,cCellVision);
CrossCorrelationPriorObject = ACMotionPriorObjects.FlowInTrap(cTimelapse,cCellVision);

PerformRegistration = cTimelapse.ACParams.CrossCorrelation.PerformRegistration;%true; %registers images and uses this to inform expected position. Useful in cases of big jumps like cycloheximide data sets.
MaxRegistration = cTimelapse.ACParams.CrossCorrelation.MaxRegistration;%50; %maximum allowed jump

if cTimelapse.trapsPresent
    PerformRegistration = false; %registration should be covered by tracking in the traps.
end

Recentering =true; %recalcluate the centre of the cells each time as the average ofthe outline


%multiplier od decision image added to Transformed image.
DIMproportion = 1;
%CrossCorrelationPrior = CrossCorrelationPrior./max(CrossCorrelationPrior(:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for trained cell trakcing rubbish

% for trained time change punishment
% gaussian parameters from paurs of curated cells.
inverted_cov_2cell_small =...
  [ 3.6850   -1.8042    0.6610    0.1756    0.5107   -0.0625   -1.2654   -0.4407   -0.5562   -0.8113   -0.4586   -0.0849
   -1.8042    7.0565   -2.3833    0.4243    0.6222   -2.1497    0.0148   -1.9660    0.9446   -0.1127   -0.5825    0.3210
    0.6610   -2.3833    5.4670   -1.1714    0.0939    0.8149   -0.3297    0.5652   -2.6783    0.0447    0.1496   -0.8001
    0.1756    0.4243   -1.1714    3.4690   -1.5093   -0.2491   -0.3079   -0.0859    0.5353   -1.3459    0.2008    0.0392
    0.5107    0.6222    0.0939   -1.5093    5.2771   -1.5584   -0.3473   -0.8205   -0.4417    0.3719   -2.5134    0.3101
   -0.0625   -2.1497    0.8149   -0.2491   -1.5584    4.8677   -0.1218    0.1100   -0.7309    0.0958    0.7098   -1.6012
   -1.2654    0.0148   -0.3297   -0.3079   -0.3473   -0.1218    1.7690   -0.3154    0.3806    0.6215    0.2986   -0.4786
   -0.4407   -1.9660    0.5652   -0.0859   -0.8205    0.1100   -0.3154    2.9549   -0.9365    0.3240    0.8932    0.1766
   -0.5562    0.9446   -2.6783    0.5353   -0.4417   -0.7309    0.3806   -0.9365    3.5456   -0.9408    0.3411    0.7558
   -0.8113   -0.1127    0.0447   -1.3459    0.3719    0.0958    0.6215    0.3240   -0.9408    2.8966   -1.2654    0.2338
   -0.4586   -0.5825    0.1496    0.2008   -2.5134    0.7098    0.2986    0.8932    0.3411   -1.2654    3.6476   -1.0149
   -0.0849    0.3210   -0.8001    0.0392    0.3101   -1.6012   -0.4786    0.1766    0.7558    0.2338   -1.0149    2.5496 ];
 

log_det_cov_2cell_small = log(det(inverted_cov_2cell_small));

inverted_cov_2cell_small_1cell = ...
   [2.4427   -2.0993    0.0641   -0.2104   -0.1239   -0.3314
   -2.0993    5.6055   -1.6940    0.4267    0.1990   -1.8805
    0.0641   -1.6940    3.2553   -1.0467   -0.1074    0.1925
   -0.2104    0.4267   -1.0467    2.7684   -1.6112   -0.0687
   -0.1239    0.1990   -0.1074   -1.6112    3.3484   -1.2699
   -0.3314   -1.8805    0.1925   -0.0687   -1.2699    3.6582];

log_det_cov_2cell_small_1cell = log(det(inverted_cov_2cell_small_1cell));


mu_2cell_small = ...
    [6.3255    5.5594    4.9345    4.7670    4.6263    4.7629    6.1710    5.5720    4.9830    4.9389    4.8321    5.0378];
 
inverted_cov_2cell_large =...
    [  2.3252   -1.0645    0.4999    0.4400    0.1024   -0.0282   -1.6182    0.2609   -0.3319   -0.8341   -0.0588    0.2063
       -1.0645    4.2161   -0.7572    0.2109    0.8579   -0.5746    0.2607   -2.1498    0.4998   -0.0011   -1.1088   -0.4927
        0.4999   -0.7572    4.1199   -1.1441   -0.0358    0.9840   -0.3555    0.1993   -2.8321    0.6279   -0.0271   -1.1231
        0.4400    0.2109   -1.1441    3.5522   -1.2739    0.4049   -0.4757   -0.1871    0.4126   -2.1332    0.4667   -0.2236
        0.1024    0.8579   -0.0358   -1.2739    3.6650   -0.9906   -0.1527   -0.8121   -0.0167    0.4856   -2.2233    0.3479
       -0.0282   -0.5746    0.9840    0.4049   -0.9906    4.1526    0.0211   -0.4100   -1.1563   -0.2920    0.5674   -2.3946
       -1.6182    0.2607   -0.3555   -0.4757   -0.1527    0.0211    1.9014   -0.4786    0.5093    0.7099    0.2932   -0.5466
        0.2609   -2.1498    0.1993   -0.1871   -0.8121   -0.4100   -0.4786    2.4660   -0.7676    0.2704    0.8639    0.8028
       -0.3319    0.4998   -2.8321    0.4126   -0.0167   -1.1563    0.5093   -0.7676    3.7467   -1.1574    0.3433    0.8806
       -0.8341   -0.0011    0.6279   -2.1332    0.4856   -0.2920    0.7099    0.2704   -1.1574    3.1400   -1.1870    0.4560
       -0.0588   -1.1088   -0.0271    0.4667   -2.2233    0.5674    0.2932    0.8639    0.3433   -1.1870    3.1958   -0.9830
        0.2063   -0.4927   -1.1231   -0.2236    0.3479   -2.3946   -0.5466    0.8028    0.8806    0.4560   -0.9830    3.1388 ];

log_det_cov_2cell_large = log(det(inverted_cov_2cell_large));

inverted_cov_2cell_large_1cell = ...
   [0.9069   -0.9364    0.2096   -0.0909    0.0602   -0.1900
   -0.9364    2.2819   -0.6710    0.1747   -0.0614   -0.8289
    0.2096   -0.6710    1.8512   -0.9688    0.0582   -0.2163
   -0.0909    0.1747   -0.9688    1.9795   -1.1770    0.2309
    0.0602   -0.0614    0.0582   -1.1770    2.0198   -0.8258
   -0.1900   -0.8289   -0.2163    0.2309   -0.8258    2.1950];

log_det_cov_2cell_large_1cell = log(det(inverted_cov_2cell_large_1cell));
    
mu_2cell_large = ...
    [9.3514    8.0165    6.8417    6.5490    6.4683    6.9211    9.3151    8.0440    6.8029    6.4617    6.4043    7.0368];

threshold_radius = 6;

% selected rather arbitrarily from histogram of trained values.
threshold_probability = 2e-30;

%throw away cells with a score higher than this.
threshold_score = -5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%for debugging
%CrossCorrelationPrior = ones(ProspectiveImageSize,ProspectiveImageSize);

%variable assignments,mostly for convenience and parallelising.
TrapPresentBoolean = cTimelapse.trapsPresent;
TransformParameters = cTimelapse.ACParams.ImageTransformation.TransformParameters;
TrapImageSize = cTimelapse.trapImSize;

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
PreviousTrapLocations = [];
PreviousTrapInfo = [];


%visualising trackin

if cTimelapse.ACParams.ActiveContour.visualise>2;
    cc_gui = GenericStackViewingGUI;
end


%array to hold the maximum label used in each trap
if TPtoStartSegmenting == cTimelapse.timepointsToProcess(1)
    TrapMaxCell = zeros(1,length(cTimelapse.defaultTrapIndices));
else
    TrapMaxCell = cTimelapse.returnMaxCellLabel([],1:(TPtoStartSegmenting-1));
end


disp = cTrapDisplay(cTimelapse,[],[],cTimelapse.ACParams.ActiveContour.ShowChannel,TrapsToCheck);

% gui\s for visualising outputs if that is desired.
if ACparameters.visualise>1
    guiDI = GenericStackViewingGUI;
    guiTransformed = GenericStackViewingGUI;
    guiOutline = GenericStackViewingGUI;
    guiTrapIM = GenericStackViewingGUI;
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

TrapRefineChannel = cTimelapse.ACParams.TrapDetection.channel;
TrapRefineFunction =  str2func(['ACTrapFunctions.' cTimelapse.ACParams.TrapDetection.function]);
TrapRefineParameters = cTimelapse.ACParams.TrapDetection.functionParams;
if isempty(TrapRefineParameters.starting_trap_outline);
    TrapRefineParameters.starting_trap_outline = cCellVision.cTrap.trapOutline;
end
TrapRefineFunction = @(stack) TrapRefineFunction(stack,TrapRefineParameters);

CrossCorrelationMethod = 'just_DIM';
                    

%% loop through timepoints
for TP = Timepoints
    tic;
    fprintf('timepoint %d \n',TP)
    
    AllChannelsToLoad = unique(abs([CrossCorrelationChannel ACImageChannel TrapRefineChannel DecisionImageChannel]));
    
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
            ImageSize = size(TempIm);

        end
        
        if ismember(channel,abs(CrossCorrelationChannel))
            CCImage = CCImage + sign(CrossCorrelationChannel(channel==abs(CrossCorrelationChannel))) * TempIm;    
        end
        
        if ismember(channel,abs(ACImageChannel))
            ACImage = ACImage + sign(ACImageChannel(channel==abs(ACImageChannel))) * TempIm;
        end
        
        if ismember(channel,abs(TrapRefineChannel))
            TrapRefineImage = TrapRefineImage + sign(TrapRefineChannel(channel==abs(TrapRefineChannel))) * TempIm;
        end
        
        if ismember(channel,DecisionImageChannel)
            DIMImage(:,:,channel==DecisionImageChannel) = TempIm;
        end
    end
    
    ACImage = IMnormalise(ACImage);
    
    CCImage = IMnormalise(CCImage);
    
    if TrapPresentBoolean
        %for holding trap images of trap pixels.
        TrapTrapImageStack = cTimelapse.returnTrapsFromImage(TrapRefineImage,TP,TrapsToCheck);
        TrapTrapImageStack = TrapRefineFunction(TrapTrapImageStack);
    else
        WholeTrapImage = zeros([size(CCImage,1) size(CCImage,2)]);
    end

    TrapLocations = cTimelapse.cTimepoint(TP).trapLocations;
    
    switch CrossCorrelationMethod
        case 'new_elco'
            %Elco - currently unused but left in since I might come back to it.
            if TrapPresentBoolean
                [~,WholeImageElcoHough] = ElcoImageFilter(WholeImage,RadRanges,CrossCorrelationGradThresh,-1,WholeTrapImage>CrossCorrelationTrapThreshold,false);
            else
                [~,WholeImageElcoHough] = ElcoImageFilter(WholeImage,RadRanges,CrossCorrelationGradThresh,-1,[],false);
            end
            WholeImageElcoHoughSum = sqrt(sum(WholeImageElcoHough.^2,3));
            WholeImageElcoHoughSum(WholeImageElcoHoughSum==0) = 1;
            WholeImageElcoHoughNormalised = WholeImageElcoHough./repmat(WholeImageElcoHoughSum,[1 1 size(WholeImageElcoHough,3)]);
            
            WholeImageElcoHoughMedians = zeros(1,size(WholeImageElcoHough,3));
            
            for slicei = 1:size(WholeImageElcoHough,3)
                tempIm = WholeImageElcoHough(:,:,slicei);
                WholeImageElcoHoughMedians(slicei) = median(tempIm(:));
            end
            
    end
    if TP>= TPtoStartSegmenting;
        
        %get decision image for each trap from SVM
        %If the traps have not been previously segmented this also initialises the trapInfo field
        
        TrapInfo = cTimelapse.cTimepoint(TP).trapInfo;

        % this calculates the decision image
        
        [ SegmentationStackArray ] = processSegmentationTrapStack( cTimelapse,DIMImage,TrapsToCheck,TP,cCellVision.imageProcessingMethod);
        
        DecisionImageStack = zeros(size(TrapTrapImageStack));
        EdgeImageStack = DecisionImageStack;
        
        parfor k=1:length(TrapsToCheck)
            [~, d_im_temp]=cCellVision.classifyImage2Stage(SegmentationStackArray{k},TrapTrapImageStack(:,:,k));
            DecisionImageStack(:,:,k)=d_im_temp(:,:,1);
            if size(d_im_temp,3)>1
                EdgeImageStack(:,:,k)=d_im_temp(:,:,2);
            end
        end
        
        TransformedImagesVIS = cell(length(TrapInfo));
        OutlinesVIS = TransformedImagesVIS;
        CellStatsDebug = TransformedImagesVIS;
        if ACparameters.visualise>1
            DecisionImageStackVIS = DecisionImageStack;
        end
        
        % stored to add to forcing image later
        NormalisedDecisionImageStack = DecisionImageStack/iqr(DecisionImageStack(:));

        CrossCorrelating = false(size(TrapsToCheck));
        
        PredictedCellLocationsAllCells = cell(size(TrapsToCheck));
        
        reg_result = [0 0];
        
        for TI = 1:length(TrapsToCheck)
            %fprintf('%d,trap\n',TI)
            trap = TrapsToCheck(TI);
            CurrentTrapInfo = TrapInfo(trap);
            TrapDecisionImage = DecisionImageStack(:,:,TI);
            
            %             %might need to do something about this
            %             if isempty(CurrentTrapInfo)
            %             end
            if TP>FirstTimepoint
                PreviousCurrentTrapInfo = PreviousTrapInfo(trap);
            end
            
            if TP>FirstTimepoint && (PreviousCurrentTrapInfo.cellsPresent) && ~isinf(CrossCorrelationValueThreshold) && ~isempty(PreviousCurrentTrapInfo.cell(1).cellCenter)
                
                %register images and use to inform expeted position
                if PerformRegistration
                    reg_result = FindRegistrationForImageStack(cat(3,PreviousWholeImage,CCImage),1,MaxRegistration);
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
                
                
                PredictedCellLocationsAllCells{TI} = -2*abs(CrossCorrelationValueThreshold)*ones(TrapImageSize(1),TrapImageSize(2),length(PreviousCurrentTrapInfo.cell));
                if TI==1 && cTimelapse.ACParams.ActiveContour.visualise>2;
                    cc_gui.stack = cat(3,WholeImageElcoHough,CCImage);
                    cc_gui.LaunchGUI;
                    pause
                end
                
                %fprintf('minimum of decision image : %f\n',min(TrapDecisionImage(:)));
                ExpectedCellCentres = [];
                for CI = 1:length(PreviousCurrentTrapInfo.cell)
                    
                    %ugly piece of code. If a cells is added by hand (not
                    %by this program) it has no cell label. This if
                    %statement is suppose to give it a cellLabel and
                    %thereby prevent errors down the line. Hasto adjust the
                    %trapMaxTP fields, which may cause problems.
                    if CI>length(PreviousCurrentTrapInfo.cellLabel)
                        cTimelapse.cTimepoint(TP).trapInfo(trap).cellLabel(CI) = cTimelapse.returnMaxCellLabel(trap)+1;
                        cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapMaxCell(trap) = cTimelapse.returnMaxCellLabel(trap);
                    end
                    
                    if isfield(PreviousCurrentTrapInfo.cell(CI),'ExpectedCentre')
                        LocalExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).ExpectedCentre;
                    else
                        LocalExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).cellCenter;
                    end
                    
                    if PerformRegistration
                        LocalExpectedCellCentre = LocalExpectedCellCentre - reg_result;
                    end
                    
                    if TrapPresentBoolean
                        ExpectedCellCentre = double(LocalExpectedCellCentre) + double([TrapLocations(trap).xcenter TrapLocations(trap).ycenter] - ([TrapWidth TrapHeight] + 1)) ;
                    else
                        ExpectedCellCentre = LocalExpectedCellCentre;
                    end
                    
                    %botch fix for error over Exzpected centre being out of
                    %range
                    if ExpectedCellCentre(1)>ImageSize(2);%ttacObject.ImageSize(1)
                        ExpectedCellCentre(1) = ImageSize(2);%ttacObject.ImageSize(1);
                    end
                    
                    if ExpectedCellCentre(1)<1;
                        ExpectedCellCentre(1) = 1;
                    end
                    
                    if ExpectedCellCentre(2)>ImageSize(1);%ttacObject.ImageSize(2)
                        ExpectedCellCentre(2) = ImageSize(1);%ttacObject.ImageSize(2);
                    end
                    
                    if ExpectedCellCentre(2)<1;
                        ExpectedCellCentre(2) = 1;
                    end
                    
                    if ~isfield(PreviousCurrentTrapInfo.cell(CI),'cellRadii')
                        CellRadii = PreviousCurrentTrapInfo.cell(CI).cellRadius;
                    else
                        CellRadii = PreviousCurrentTrapInfo.cell(CI).cellRadii;
                    end
                    
                    
                    PredictedCellLocation = zeros(ProspectiveImageSize,ProspectiveImageSize);
                    
                    
                    switch CrossCorrelationMethod
                        case 'just_DIM'
                            %decision image is negative where cells are
                            %likely to be, so take the negative.
                            PredictedCellLocation = -ACBackGroundFunctions.get_cell_image(TrapDecisionImage,...
                                ProspectiveImageSize,...
                                LocalExpectedCellCentre,...
                                Inf);
                        case 'new_elco'
                            CellCorrelationVector = PreviousCurrentTrapInfo.cell(CI).CorrelationVector;
                    
                            ProspectiveImageHoughStack = GetSubStack(WholeImageElcoHoughNormalised,...
                                round(fliplr(ExpectedCellCentre)),...
                                ProspectiveImageSize*[1 1 ]);
                            ProspectiveImageHoughStack = ProspectiveImageHoughStack{1};
                            
                            ReshapedProspectiveImageHoughStack = reshape(shiftdim(ProspectiveImageHoughStack,2),[size(ProspectiveImageHoughStack,3),(numel(ProspectiveImageHoughStack)/size(ProspectiveImageHoughStack,3))]);
                            PredictedCellLocation = reshape(CellCorrelationVector'*ReshapedProspectiveImageHoughStack,[size(ProspectiveImageHoughStack,1) size(ProspectiveImageHoughStack,2)]);
                            
                            
                        case 'old elco'
                            for CellRadius = CellRadii
                                [~,BestFit] = sort(abs(RadMeans-CellRadius),1,'ascend');
                                BestFit = BestFit(1)';%BestFit = BestFit(1:2)';
                                for BestFiti = BestFit
                                    PredictedCellLocation = PredictedCellLocation + ACBackGroundFunctions.get_cell_image(WholeImageElcoHough(:,:,BestFiti),...
                                        ProspectiveImageSize,...
                                        ExpectedCellCentre,...
                                        WholeImageElcoHoughMedians(BestFiti));
                                    %multiplication by Radmeans added because it seems like the
                                    %transformation procedure gave higher values for smaller radii - so
                                    %this should balance that.
                                end
                            end
                    end
                    
                    % apply 'movement prior' provided by MotionPrior oject
                    PredictedCellLocation = CrossCorrelationPriorObject.returnPrior(LocalExpectedCellCentre,mean(CellRadii)).*PredictedCellLocation;
                    
                    %this for loop might seem somewhat strange and
                    %unecessary, but it is to deal with the 'TrapImage'
                    %being the whole image and therefore not necessarily an
                    %odd number in size.
                    if TrapPresentBoolean
                        temp_im = ACBackGroundFunctions.get_cell_image(PredictedCellLocation,...
                            TrapImageSize,...
                            (ceil(ProspectiveImageSize/2)*[1 1] + ceil(fliplr(TrapImageSize)/2)) - LocalExpectedCellCentre,...
                            -2*abs(CrossCorrelationValueThreshold) );
                        
                        % set those pixels above the more lenient decision
                        % image threshold to a value for which they will
                        % never be identified as cells.
                        temp_im(TrapDecisionImage>CrossCorrelationDIMthreshold)  = -2*abs(CrossCorrelationValueThreshold);
                        PredictedCellLocationsAllCells{TI}(:,:,CI) = temp_im;
                    else
                        
                        temp_im = (ACBackGroundFunctions.put_cell_image(PredictedCellLocationsAllCells{TI}(:,:,CI),PredictedCellLocation,ExpectedCellCentre)).*(TrapDecisionImage<CrossCorrelationDIMthreshold);
                        temp_im(TrapDecisionImage>CrossCorrelationDIMthreshold)  = -2*abs(CrossCorrelationValueThreshold);
                        PredictedCellLocationsAllCells{TI}(:,:,CI) = temp_im;
                    end
                    
                    
                    
                    %for debug
                    %ExpectedCellCentres = [ExpectedCellCentres;ExpectedCellCentre];
                    
                end
                
                
                %store image for visualisation
                if  cTimelapse.ACParams.ActiveContour.visualise > 0
                    PredictedCellLocationsAllCellsToView = PredictedCellLocationsAllCells{TI};
                    
                end
                
                if  cTimelapse.ACParams.ActiveContour.visualise>4;
                    cc_gui.stack = cat(3,PredictedCellLocationsAllCellsToView,TrapDecisionImage);
                    cc_gui.LaunchGUI;
                    pause
                    close(cc_gui.FigureHandle);
                end
                
                
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
        %parfor actually looking for cells
        %fprintf('CHANGE BACK TO PARFOR IN SegmentConsecutiveTimepointsCrossCorrelationParallel\n')
        cells_discarded = 0;
        cells_found = 0;
        parfor TI = 1:length(TrapsToCheck)
            
            PreviousCurrentTrapInfo = [];
            if CrossCorrelating(TI)
                PreviousCurrentTrapInfo = SliceablePreviousTrapInfo(TI);
            end
            
            TrapDecisionImage = DecisionImageStack(:,:,TI);
            NormalisedTrapDecisionImage = NormalisedDecisionImageStack(:,:,TI);
            TrapTrapImage = TrapTrapImageStack(:,:,TI);
            
            NormalisedTrapDecisionImage(TrapTrapImage>0) = TwoStageThreshold;
            
            NormalisedTrapDecisionImage = -NormalisedTrapDecisionImage;
            
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
            
            if  ACparameters.visualise >1
                TransformedImagesVISTrap = [];
                OutlinesVISTrap = [];
                CellStatsDebugTrap = [];
            end
            
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
                            SubImageSize,...
                            NewCellCentre );
                        %TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters,CellTrapImage+NotCellsCell);
                        TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters,CellTrapImage);
                        
                    else
                        %TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters,NotCellsCell);
                        TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters);
                    end
                    
                    %COME BACK TO LATER. NEED TO DO THE TRAP REMOVAL AGAIN
                    %FOR THIS TO WORK
                    %%%%%%  cheeky little temporary addition - add a
                    %%%%%%  proportion of the cell image to the transformed
                    %%%%%%  image.
                    
                    CellDecisionImage = ACBackGroundFunctions.get_cell_image(NormalisedTrapDecisionImage,...
                        SubImageSize,...
                        NewCellCentre );
                    
                    %take cell decision image, isolate those parts which
                    %are above TwoStageThreshold(and therefore a partof
                    %cell centres) and add it to the TransformedCellImage,
                    %multiplying by the 75th percentile of the
                    %TransformedCellImage for scaling.
                    
                    TransformedCellImage = TransformedCellImage + DIMproportion*(CellDecisionImage*iqr(TransformedCellImage(:)));
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
                        PreviousTimepointRadii = PreviousCurrentTrapInfo.cell(CIpar).cellRadii;
                        
                        [RadiiResult,AnglesResult,ACscore] = ...
                            ACMethods.PSORadialTimeStack(TransformedCellImage,ACparametersPass,FauxCentersStack,PreviousTimepointRadii,PreviousTimepointRadii,ExcludeLogical);
                    else
                        [RadiiResult,AnglesResult,ACscore] = ...
                            ACMethods.PSORadialTimeStack(TransformedCellImage,ACparametersPassFirstFind,FauxCentersStack,[],[],ExcludeLogical);
                        
                    end
                    
                    %fprintf('%f\n',ACscore);
                    
                    % check tracked cell meets criteria of shape change
                    if CrossCorrelating(TI)
                        reordered_radii = ACBackGroundFunctions.reorder_radii(cat(1,PreviousTimepointRadii,RadiiResult));
                        reordered_radii_list = [reordered_radii(1,:) reordered_radii(2,:)];
                        if mean(PreviousTimepointRadii)<threshold_radius;
                            p_score = -(reordered_radii_list - mu_2cell_small)*inverted_cov_2cell_small*((reordered_radii_list - mu_2cell_small)') - 0.5*log_det_cov_2cell_small...
                                + (reordered_radii_list(1:OptPoints) - mu_2cell_small(1:OptPoints))*inverted_cov_2cell_small_1cell*((reordered_radii_list(1:OptPoints) - mu_2cell_small(1:OptPoints))') + 0.5*log_det_cov_2cell_small_1cell;
                        else
                            p_score = -(reordered_radii_list - mu_2cell_large)*inverted_cov_2cell_large*((reordered_radii_list - mu_2cell_large)') - log_det_cov_2cell_large...
                                + (reordered_radii_list(1:OptPoints) - mu_2cell_large(1:OptPoints))*inverted_cov_2cell_large_1cell*((reordered_radii_list(1:OptPoints) - mu_2cell_large(1:OptPoints))') + 0.5*log_det_cov_2cell_large_1cell;
                        
                        end
                        
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
                        ParCurrentTrapInfo.cellLabel(NCI) = PreviousCurrentTrapInfo.cellLabel(CIpar);
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
                    
                    if Recentering
                        %somewhat crude, hope that it will keep cells
                        %reasonably centred.
                        [px,py] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult',AnglesResult',double(ParCurrentTrapInfo.cell(NCI).cellCenter),TrapImageSize);
                        
                        xnewcell = round(mean(px));
                        ynewcell = round(mean(py));
                        
                        ParCurrentTrapInfo.cell(NCI).cellCenter = double([xnewcell ynewcell]);
                        
                        SegmentationBinary = false(TrapImageSize);
                        SegmentationBinary(py+TrapImageSize(1,1)*(px-1))=true;
                        %SegmentationBinary = imfill(SegmentationBinary,'holes')
                        
                        RadiiResult = ACBackGroundFunctions.initialise_snake_radial(1*(~imfill(SegmentationBinary,[ynewcell xnewcell])),OptPoints,xnewcell,ynewcell,ACparameters.R_min,ACparameters.R_max,[]);
                        RadiiResult = RadiiResult';
                        
                        %debug
%                         NewSegmentationBinary = ACBackGroundFunctions.get_outline_from_radii(RadiiResult',AnglesResult',[xnewcell ynewcell],TrapImageSize);
%                         NewSegmentationBinary = imdilate(NewSegmentationBinary,ones(5),'same');
%                         if any(SegmentationBinary(:) & ~NewSegmentationBinary(:))
%                             fprintf('debug')
%                         end
                    end
                    
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
                    DilateSegmentationBinary = imdilate(SegmentationBinary,strel('disk',PostCellIdentificationDilateValue),'same');
                    
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
                    TrapDecisionImage(DilateSegmentationBinary) = 2*abs(TwoStageThreshold);
                    
                    
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
                CellMove = (ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).cellCenter - PreviousCurrentTrapInfo.cell(OldCells(CI)).cellCenter);
                
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
                
                %ParCurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).TPpresent = PreviousCurrentTrapInfo.cell(OldCells(CI)).TPpresent+1;
                
            end
            
            for CI = 1:length(NewCells);
                ParCurrentTrapInfo.cell(NewCells(CI)).ExpectedCentre = ParCurrentTrapInfo.cell(NewCells(CI)).cellCenter;
                ParCurrentTrapInfo.cell(NewCells(CI)).TPpresent = 1;
            end
            
            
            
            
            
            %write results to internal variables
            SliceableTrapInfo(TI) = ParCurrentTrapInfo;
            
            
            
            
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
    
    PreviousWholeImage = CCImage;
    PreviousTrapInfo = TrapInfo;
    
    TimeOfTimepoint = toc;
    fprintf('timepoint analysed in %.2f seconds \n',TimeOfTimepoint);
    
    disp.slider.Value = TP;
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
