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
CrossCorrelationChannel = 1;%ttacObject.Parameters.ImageTransformation.channel;
CrossCorrelationTrapThreshold = 0.1;
CrossCorrelationValueThreshold = 0.001;

TwoStageThreshold = 0; %negative is stricter, positive more lenient

TrapPixExcludeThresh = 1;
CellPixExcludeThresh = 0.8;

CrossCorrelationPrior = fspecial('gaussian',ProspectiveImageSize,10); %filter with which prospective image is multiplied to weigh centres close to expected stronger.
CrossCorrelationPrior = CrossCorrelationPrior./max(CrossCorrelationPrior(:));

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


%% loop through the rest of the timepoints
for TP = Timepoints
    
    tic;
    fprintf('timepoint %d \n',TP)
    
        
    WholeImage = ttacObject.ReturnImage(TP,CrossCorrelationChannel);
    WholeImage = IMnormalise(WholeImage);
    
    if ttacObject.TrapPresentBoolean
        WholeTrapImage = ttacObject.ReturnTrapImage(TP);
    else
        WholeTrapImage = zeros(size(WholeImage));
    end
    
    if ITparameters.channel ~= CrossCorrelationChannel;
        ACImage = ttacObject.ReturnImage(TP);
        ACImage = IMnormalise(ACImage);
        
    else
        ACImage = WholeImage;
    end
    
    TrapLocations = ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations;
    TrapInfo = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo;
    
        %array to hold the maximum label used in each trap
        
    
    if TP == ttacObject.TimelapseTraps.timepointsToProcess(1)
        TrapMaxCell = zeros(1,length(TrapInfo));
    else
        TrapMaxCell = ttacObject.TimelapseTraps.cTimepoint(TP-1).trapMaxCellUTP;
    end
    
    
    if TP>= TPtoStartSegmenting;
        
        %get decision image for each cell from SVM
        DecisionImageStack = identifyCellCentersTrap(ttacObject.TimelapseTraps,ttacObject.cCellVision,TP,ttacObject.TrapsToCheck(TP),[],[]);
        
        for TI = ttacObject.TrapsToCheck(TP)
            
            NewCells = [];
            OldCells = [];
            NewCrossCorrelatedCells = [];
            CurrentTrapInfo = TrapInfo(TI);
            TrapDecisionImage = DecisionImageStack(:,:,TI);
            
            %             %might need to do something about this
            %             if isempty(CurrentTrapInfo)
            %             end
            if TP>FirstTimepoint
                PreviousCurrentTrapInfo = PreviousTrapInfo(TI);
            end
            
            if TP>FirstTimepoint && (PreviousCurrentTrapInfo.cellsPresent) && ~isinf(CrossCorrelationValueThreshold)
                %cross correlation loop
                PreviousCellCentresAbsolute = ttacObject.ReturnCellCentreAbsolute(TP-1,TI);
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
                        
                    ExpectedCellCentre = LocalExpectedCellCentre + [TrapLocations(TI).xcenter TrapLocations(TI).ycenter] - ([TrapWidth TrapHeight] + 1) ;
                    
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
                        -2*abs(CrossCorrelationTrapThreshold) ).*(TrapDecisionImage<0).*(-TrapDecisionImage)/sum(CellOutline(:));

                end %end cell loop to find cross correlation matrix
                
                %store image for visualisation
                if ttacObject.Parameters.ActiveContour.visualise > 0
                    PredictedCellLocationsAllCellsToView = PredictedCellLocationsAllCells;
                    
                end
                
                
                CrossCorrelating = true;
            else
                CrossCorrelating = false;
                
            end %if timepoint> FirstTimepoint
            
            if ttacObject.TrapPresentBoolean
                TrapTrapImage = ACBackGroundFunctions.get_cell_image(WholeTrapImage,...
                    ttacObject.TrapImageSize,...
                    [TrapLocations(TI).xcenter TrapLocations(TI).ycenter],...
                    0 ) ;
                TrapTrapLogical = TrapTrapImage > CrossCorrelationTrapThreshold;
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
                    
                    %lazy first bit to stop crashing
                    if NCI==1
                        CurrentTrapInfo.cell = NewCellStruct;
                    else
                        CurrentTrapInfo.cell(NCI) = NewCellStruct;
                    end
                    if CrossCorrelating
                        CurrentTrapInfo.cellLabel(NCI) = PreviousCurrentTrapInfo.cellLabel(CI);
                        OldCells = [OldCells CI];
                        NewCrossCorrelatedCells = [NewCrossCorrelatedCells NCI];
                        CurrentTrapInfo.cell(NCI).crossCorrelationScore = value;
                        CurrentTrapInfo.cell(NCI).decisionImageScore = NaN;
                    else
                        NewCells = [NewCells NCI];
                        CurrentTrapInfo.cellLabel(NCI) = TrapMaxCell(TI)+1;
                        TrapMaxCell(TI) = TrapMaxCell(TI)+1;
                        CurrentTrapInfo.cell(NCI).crossCorrelationScore = NaN;
                        CurrentTrapInfo.cell(NCI).decisionImageScore = value;
                    end
                    CurrentTrapInfo.cell(NCI).cellCenter = [xnewcell ynewcell];
                    CurrentTrapInfo.cellsPresent = true;
                    
                    
                    %do active contour
                    
                    NewCellCentre = [xnewcell ynewcell] + [TrapLocations(TI).xcenter TrapLocations(TI).ycenter] - ( [TrapWidth TrapHeight] + 1 );
                    
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
                        ExcludeLogical = (CellTrapImage>=TrapPixExcludeThresh) | (NotCellsCell>=CellPixExcludeThresh);
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
                    
                     if CrossCorrelating
                         %remove cell that has been successfully cross
                         %correlated from cross correlation matrix
                         PredictedCellLocationsAllCells(:,:,CI) = -2*abs(CrossCorrelationValueThreshold);
                         %ensure no cells are found overlapping identified cell
                         PredictedCellLocationsAllCells(repmat(SegmentationBinary,[1,1,size(PredictedCellLocationsAllCells,3)])) = -2*abs(CrossCorrelationValueThreshold);
                     end
                     %remove pixels identified as cell pixels from
                     %decision image
                     TrapDecisionImage(SegmentationBinary) = 2*abs(TwoStageThreshold);
                     

                    %update trap image so that it includes all
                    %segmented cells
                    NotCells = NotCells | SegmentationBinary;
                    EdgeConfidenceImage = bwdist(~SegmentationBinary);
                    EdgeConfidenceImage = EdgeConfidenceImage./max(EdgeConfidenceImage(:));
                    AllCellPixels = AllCellPixels + EdgeConfidenceImage;
                    
                    if ACparameters.visualise>0;
                        TrapIm = double(ttacObject.TimelapseTraps.returnSingleTrapTimepoint(TI,TP,ACparameters.ShowChannel));
                        if CrossCorrelating
                            fprintf('cell found by cross correlation. CC value  =  %f ;\n',value)
                            figure(cc_im_handle);
                            imshow(OverlapGreyRed(TrapIm,PredictedCellLocationsAllCellsToView(:,:,CI),true,(TrapTrapImage>=TrapPixExcludeThresh) |(AllCellPixels>=CellPixExcludeThresh)),[]);
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
            ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI) = CurrentTrapInfo;
            ttacObject.TimelapseTraps.cTimepoint(ttacObject.TimelapseTraps.timepointsToProcess(1)).trapMaxCell = TrapMaxCell;
            ttacObject.TimelapseTraps.cTimepoint(TP).trapMaxCellUTP = TrapMaxCell;
            
            
            %calculated expected CellCentre as the simple sum of current
            %location and distance moved in previous timepoint.
            %for new cells it is simply their current location
            for CI = 1:length(NewCrossCorrelatedCells);
                CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).ExpectedCentre = (2*CurrentTrapInfo.cell(NewCrossCorrelatedCells(CI)).cellCenter) - PreviousCurrentTrapInfo.cell(OldCells(CI)).cellCenter;
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
            TrapInfo(TI) = CurrentTrapInfo;
           
            
            
            
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

