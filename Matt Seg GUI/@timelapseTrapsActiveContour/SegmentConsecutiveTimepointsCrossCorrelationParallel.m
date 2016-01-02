function SegmentConsecutiveTimepointsCrossCorrelationParallel(ttacObject,FirstTimepoint,LastTimepoint,FixFirstTimePointBoolean,CellsToUse)
%SegmentConsecutiveTimepointsCrossCorrelation(ttacObject,FirstTimepoint,LastTimepoint,FixFirstTimePointBoolean,CellsToUse)
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




if nargin<4
    
    FixFirstTimePointBoolean = false;
    
end


ACparameters = ttacObject.Parameters.ActiveContour;
ITparameters = ttacObject.Parameters.ImageTransformation;
slice_size = 1;%slice of the timestack you look at in one go. Fixed to 1 since this makes most sense  for looking 1 timpoint into the future.
keepers = 1;%number of timpoints from that slice that you will keep (normally slice_size-1)
SubImageSize = ttacObject.Parameters.ImageSegmentation.SubImageSize;%61;
OptPoints = ttacObject.Parameters.ActiveContour.opt_points;%6;

ProspectiveImageSize =ttacObject.Parameters.CrossCorrelation.ProspectiveImageSize;% 81; %image which will be searched for next cell
CrossCorrelationChannel = ttacObject.Parameters.CrossCorrelation.CrossCorrelationChannel; % 2; %ttacObject.Parameters.ImageTransformation.channel;
CrossCorrelationTrapThreshold = ttacObject.Parameters.CrossCorrelation.CrossCorrelationTrapThreshold; % Inf;% %value of trap pixels above which they are excluded from cross correlation image and therefore do not contribute
CrossCorrelationValueThreshold = ttacObject.Parameters.CrossCorrelation.CrossCorrelationValueThreshold; %0.5; % value normalised cross correlation must be above to consitute continuation of cell from previous timepoint
CrossCorrelationDIMthreshold = ttacObject.Parameters.CrossCorrelation.CrossCorrelationDIMthreshold;%  -0.3; %decision image threshold above which cross correlated cells are not considered to be possible cells
PostCellIdentificationDilateValue = ttacObject.Parameters.CrossCorrelation.PostCellIdentificationDilateValue;% 2; %dilation applied to the cell outline to rule out new cell centres
CrossCorrelationGradThresh = ttacObject.Parameters.CrossCorrelation.CrossCorrelationGradThresh;% {25}; %used to find the bound the gradient necessary for an edge to be considered an edge


RadMeans = (ttacObject.Parameters.ActiveContour.R_min:ttacObject.Parameters.ActiveContour.R_max)';%(2:15)';
RadRanges = [RadMeans-0.5 RadMeans+0.5];

TwoStageThreshold = ttacObject.Parameters.CrossCorrelation.twoStageThresh; % boundary in decision image for new cells negative is stricter, positive more lenient

TrapPixExcludeThreshCentre = ttacObject.Parameters.CrossCorrelation.TrapPixExcludeThreshCentre;%0.5; %pixels which cannot be classified as centres
TrapPixExcludeThreshAC = ttacObject.Parameters.ActiveContour.TrapPixExcludeThreshAC;% 1; %trap pixels which will not be allowed within active contour areas
CellPixExcludeThresh = ttacObject.Parameters.ActiveContour.CellPixExcludeThresh; %0.8; %bwdist value of cell pixels which will not be allowed in the cell area (so inner (1-cellPixExcludeThresh) fraction will be ruled out of future other cell areas)

% cross correlation prior constructed from two parts: 
% a tight gaussian gaussian centered at the center spot (width JumpSize1)
% a broader gaussian constrained to not go beyond front of the cell (width JumpSize2, truncated at JumpSize1)

JumpSize1 = ttacObject.Parameters.CrossCorrelation.JumpSize1;% 2; distance cell moves under normal circumstances (pixels)
JumpSize2 = ttacObject.Parameters.CrossCorrelation.JumpSize2;% 15; distance a cell can move backwards (pixels) when it 'pops'
JumpWeight = ttacObject.Parameters.CrossCorrelation.JumpWeight;% 0.2; weight given to larger jump (raise of pops frequent).

CrossCorrelationPrior1 = fspecial('gaussian',ProspectiveImageSize,JumpSize1); %filter with which prospective image is multiplied to weigh centres close to expected stronger.

%DONT COMMIT = trial cross correlation prior change
% [CrossCorrelationPrior1,~] = ACBackGroundFunctions.radius_and_angle_matrix(ProspectiveImageSize*[1 1]);
% CrossCorrelationPrior1 = (1./(CrossCorrelationPrior1+20)).*(CrossCorrelationPrior1<=JumpSize1);
% CrossCorrelationPrior1(CrossCorrelationPrior1 == Inf) = 1;
% CrossCorrelationPrior1(CrossCorrelationPrior1~=0) = CrossCorrelationPrior1(CrossCorrelationPrior1~=0)+10;

CrossCorrelationPrior2 = 2*fspecial('gaussian',ProspectiveImageSize,JumpSize2);
[~,angle] = ACBackGroundFunctions.radius_and_angle_matrix([ProspectiveImageSize,ProspectiveImageSize]);
CrossCorrelationPrior2 = CrossCorrelationPrior2.*cos(angle);
CrossCorrelationPrior2(:,1:(floor(ProspectiveImageSize/2))) = 0;
CrossCorrelationPrior = max((1-JumpWeight)*CrossCorrelationPrior1/max(CrossCorrelationPrior1(:)),JumpWeight*CrossCorrelationPrior2/max(CrossCorrelationPrior2(:)));

PerformRegistration = ttacObject.Parameters.CrossCorrelation.PerformRegistration;%true; %registers images and uses this to inform expected position. Useful in cases of big jumps like cycloheximide data sets.
MaxRegistration = ttacObject.Parameters.CrossCorrelation.MaxRegistration;%50; %maximum allowed jump

if ttacObject.TrapPresentBoolean
    PerformRegistration = false; %registration should be covered by tracking in the traps.
end

Recentering = true; %recalcluate the centre of the cells each time as the average ofthe outline

min_filt_size = 3; %filter DIM by square of this size

f_dim = fspecial('disk',3);
%CrossCorrelationPrior = CrossCorrelationPrior./max(CrossCorrelationPrior(:));

%for debugging
%CrossCorrelationPrior = ones(ProspectiveImageSize,ProspectiveImageSize);

%variable assignments,mostly for convenience and parallelising.
ImageSize = ttacObject.ImageSize;
TrapPresentBoolean = ttacObject.TrapPresentBoolean;
TransformParameters = ttacObject.Parameters.ImageTransformation.TransformParameters;
TrapImageSize = ttacObject.TrapImageSize;

ImageTransformFunction = str2func(['ACImageTransformations.' ttacObject.Parameters.ImageTransformation.ImageTransformFunction]);

if ttacObject.TrapPresentBoolean
    TrapWidth = ttacObject.TimelapseTraps.cTrapSize.bb_width;
    TrapHeight = ttacObject.TimelapseTraps.cTrapSize.bb_height;
end

NewCellStruct = struct('cellCenter',[],...
                       'cellRadius',[],...
                       'segmented',sparse(false(ttacObject.TrapImageSize)),...
                       'crossCorrelationScore',[],...
                       'decisionImageScore',[],...
                       'cellRadii',[],...
                       'cellAngle',[]);


%protects program from super crashing out by opening and closing a million
%images.
if LastTimepoint-FirstTimepoint>50 %(matlabpool('size') ~= 0)
    
    ACparameters.visualise = 0;
end


%FauxCentersStack is just a filler for the PSO optimisation that takes centers
%(because in this code the centers are always at the centers of the image).
%Better to assign it here than every time in the loop.
FauxCentersStack = round(SubImageSize/2)*ones(slice_size,2);

Timepoints = FirstTimepoint:LastTimepoint;

ttacObject.CheckTimepointsValid(Timepoints)


%% set TP at which to start segmenting

% if the first timepoint is suppose to be fixed it should not be segmented,
% so segmenting should only happen at FirstTimepoint + slice_size, since
% this will be one timepoint after the condition that the slice is fully
% populated is met. Otherwise the segmentation will start at FirstTimepoint+slice_size - 1
% the first timepoint at which the slice is fully populated.
if FixFirstTimePointBoolean
    TPtoStartSegmenting = FirstTimepoint+slice_size;
else
    TPtoStartSegmenting = FirstTimepoint+slice_size - 1;
    
end

FirstDisplay = true;

PreviousWholeImage = [];
PreviousTrapLocations = [];
PreviousTrapInfo = [];


%visualising trackin
if ttacObject.Parameters.ActiveContour.visualise>0;
    dec_im_handle = figure;
    cc_im_handle = figure;
    outline_im_handle = figure;
end

if ttacObject.Parameters.ActiveContour.visualise>2;
    cc_gui = GenericStackViewingGUI;
end


 %array to hold the maximum label used in each trap
 if TPtoStartSegmenting == ttacObject.TimelapseTraps.timepointsToProcess(1)
     TrapMaxCell = zeros(1,length(ttacObject.TimelapseTraps.cTimepoint(TPtoStartSegmenting).trapLocations));
 else
     TrapMaxCell = ttacObject.TimelapseTraps.cTimepoint(TPtoStartSegmenting-1).trapMaxCellUTP;
 end
 
 if nargin<5|| isempty(CellsToUse)
     TrapsToCheck = ttacObject.TrapsToCheck(Timepoints(1));
 else
     TrapsToCheck = intersect(CellsToUse(:,1),ttacObject.TrapsToCheck(Timepoints(1)))';
 end
 
disp = cTrapDisplay(ttacObject.TimelapseTraps,[],[],ttacObject.Parameters.ActiveContour.ShowChannel,TrapsToCheck);

%% loop through the rest of the timepoints
for TP = Timepoints
    tic;
    fprintf('timepoint %d \n',TP)
    
    WholeImage = [];
    for chi = 1:length(CrossCorrelationChannel)
        if chi==1
            WholeImage =sign(CrossCorrelationChannel(chi)) * ttacObject.ReturnImage(TP,abs(CrossCorrelationChannel(chi)));
        else
            WholeImage = WholeImage  + sign(CrossCorrelationChannel(chi)) * ttacObject.ReturnImage(TP,abs(CrossCorrelationChannel(chi)));
            
        end
    end
    WholeImage = IMnormalise(WholeImage);
    
    if ttacObject.TrapPresentBoolean
        WholeTrapImage = ttacObject.ReturnTrapImage(TP);
    else
        WholeTrapImage = zeros(size(WholeImage));
    end
    
    ACImageChannel = ttacObject.Parameters.ImageTransformation.channel;
    
    for chi = 1:length(ACImageChannel)
        if chi==1
            ACImage =sign(ACImageChannel(chi)) * ttacObject.ReturnImage(TP,abs(ACImageChannel(chi)));
        else
            ACImage = ACImage  + sign(ACImageChannel(chi)) * ttacObject.ReturnImage(TP,abs(ACImageChannel(chi)));
            
        end
    end
    
    ACImage = IMnormalise(ACImage);
    
    TrapLocations = ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations;
    
    if ttacObject.TrapPresentBoolean
        [~,WholeImageElcoHough] = ElcoImageFilter(WholeImage,RadRanges,CrossCorrelationGradThresh,-1,WholeTrapImage>CrossCorrelationTrapThreshold,false);
    else
        [~,WholeImageElcoHough] = ElcoImageFilter(WholeImage,RadRanges,CrossCorrelationGradThresh,-1,[],false);
    end
    WholeImageElcoHoughSum = sqrt(sum(WholeImageElcoHough.^2,3));
    WholeImageElcoHoughSum(WholeImageElcoHoughSum==0) = 1;
    WholeImageElcoHoughNormalised = WholeImageElcoHough./repmat(WholeImageElcoHoughSum,[1 1 size(WholeImageElcoHough,3)]);
    
    if nargin<5|| isempty(CellsToUse)
        TrapsToCheck = ttacObject.TrapsToCheck(TP);
    else
        TrapsToCheck = intersect(CellsToUse(:,1),ttacObject.TrapsToCheck(TP))';
    end
    
    if TP>= TPtoStartSegmenting;
        
        %get decision image for each trap from SVM
        %If the traps have not been previously segmented this also initialises the trapInfo field
        
        %%%%%%%  SORT OUT NOW THAT CELLVISION STUFF HAS CHANGED
        % cCellVision.imageProcessingMethod
        if strcmp(ttacObject.cCellVision.method,'wholeIm')
            wholeImSegCh= ttacObject.TimelapseTraps.returnSegmenationTrapsStack(ttacObject.TrapsToCheck(TP),TP,'whole');
            DecisionImageStack = identifyCellCentersTrap(ttacObject.TimelapseTraps,ttacObject.cCellVision,TP,ttacObject.TrapsToCheck(TP),wholeImSegCh,[]);
            DecisionImageStack=ttacObject.TimelapseTraps.returnTrapsFromImage(DecisionImageStack,TP);
        else
            DecisionImageStack = identifyCellCentersTrap(ttacObject.TimelapseTraps,ttacObject.cCellVision,TP,ttacObject.TrapsToCheck(TP),[],[]);
        end
        TrapInfo = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo;
        
        %min filtering to try and get rid of spurious points. May not want
        %to leave this in. Addition of 1/1000 image stack is to break ties
        %later.
        %DecisionImageStack = minmaxfilt(DecisionImageStack,[min_filt_size min_filt_size 1],'min','same') + (DecisionImageStack/1000);
        DIM2 = imfilter(DecisionImageStack,f_dim,'same');
        DIM2(DecisionImageStack>CrossCorrelationDIMthreshold) = DecisionImageStack(DecisionImageStack>CrossCorrelationDIMthreshold);
        DecisionImageStack = DIM2;

        
        %for use later in subimage getting
        WholeImageElcoHoughMedians = zeros(1,size(WholeImageElcoHough,3));
        
        for slicei = 1:size(WholeImageElcoHough,3)
            tempIm = WholeImageElcoHough(:,:,slicei);
            WholeImageElcoHoughMedians(slicei) = median(tempIm(:));
        end
        
        CrossCorrelating = false(size(TrapsToCheck));
        
        PredictedCellLocationsAllCells = cell(size(TrapsToCheck));
        
        reg_result = [0 0];

        for TI = 1:length(TrapsToCheck)
            %fprintf('%d,trap\n',TI)
            CurrentTrapInfo = TrapInfo(TrapsToCheck(TI));
            TrapDecisionImage = DecisionImageStack(:,:,TrapsToCheck(TI));
            
            %             %might need to do something about this
            %             if isempty(CurrentTrapInfo)
            %             end
            if TP>FirstTimepoint
                PreviousCurrentTrapInfo = PreviousTrapInfo(TrapsToCheck(TI));
            end
            
            if TP>FirstTimepoint && (PreviousCurrentTrapInfo.cellsPresent) && ~isinf(CrossCorrelationValueThreshold) && ~isempty(PreviousCurrentTrapInfo.cell(1).cellCenter)
                
                %register images and use to inform expeted position
                if PerformRegistration
                    reg_result = FindRegistrationForImageStack(cat(3,PreviousWholeImage,WholeImage),1,MaxRegistration);
                    reg_result = fliplr(reg_result(2,:));
                    %fprintf('reg result: %d %d\n',reg_result(1),reg_result(2))
                    %this is no the shift required in the current image - 
                    % [x y] after fliplr - to make it match up with the
                    % Previous timepoint image, so is later subtracted from
                    % the expected position to get a better expected
                    % position estimate.
                else 
                    reg_result = [0 0];
                    %needs to be initialised for parpool
                end
                
                
                PredictedCellLocationsAllCells{TI} = -2*abs(CrossCorrelationValueThreshold)*ones(ttacObject.TrapImageSize(1),ttacObject.TrapImageSize(2),length(PreviousCurrentTrapInfo.cell));
                if ttacObject.Parameters.ActiveContour.visualise>2;
                    cc_gui.stack = cat(3,WholeImageElcoHough,WholeImage);
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
                        ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellLabel(CI) = ttacObject.TimelapseTraps.cTimepoint(1).trapMaxCell(TI)+1;
                        ttacObject.TimelapseTraps.cTimepoint(ttacObject.TimelapseTraps.timepointsToProcess(1)).trapMaxCell(TI) = ttacObject.TimelapseTraps.cTimepoint(ttacObject.TimelapseTraps.timepointsToProcess(1)).trapMaxCell(TI)+1;
                        for TPtemp = TP:ttacObject.TimelapseTraps.timepointsToProcess(end)
                            if isfield(ttacObject.TimelapseTraps.cTimepoint(TPtemp),'trapMaxCellUTP')
                            ttacObject.TimelapseTraps.cTimepoint(TPtemp).trapMaxCellUTP(TI) = ttacObject.TimelapseTraps.cTimepoint(ttacObject.TimelapseTraps.timepointsToProcess(1)).trapMaxCell(TI);
                            end
                        end
                    end
                    
                    if isfield(PreviousCurrentTrapInfo.cell(CI),'ExpectedCentre')
                        LocalExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).ExpectedCentre;
                    else
                        LocalExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).cellCenter;
                    end
                    
                    if PerformRegistration
                        LocalExpectedCellCentre = LocalExpectedCellCentre - reg_result;
                    end
                    
                    if ttacObject.TrapPresentBoolean
                    ExpectedCellCentre = LocalExpectedCellCentre + [TrapLocations(TrapsToCheck(TI)).xcenter TrapLocations(TrapsToCheck(TI)).ycenter] - ([TrapWidth TrapHeight] + 1) ;
                    else
                        ExpectedCellCentre = LocalExpectedCellCentre;
                    end
                    
                    %botch fix for error over Exzpected centre being out of
                    %range
                    if ExpectedCellCentre(1)>size(WholeImageElcoHough,2);%ttacObject.ImageSize(1)
                        ExpectedCellCentre(1) = size(WholeImageElcoHough,2);%ttacObject.ImageSize(1);
                    end
                    
                    if ExpectedCellCentre(1)<1;
                        ExpectedCellCentre(1) = 1;
                    end
                    
                    if ExpectedCellCentre(2)>size(WholeImageElcoHough,1);%ttacObject.ImageSize(2)
                        ExpectedCellCentre(2) = size(WholeImageElcoHough,1);%ttacObject.ImageSize(2);
                    end
                    
                    if ExpectedCellCentre(2)<1;
                        ExpectedCellCentre(2) = 1;
                    end
                    
                    if ~isfield(PreviousCurrentTrapInfo.cell(CI),'cellRadii')
                        CellRadii = PreviousCurrentTrapInfo.cell(CI).cellRadius;
                    else
                        CellRadii = PreviousCurrentTrapInfo.cell(CI).cellRadii;
                    end
                    
                    CellCorrelationVector = PreviousCurrentTrapInfo.cell(CI).CorrelationVector;
                    
                    PredictedCellLocation = zeros(ProspectiveImageSize,ProspectiveImageSize);
                    
                    CrossCorrelationMethod = 'new_elco';

                    switch CrossCorrelationMethod
                        case 'just_DIM'
                            PredictedCellLocation = -ACBackGroundFunctions.get_cell_image(TrapDecisionImage,...
                                ProspectiveImageSize,...
                                ExpectedCellCentre,...
                                Inf);
                        case 'new_elco'
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
                    PredictedCellLocation = CrossCorrelationPrior.*PredictedCellLocation;
                    
                    %this for loop might seem somewhat strange and
                    %unecessary, but it is to deal with the 'TrapImage'
                    %being the whole image and therefore not necessarily an
                    %odd number in size.
                    if ttacObject.TrapPresentBoolean
                        temp_im = ACBackGroundFunctions.get_cell_image(PredictedCellLocation,...
                            ttacObject.TrapImageSize,...
                            (ceil(ProspectiveImageSize/2)*[1 1] + ceil(fliplr(ttacObject.TrapImageSize)/2)) - LocalExpectedCellCentre,...
                            -2*abs(CrossCorrelationValueThreshold) );
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
                if ttacObject.Parameters.ActiveContour.visualise > 0
                    PredictedCellLocationsAllCellsToView = PredictedCellLocationsAllCells{TI};
                    
                end
                
                if ttacObject.Parameters.ActiveContour.visualise>2;
                    cc_gui.stack = cat(3,PredictedCellLocationsAllCellsToView,TrapDecisionImage);
                    cc_gui.LaunchGUI;
                    pause
                    close(cc_gui.FigureHandle);
                end
                
                
                CrossCorrelating(TI) = true;
            else
                CrossCorrelating(TI) = false;
                
            end %if timepoint> FirstTimepoint
            
            if ttacObject.TrapPresentBoolean
                TrapTrapImage = ACBackGroundFunctions.get_cell_image(WholeTrapImage,...
                    ttacObject.TrapImageSize,...
                    [TrapLocations(TrapsToCheck(TI)).xcenter TrapLocations(TrapsToCheck(TI)).ycenter],...
                    0 ) ;
                TrapTrapLogical = TrapTrapImage > TrapPixExcludeThreshCentre;
                if CrossCorrelating(TI)
                    PredictedCellLocationsAllCells{TI}(repmat(TrapTrapLogical,[1,1,size(PredictedCellLocationsAllCells{TI},3)])) = -2*abs(CrossCorrelationValueThreshold);
                    
                end
                TrapDecisionImage(TrapTrapLogical) = 2*abs(TwoStageThreshold);
                DecisionImageStack(:,:,TI) = TrapDecisionImage;
            else
                TrapTrapLogical = false(ttacObject.TrapImageSize);
                TrapTrapImage = zeros(ttacObject.TrapImageSize);
                
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
        
        if ttacObject.TrapPresentBoolean
        ACTrapImageStack = ACBackGroundFunctions.get_cell_image(ACImage,...
                                                                TrapImageSize,...
                                                                [[SliceableTrapLocations(:).xcenter]' [SliceableTrapLocations(:).ycenter]']);
        
        else
            ACTrapImageStack = ACImage;
        end
        %parfor actually looking for cells
        %fprintf('CHANGE BACK TO PARFOR IN SegmentConsecutiveTimepointsCrossCorrelationParallel\n')
        parfor TI = 1:length(TrapsToCheck)
        
        %for TI = 1:length(TrapsToCheck)
        %fprintf('lin 348 SegmentConsecutive....: make parallel again\n')
            
            TrapLocation = SliceableTrapLocations(TI);
            
            PreviousCurrentTrapInfo = [];
            if CrossCorrelating(TI)
                PreviousCurrentTrapInfo = SliceablePreviousTrapInfo(TI);
            end
            Trap = TrapsToCheck(TI);
            TrapDecisionImage = DecisionImageStack(:,:,Trap);
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
                    
                    NCI = NCI+1;
                    
                    %write new cell info
                    ParCurrentTrapInfo.cell(NCI) = NewCellStruct;

                    if CrossCorrelating(TI)
                        ParCurrentTrapInfo.cellLabel(NCI) = PreviousCurrentTrapInfo.cellLabel(CIpar);
                        OldCells = [OldCells CIpar];
                        NewCrossCorrelatedCells = [NewCrossCorrelatedCells NCI];
                        ParCurrentTrapInfo.cell(NCI).crossCorrelationScore = value;
                        ParCurrentTrapInfo.cell(NCI).decisionImageScore = NaN;
                    else
                        NewCells = [NewCells NCI];
                        ParCurrentTrapInfo.cellLabel(NCI) = SliceableTrapMaxCell(TI)+1;
                        SliceableTrapMaxCell(TI) = SliceableTrapMaxCell(TI)+1;
                        ParCurrentTrapInfo.cell(NCI).crossCorrelationScore = NaN;
                        ParCurrentTrapInfo.cell(NCI).decisionImageScore = value;
                    end
                    ParCurrentTrapInfo.cell(NCI).cellCenter = double([xnewcell ynewcell]);
                    ParCurrentTrapInfo.cellsPresent = true;
                    
                    
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
                        TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters,CellTrapImage+NotCellsCell);
                        
                    else
                        TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters,NotCellsCell);
                    end
                    
                    if TrapPresentBoolean
                        ExcludeLogical = (CellTrapImage>=TrapPixExcludeThreshAC) | (NotCellsCell>=CellPixExcludeThresh);
                    else
                        ExcludeLogical = NotCellsCell>=CellPixExcludeThresh;
                    end
                    
                    if ~any(ExcludeLogical(:))
                        ExcludeLogical = [];
                    end
                    
                    if CrossCorrelating(TI)
                        PreviousTimepointRadii = PreviousCurrentTrapInfo.cell(CIpar).cellRadii;
                    
                    [RadiiResult,AnglesResult] = ...
                        ACMethods.PSORadialTimeStack(TransformedCellImage,ACparameters,FauxCentersStack,PreviousTimepointRadii,PreviousTimepointRadii,ExcludeLogical);
                    else
                        [RadiiResult,AnglesResult] = ...
                        ACMethods.PSORadialTimeStack(TransformedCellImage,ACparameters,FauxCentersStack,[],[],ExcludeLogical);
                    
                    end
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
                        
                        RadiiResult = ACBackGroundFunctions.initialise_snake_radial(1*(~SegmentationBinary),OptPoints,xnewcell,ynewcell,ACparameters.R_min,ACparameters.R_max,[]);
                        RadiiResult = RadiiResult';
                    end
                    
                    ParCurrentTrapInfo.cell(NCI).cellRadii = RadiiResult;
                    ParCurrentTrapInfo.cell(NCI).cellAngle = AnglesResult;
                    ParCurrentTrapInfo.cell(NCI).cellRadius = mean(RadiiResult);
                    
                    [px,py] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult',AnglesResult',double(ParCurrentTrapInfo.cell(NCI).cellCenter),TrapImageSize);
                    
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
                        pixels_to_remove = find(DilateSegmentationBinary);
                        all_pixels_to_remove = kron(ones(1,size(PredictedCellLocationsAllCells{TI},3)),pixels_to_remove') + kron(((0:(size(PredictedCellLocationsAllCells{TI},3)-1))*size(PredictedCellLocationsAllCells{TI},1)*size(PredictedCellLocationsAllCells{TI},2)),ones(1,length(pixels_to_remove)));
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
                
            end
            
            for CI = 1:length(NewCells);
                ParCurrentTrapInfo.cell(NewCells(CI)).ExpectedCentre = ParCurrentTrapInfo.cell(NewCells(CI)).cellCenter;
            end
            

            
            
            
            %write results to internal variables
            SliceableTrapInfo(TI) = ParCurrentTrapInfo;
           
            
            
            
        end %end traps loop
        
        
        TrapMaxCell(TrapsToCheck) = SliceableTrapMaxCell;
        
        %write results to cTimelapse
        ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TrapsToCheck) = SliceableTrapInfoToWrite;
        ttacObject.TimelapseTraps.cTimepoint(ttacObject.TimelapseTraps.timepointsToProcess(1)).trapMaxCell = TrapMaxCell;
        ttacObject.TimelapseTraps.cTimepoint(TP).trapMaxCellUTP = TrapMaxCell;
        ttacObject.TimelapseTraps.timepointsProcessed(TP) = true;
        
        TrapInfo(TrapsToCheck) = SliceableTrapInfo;
    else
        TrapInfo = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo;
    end
    
    for trapi = TrapsToCheck
        AbsoluteCellCentres = round(ReturnCellCentreAbsolute(ttacObject,TP,trapi));
        for CI = 1:size(AbsoluteCellCentres,1)
            %this is a vector taken from the correlation image at the
            %current timepoint which will hopefully be very similar for
            %this same cells at the next timepoint.
            TrapInfo(trapi).cell(CI).CorrelationVector = squeeze(WholeImageElcoHoughNormalised(AbsoluteCellCentres(CI,2),AbsoluteCellCentres(CI,1),:));
        end
    end
    
    
    PreviousWholeImage = WholeImage;
    PreviousTrapLocations = TrapLocations;
    PreviousTrapInfo = TrapInfo;
    
    TimeOfTimepoint = toc;
    fprintf('timepoint analysed in %.2f seconds \n',TimeOfTimepoint);
    
    disp.slider.Value = TP;
    disp.slider_cb;
    pause(.1);
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

