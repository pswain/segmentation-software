function SegmentConsecutiveTimepointsCrossCorrelation(ttacObject,FirstTimepoint,LastTimepoint,FixFirstTimePointBoolean)
%SegmentConsecutiveTimepointsCrossCorrelation(ttacObject,FirstTimepoint,LastTimepoint,varargin)
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




if nargin<3
    
    FixFirstTimePointBoolean = false;
    
end


ACparameters = ttacObject.Parameters.ActiveContour;
ITparameters = ttacObject.Parameters.ImageTransformation;
slice_size = 1;%slice of the timestack you look at in one go. Fixed to 1 since this makes most sense  for looking 1 timpoint into the future.
keepers = 1;%number of timpoints from that slice that you will keep (normally slice_size-1)
SubImageSize = ttacObject.Parameters.ImageSegmentation.SubImageSize;%61;
OptPoints = ttacObject.Parameters.ImageSegmentation.OptPoints;%6;

ProspectiveImageSize = 81; %image which will be searched for next cell
CrossCorrelationChannel = 2;%ttacObject.Parameters.ImageTransformation.channel;
CrossCorrelationTrapThreshold = Inf;%0.6; %value of trap pixels above which they are excluded from cross correlation image and therefore do not contribute
CrossCorrelationValueThreshold = 0.5;%0.001; % value normalised cross correlation must be above to consitute continuation of cell from previous timepoint
CrossCorrelationDIMthreshold = -0.3; %decision image threshold above which cross correlated cells are not considered to be possible cells
PostCellIdentificationDilateValue = 2;
CrossCorrelationGradThresh = {25};
CrossCorrelationUseCanny = true;


RadMeans = (2:15)';
RadRanges = [RadMeans-0.5 RadMeans+0.5];

TwoStageThreshold = ttacObject.cCellVision.twoStageThresh; % boundary in decision image for new cells negative is stricter, positive more lenient

TrapPixExcludeThreshCentre = 0.5; %pixels which cannot be classified as centres
TrapPixExcludeThreshAC = 1; %pixels which will not be allowed within active contour areas
CellPixExcludeThresh = 0.8;

% cross correlation prior constructed from two parts: 
% a tight gaussian gaussian centered at the center spot (width JumpSize1)
% a broader gaussian constrained to not go beyond front of the cell (width JumpSize2, truncated at JumpSize1)
JumpSize1 = 2;
JumpSize2 = 15;
JumpWeight = 0.2;

CrossCorrelationPrior1 = fspecial('gaussian',ProspectiveImageSize,JumpSize1); %filter with which prospective image is multiplied to weigh centres close to expected stronger.
CrossCorrelationPrior2 = 2*fspecial('gaussian',ProspectiveImageSize,JumpSize2);
[~,angle] = ACBackGroundFunctions.radius_and_angle_matrix([ProspectiveImageSize,ProspectiveImageSize]);
CrossCorrelationPrior2 = CrossCorrelationPrior2.*cos(angle);
CrossCorrelationPrior2(:,1:(floor(ProspectiveImageSize/2))) = 0;
CrossCorrelationPrior = max((1-JumpWeight)*CrossCorrelationPrior1/max(CrossCorrelationPrior1(:)),JumpWeight*CrossCorrelationPrior2/max(CrossCorrelationPrior2(:)));
%CrossCorrelationPrior = CrossCorrelationPrior./max(CrossCorrelationPrior(:));

%for debugging
%CrossCorrelationPrior = ones(ProspectiveImageSize,ProspectiveImageSize);


ImageTransformFunction = str2func(['ACImageTransformations.' ttacObject.Parameters.ImageTransformation.ImageTransformFunction]);

TrapWidth = ttacObject.TimelapseTraps.cTrapSize.bb_width;
TrapHeight = ttacObject.TimelapseTraps.cTrapSize.bb_height;

NewCellStruct = struct('cellCenter',[],...
                       'cellRadius',[],...
                       'segmented',sparse(false(ttacObject.TrapImageSize)),...
                       'crossCorrelationScore',[],...
                       'decisionImageScore',[],...
                       'cellRadii',[],...
                       'cellAngle',[]);


%protects program from super crashing out by opening and closing a million
%images.
if LastTimepoint-FirstTimepoint>50 || (matlabpool('size') ~= 0)
    
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
     TrapMaxCell = zeros(1,length(ttacObject.TimelapseTraps.cTimepoint(TPtoStartSegmenting).trapInfo));
 else
     TrapMaxCell = ttacObject.TimelapseTraps.cTimepoint(TPtoStartSegmenting).trapMaxCellUTP;
 end

%% loop through the rest of the timepoints
for TP = Timepoints
    
    tic;
    fprintf('timepoint %d \n',TP)
    
        
    WholeImage = ttacObject.ReturnImage(TP,CrossCorrelationChannel);
    WholeImage = IMnormalise(WholeImage);
    
    %WholeImage = 1*edge(WholeImage,'canny',0.01);
%     upper = prctile(WholeImage(:),95);
%     lower = prctile(WholeImage(:),5);
%     WholeImage(WholeImage>upper) = upper;
%     WholeImage(WholeImage<lower) = lower;
%     

    
    
    
    if ttacObject.TrapPresentBoolean
        WholeTrapImage = ttacObject.ReturnTrapImage(TP);
    else
        WholeTrapImage = zeros(size(WholeImage));
    end

        ACImage = ttacObject.ReturnImage(TP,ttacObject.Parameters.ImageTransformation.channel);
        ACImage = IMnormalise(ACImage);

    
    TrapLocations = ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations;
    TrapInfo = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo;
    
    if TP>= TPtoStartSegmenting;
        
        %get decision image for each cell from SVM
        DecisionImageStack = identifyCellCentersTrap(ttacObject.TimelapseTraps,ttacObject.cCellVision,TP,ttacObject.TrapsToCheck(TP),[],[]);
        
        if ttacObject.TrapPresentBoolean
            [~,WholeImageElcoHough] = ElcoImageFilter(WholeImage,RadRanges,CrossCorrelationGradThresh,-1,WholeTrapImage>CrossCorrelationTrapThreshold,false,CrossCorrelationUseCanny);
        else
            [~,WholeImageElcoHough] = ElcoImageFilter(WholeImage,RadRanges,CrossCorrelationGradThresh,-1,[],false,CrossCorrelationUseCanny);
        end
        
        TrapsToCheck = ttacObject.TrapsToCheck(TP);
        for TI = 1:length(TrapsToCheck)
            %fprintf('%d,trap\n',TI)
            NewCells = [];
            OldCells = [];
            NewCrossCorrelatedCells = [];
            CurrentTrapInfo = TrapInfo(TrapsToCheck(TI));
            TrapDecisionImage = DecisionImageStack(:,:,TI);
            
            %             %might need to do something about this
            %             if isempty(CurrentTrapInfo)
            %             end
            if TP>FirstTimepoint
                PreviousCurrentTrapInfo = PreviousTrapInfo(TrapsToCheck(TI));
            end
            
            if TP>FirstTimepoint && (PreviousCurrentTrapInfo.cellsPresent) && ~isinf(CrossCorrelationValueThreshold) && ~isempty(PreviousCurrentTrapInfo.cell(1).cellCenter)
                
                if false %old cross correlation scheme
                %cross correlation loop
                PreviousCellCentresAbsolute = ttacObject.ReturnCellCentreAbsolute(TP-1,TrapsToCheck(TI));
                
                PreviousCellImages = ACBackGroundFunctions.get_cell_image(PreviousWholeImage,ttacObject.Parameters.ImageSegmentation.SubImageSize,PreviousCellCentresAbsolute);
                
                PredictedCellLocationsAllCells = zeros(ttacObject.TrapImageSize(1),ttacObject.TrapImageSize(2),length(PreviousCurrentTrapInfo.cell));
                
                %loop over old cells and do cross correlation
                for CI = 1:length(PreviousCurrentTrapInfo.cell)
                    
                    %make template
                    
                    %get absolute centres
                    
                    %get cell images from centres
                    
                    CellImage = PreviousCellImages(:,:,CI);
                    
                        CellOutline = ACBackGroundFunctions.get_cell_image(full(PreviousCurrentTrapInfo.cell(CI).segmented),...
                    ttacObject.Parameters.ImageSegmentation.SubImageSize,...
                        PreviousCurrentTrapInfo.cell(CI).cellCenter );
                    
                    CellOutline = imfill(CellOutline,'holes');
                    CellOutline = imdilate(CellOutline,strel('disk',3),'same');
                    %remove erode and instead dilate trap image
                    %CellOutline = bwmorph(CellOutline,'erode');
                    
                    %make expected centre absolute
                    %done in this way (relative to trap centre) so as not
                    %to be affected by drift
                    if isfield(PreviousCurrentTrapInfo.cell(CI),'ExpectedCentre')
                        LocalExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).ExpectedCentre;
                    else
                        LocalExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).cellCenter;
                    end
                        
                    ExpectedCellCentre = LocalExpectedCellCentre + [TrapLocations(TrapsToCheck(TI)).xcenter TrapLocations(TrapsToCheck(TI)).ycenter] - ([TrapWidth TrapHeight] + 1) ;
                    
                    if ExpectedCellCentre(1)>ttacObject.ImageSize(1)
                        ExpectedCellCentre(1) = ttacObject.ImageSize(1);
                    end
                    
                    if ExpectedCellCentre(1)<1;
                        ExpectedCellCentre(1) = 1;
                    end
                    
                    if ExpectedCellCentre(2)>ttacObject.ImageSize(2)
                        ExpectedCellCentre(2) = ttacObject.ImageSize(2);
                    end
                    
                    if ExpectedCellCentre(2)<1;
                        ExpectedCellCentre(2) = 1;
                    end
                    
                    ProspectiveImage = ACBackGroundFunctions.get_cell_image(WholeImage,...
                        ProspectiveImageSize,...
                        ExpectedCellCentre );
                    if ttacObject.TrapPresentBoolean
                        TrapImageOfPredictedCellLocation = ACBackGroundFunctions.get_cell_image(WholeTrapImage,...
                            ProspectiveImageSize,...
                            ExpectedCellCentre );
                    end
                    
                    %adjust images to get zero contribution from non
                    %template pixels
                    CellMean = mean(CellImage(CellOutline));
                    CellImage(~CellOutline) = CellMean;
                    
                    %might not be necessary
                    if ttacObject.TrapPresentBoolean
                        TrapImageOfPredictedCellLocation = TrapImageOfPredictedCellLocation>CrossCorrelationTrapThreshold;
                        TrapImageOfPredictedCellLocation = bwmorph(TrapImageOfPredictedCellLocation,'dilate',1);
                        ProspectiveImageMean = mean(ProspectiveImage(~TrapImageOfPredictedCellLocation));
                        ProspectiveImage(TrapImageOfPredictedCellLocation) = ProspectiveImageMean;
                    end
                    %do cross correlation
                    PredictedCellLocation = normxcorr2(CellImage,ProspectiveImage);
                    PredictedCellLocation = (PredictedCellLocation(ceil(SubImageSize/2):(end-floor(SubImageSize/2)),ceil(SubImageSize/2):(end-floor(SubImageSize/2))));
                    PredictedCellLocation = CrossCorrelationPrior.*PredictedCellLocation;
                    
                    PredictedCellLocationsAllCells(:,:,CI) = ACBackGroundFunctions.get_cell_image(PredictedCellLocation,...
                        ttacObject.TrapImageSize,...
                        (ceil(ProspectiveImageSize/2)*[1 1] + ceil(fliplr(ttacObject.TrapImageSize)/2)) - LocalExpectedCellCentre,...
                        -2*abs(CrossCorrelationValueThreshold) ).*(TrapDecisionImage<CrossCorrelationDIMthreshold);

                end %end cell loop to find cross correlation matrix
                
                end
                
                
                if true %new hough ish scheme
                    
                    PredictedCellLocationsAllCells = zeros(ttacObject.TrapImageSize(1),ttacObject.TrapImageSize(2),length(PreviousCurrentTrapInfo.cell));
                    
                    if ttacObject.Parameters.ActiveContour.visualise>2;
                        cc_gui.stack = cat(3,WholeImageElcoHough,WholeImage);
                        cc_gui.LaunchGUI;
                        pause
                    end
                
                    for CI = 1:length(PreviousCurrentTrapInfo.cell)
                        
                        if isfield(PreviousCurrentTrapInfo.cell(CI),'ExpectedCentre')
                            LocalExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).ExpectedCentre;
                        else
                            LocalExpectedCellCentre = PreviousCurrentTrapInfo.cell(CI).cellCenter;
                        end
                        
                        ExpectedCellCentre = LocalExpectedCellCentre + [TrapLocations(TrapsToCheck(TI)).xcenter TrapLocations(TrapsToCheck(TI)).ycenter] - ([TrapWidth TrapHeight] + 1) ;
                        
                        if ExpectedCellCentre(1)>ttacObject.ImageSize(1)
                            ExpectedCellCentre(1) = ttacObject.ImageSize(1);
                        end
                        
                        if ExpectedCellCentre(1)<1;
                            ExpectedCellCentre(1) = 1;
                        end
                        
                        if ExpectedCellCentre(2)>ttacObject.ImageSize(2)
                            ExpectedCellCentre(2) = ttacObject.ImageSize(2);
                        end
                        
                        if ExpectedCellCentre(2)<1;
                            ExpectedCellCentre(2) = 1;
                        end
                        
                        CellRadii = PreviousCurrentTrapInfo.cell(CI).cellRadii;
                        
                        PredictedCellLocation = zeros(ProspectiveImageSize,ProspectiveImageSize);
                        for CellRadius = CellRadii
                            [~,BestFit] = sort(abs(RadMeans-CellRadius),1,'ascend');
                            BestFit = BestFit(1)';%BestFit = BestFit(1:2)';
                            for BestFiti = BestFit
                                PredictedCellLocation = PredictedCellLocation + ACBackGroundFunctions.get_cell_image(WholeImageElcoHough(:,:,BestFiti),...
                                    ProspectiveImageSize,...
                                    ExpectedCellCentre );
                                %multiplication by Radmeans added because it seems like the
                                %transformation procedure gave higher values for smaller radii - so
                                %this should balance that.
                            end
                        end
                        PredictedCellLocation = CrossCorrelationPrior.*PredictedCellLocation;
                        
                        PredictedCellLocationsAllCells(:,:,CI) = ACBackGroundFunctions.get_cell_image(PredictedCellLocation,...
                            ttacObject.TrapImageSize,...
                            (ceil(ProspectiveImageSize/2)*[1 1] + ceil(fliplr(ttacObject.TrapImageSize)/2)) - LocalExpectedCellCentre,...
                            -2*abs(CrossCorrelationValueThreshold) ).*(TrapDecisionImage<CrossCorrelationDIMthreshold);
                        
                        
                        
                        
                    end
                end
                
                %store image for visualisation
                if ttacObject.Parameters.ActiveContour.visualise > 0
                    PredictedCellLocationsAllCellsToView = PredictedCellLocationsAllCells;
                    
                end
                
                if ttacObject.Parameters.ActiveContour.visualise>2;
                    cc_gui.stack = cat(3,PredictedCellLocationsAllCellsToView,TrapDecisionImage);
                    cc_gui.LaunchGUI;
                    pause
                    close(cc_gui.FigureHandle);
                end
                
                
                CrossCorrelating = true;
            else
                CrossCorrelating = false;
                
            end %if timepoint> FirstTimepoint
            
            if ttacObject.TrapPresentBoolean
                TrapTrapImage = ACBackGroundFunctions.get_cell_image(WholeTrapImage,...
                    ttacObject.TrapImageSize,...
                    [TrapLocations(TrapsToCheck(TI)).xcenter TrapLocations(TrapsToCheck(TI)).ycenter],...
                    0 ) ;
                TrapTrapLogical = TrapTrapImage > TrapPixExcludeThreshCentre;
                if CrossCorrelating
                    PredictedCellLocationsAllCells(repmat(TrapTrapLogical,[1,1,size(PredictedCellLocationsAllCells,3)])) = -2*abs(CrossCorrelationValueThreshold);
                    
                end
                TrapDecisionImage(TrapTrapLogical) = 2*abs(TwoStageThreshold);
            else
                TrapTrapLogical = false(ttacObject.TrapImageSize);
                TrapTrapImage = zeros(ttacObject.TrapImageSize);
                
            end
            
            NotCells = TrapTrapLogical;
            AllCellPixels = zeros(ttacObject.TrapImageSize);
            
            CellSearch = true;
            ProceedWithCell = false;
            NCI = 0;
            CurrentTrapInfo.cell = NewCellStruct;
            CurrentTrapInfo.cellsPresent = false;
            CurrentTrapInfo.cellLabel = [];
            %look for new cells
            while CellSearch
                
                if CrossCorrelating
                    %look for cells based on cross correlation with
                    %previous timepoint
                    value = max(PredictedCellLocationsAllCells(:));
                    [Index] = find(PredictedCellLocationsAllCells==value,1);
                    if value>CrossCorrelationValueThreshold
                        [ynewcell,xnewcell,CI] = ind2sub(size(PredictedCellLocationsAllCells),Index);
                        ProceedWithCell = true;
                    else
                        ProceedWithCell = false;
                        CrossCorrelating = false;
                    end
                end
                
                if ~CrossCorrelating
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
                    CurrentTrapInfo.cell(NCI) = NewCellStruct;

                    if CrossCorrelating
                        CurrentTrapInfo.cellLabel(NCI) = PreviousCurrentTrapInfo.cellLabel(CI);
                        OldCells = [OldCells CI];
                        NewCrossCorrelatedCells = [NewCrossCorrelatedCells NCI];
                        CurrentTrapInfo.cell(NCI).crossCorrelationScore = value;
                        CurrentTrapInfo.cell(NCI).decisionImageScore = NaN;
                    else
                        NewCells = [NewCells NCI];
                        CurrentTrapInfo.cellLabel(NCI) = TrapMaxCell(TrapsToCheck(TI))+1;
                        TrapMaxCell(TrapsToCheck(TI)) = TrapMaxCell(TrapsToCheck(TI))+1;
                        CurrentTrapInfo.cell(NCI).crossCorrelationScore = NaN;
                        CurrentTrapInfo.cell(NCI).decisionImageScore = value;
                    end
                    CurrentTrapInfo.cell(NCI).cellCenter = double([xnewcell ynewcell]);
                    CurrentTrapInfo.cellsPresent = true;
                    
                    
                    %do active contour
                    
                    NewCellCentre = [xnewcell ynewcell] + [TrapLocations(TrapsToCheck(TI)).xcenter TrapLocations(TrapsToCheck(TI)).ycenter] - ( [TrapWidth TrapHeight] + 1 );
                    
                    if NewCellCentre(1)>ttacObject.ImageSize(1)
                        NewCellCentre(1) = ttacObject.ImageSize(1);
                    end
                    
                    if NewCellCentre(1)<1;
                        NewCellCentre(1) = 1;
                    end
                    
                    if NewCellCentre(2)>ttacObject.ImageSize(2)
                        NewCellCentre(2) = ttacObject.ImageSize(2);
                    end
                    
                    if NewCellCentre(2)<1;
                        NewCellCentre(2) = 1;
                    end
                    
                    CellImage = ACBackGroundFunctions.get_cell_image(ACImage,...
                        SubImageSize,...
                        NewCellCentre );
                    
                    NotCellsCell = ACBackGroundFunctions.get_cell_image(AllCellPixels,...
                        SubImageSize,...
                        [xnewcell ynewcell],...
                        false);
                    
                    
                    if ttacObject.TrapPresentBoolean
                        CellTrapImage = ACBackGroundFunctions.get_cell_image(WholeTrapImage,...
                            SubImageSize,...
                            NewCellCentre );
                        TransformedCellImage = ImageTransformFunction(CellImage,ttacObject.Parameters.ImageTransformation.TransformParameters,CellTrapImage+NotCellsCell);
                        
                    else
                        TransformedCellImage = ImageTransformFunction(CellImage,ttacObject.Parameters.ImageTransformation.TransformParameters,NotCellsCell);
                    end
                    
                    if ttacObject.TrapPresentBoolean
                        ExcludeLogical = (CellTrapImage>=TrapPixExcludeThreshAC) | (NotCellsCell>=CellPixExcludeThresh);
                    else
                        ExcludeLogical = NotCellsCell>=CellPixExcludeThresh;
                    end
                    
                    if ~any(ExcludeLogical(:))
                        ExcludeLogical = [];
                    end
                    
                    if CrossCorrelating
                        PreviousTimepointRadii = PreviousCurrentTrapInfo.cell(CI).cellRadii;
                    
                    [RadiiResult,AnglesResult] = ...
                        ACMethods.PSORadialTimeStack(TransformedCellImage,ACparameters,FauxCentersStack,PreviousTimepointRadii,PreviousTimepointRadii,ExcludeLogical);
                    else
                        [RadiiResult,AnglesResult] = ...
                        ACMethods.PSORadialTimeStack(TransformedCellImage,ACparameters,FauxCentersStack,[],[],ExcludeLogical);
                    
                    end
                    %write active contour result and change cross
                    %correlation matrix and decision image.
                    
                    CurrentTrapInfo.cell(NCI).cellRadii = RadiiResult;
                    CurrentTrapInfo.cell(NCI).cellAngle = AnglesResult;
                    CurrentTrapInfo.cell(NCI).cellRadius = mean(RadiiResult);
                    
                    [px,py] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult',AnglesResult',double(CurrentTrapInfo.cell(NCI).cellCenter),ttacObject.TrapImageSize);
                    
                    SegmentationBinary = false(ttacObject.TrapImageSize);
                    SegmentationBinary(py+ttacObject.TrapImageSize(1,1)*(px-1))=true;
                    
                    
                    CurrentTrapInfo.cell(NCI).segmented = sparse(SegmentationBinary);
                    SegmentationBinary = imfill(SegmentationBinary,'holes');
                    DilateSegmentationBinary = imdilate(SegmentationBinary,strel('disk',PostCellIdentificationDilateValue),'same');
                    
                     if CrossCorrelating
                         %remove cell that has been successfully cross
                         %correlated from cross correlation matrix
                         PredictedCellLocationsAllCells(:,:,CI) = -2*abs(CrossCorrelationValueThreshold);
                         %ensure no cells are found overlapping identified cell
                         PredictedCellLocationsAllCells(repmat(DilateSegmentationBinary,[1,1,size(PredictedCellLocationsAllCells,3)])) = -2*abs(CrossCorrelationValueThreshold);
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
                    
                    if ACparameters.visualise>0;
                        TrapIm = double(ttacObject.TimelapseTraps.returnSingleTrapTimepoint(TrapsToCheck(TI),TP,ACparameters.ShowChannel));
                        if CrossCorrelating
                            fprintf('cell found by cross correlation. CC value  =  %f ;\n',value)
                            figure(cc_im_handle);
                            imshow(OverlapGreyRed(TrapIm,PredictedCellLocationsAllCellsToView(:,:,CI),true,(TrapTrapImage>=TrapPixExcludeThreshAC) |(AllCellPixels>=CellPixExcludeThresh)),[]);
                            title('cross correlation image')
                        else
                            fprintf('cell found by deicison image. DI value  =  %f ;\n',value)
                        end
                        figure(dec_im_handle);
                        imshow(OverlapGreyRed(TrapIm,TrapDecisionImage,true),[]);
                        title('decision image')
                        figure(outline_im_handle);
                        imshow(OverlapGreyRed(TrapIm,xor(NotCells,SegmentationBinary),false,SegmentationBinary),[])
                        title('new cell outline')
                        
                        pause(1)
                        if ACparameters.visualise >=1
                            pause
                        end
                        
                    end
                    
                end %if ProceedWithCell
                
            end %while cell search
            
            %write results to cTimelapse
            ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TrapsToCheck(TI)) = CurrentTrapInfo;
            ttacObject.TimelapseTraps.cTimepoint(ttacObject.TimelapseTraps.timepointsToProcess(1)).trapMaxCell = TrapMaxCell;
            ttacObject.TimelapseTraps.cTimepoint(TP).trapMaxCellUTP = TrapMaxCell;
            
            
            %calculated expected CellCentre as the simple sum of current
            %location and distance moved in previous timepoint.
            %for new cells it is simply their current location
             for CI = 1:length(NewCrossCorrelatedCells);
                CellMove = (CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).cellCenter - PreviousCurrentTrapInfo.cell(OldCells(CI)).cellCenter);
                if any(abs(CellMove)>4) %more than 4, probably a jump, cell movement not related to previous timepoint
                    CellMove = [0 0];
                end
                %CellMove = sign(CellMove) .* min(abs(CellMove),[2 2]); %allow a predicted move of no more than two - stops crazy jumps
                CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre = CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).cellCenter + CellMove;
                if CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(1) > ttacObject.TrapImageSize(2);
                    CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(1) = ttacObject.TrapImageSize(2);
                elseif CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(1) < 1;
                    CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(1) = 1;
                end
                
                if CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(2) > ttacObject.TrapImageSize(1);
                    CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(2) = ttacObject.TrapImageSize(1);
                elseif CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(2) < 1;
                    CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre(2) = 1;
                end
                
            end
            
            for CI = 1:length(NewCells);
                CurrentTrapInfo.cell(NewCells(CI)).ExpectedCentre = CurrentTrapInfo.cell(NewCells(CI)).cellCenter;
            end
            
            %write results to internal variables
            TrapInfo(TrapsToCheck(TI)) = CurrentTrapInfo;
           
            
            
            
        end %end traps loop
        
    end
    
    PreviousWholeImage = WholeImage;
    PreviousTrapLocations = TrapLocations;
    PreviousTrapInfo = TrapInfo;
    
    TimeOfTimepoint = toc;
    fprintf('timepoint analysed in %.2f seconds \n',TimeOfTimepoint);
    
end %end TP loop
 
 
end

function WholeImage = IMnormalise(WholeImage)

WholeImage = double(WholeImage);
        WholeImage = WholeImage - median(WholeImage(:));
        IQ = iqr(WholeImage(:));
        if IQ>0
            WholeImage = WholeImage./iqr(WholeImage(:));
        end
        
end

