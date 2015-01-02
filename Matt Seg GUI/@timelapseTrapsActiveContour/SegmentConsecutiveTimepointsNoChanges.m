function SegmentConsecutiveTimepointsNoChanges(ttacObject,FirstTimepoint,LastTimepoint)
%SegmentConsecutiveTimepointsNoChanges(ttacObject,FirstTimepoint,LastTimepoint)
%very simple code for cycloheximide or bleaching data. Uses the
%CrossCorrelationChannel to register the image with the first timepoint,
%then just moves cells by this registration value without changing the cell
%outline at all.
%
%
%   INPUTS
% FirstTimepoint    - time point at which to start
% LastTimepoint     - and to end
%
%
%outline


MaxOffsetRegistration = 30;


FixFirstTimePointBoolean = true;



ACparameters = ttacObject.Parameters.ActiveContour;
ITparameters = ttacObject.Parameters.ImageTransformation;
slice_size = 1;%slice of the timestack you look at in one go. Fixed to 1 since this makes most sense  for looking 1 timpoint into the future.
keepers = 1;%number of timpoints from that slice that you will keep (normally slice_size-1)
SubImageSize = ttacObject.Parameters.ImageSegmentation.SubImageSize;%61;
OptPoints = ttacObject.Parameters.ImageSegmentation.OptPoints;%6;

ProspectiveImageSize =ttacObject.Parameters.CrossCorrelation.ProspectiveImageSize;% 81; %image which will be searched for next cell
CrossCorrelationChannel = ttacObject.Parameters.CrossCorrelation.CrossCorrelationChannel; % 2; %ttacObject.Parameters.ImageTransformation.channel;
CrossCorrelationTrapThreshold = ttacObject.Parameters.CrossCorrelation.CrossCorrelationTrapThreshold; % Inf;% %value of trap pixels above which they are excluded from cross correlation image and therefore do not contribute
CrossCorrelationValueThreshold = ttacObject.Parameters.CrossCorrelation.CrossCorrelationValueThreshold; %0.5; % value normalised cross correlation must be above to consitute continuation of cell from previous timepoint
CrossCorrelationDIMthreshold = ttacObject.Parameters.CrossCorrelation.CrossCorrelationDIMthreshold;%  -0.3; %decision image threshold above which cross correlated cells are not considered to be possible cells
PostCellIdentificationDilateValue = ttacObject.Parameters.CrossCorrelation.PostCellIdentificationDilateValue;% 2; %dilation applied to the cell outline to rule out new cell centres
CrossCorrelationGradThresh = ttacObject.Parameters.CrossCorrelation.CrossCorrelationGradThresh;% {25}; %used to find the bound the gradient necessary for an edge to be considered an edge
CrossCorrelationUseCanny = ttacObject.Parameters.CrossCorrelation.CrossCorrelationUseCanny;%true; % another parameter for cross correlation. If true cannies the image first so that intensity is unimportant, only edges and gradient direction.


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
CrossCorrelationPrior2 = 2*fspecial('gaussian',ProspectiveImageSize,JumpSize2);
[~,angle] = ACBackGroundFunctions.radius_and_angle_matrix([ProspectiveImageSize,ProspectiveImageSize]);
CrossCorrelationPrior2 = CrossCorrelationPrior2.*cos(angle);
CrossCorrelationPrior2(:,1:(floor(ProspectiveImageSize/2))) = 0;
CrossCorrelationPrior = max((1-JumpWeight)*CrossCorrelationPrior1/max(CrossCorrelationPrior1(:)),JumpWeight*CrossCorrelationPrior2/max(CrossCorrelationPrior2(:)));
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
if LastTimepoint-FirstTimepoint>50 || ~isempty(gcp('nocreate'))%(matlabpool('size') ~= 0)
    
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



 %array to hold the maximum label used in each trap
 if TPtoStartSegmenting == ttacObject.TimelapseTraps.timepointsToProcess(1)
     TrapMaxCell = zeros(1,length(ttacObject.TimelapseTraps.cTimepoint(TPtoStartSegmenting).trapLocations));
 else
     TrapMaxCell = ttacObject.TimelapseTraps.cTimepoint(TPtoStartSegmenting-1).trapMaxCellUTP;
 end

 WholeImageOne = ttacObject.ReturnImage(Timepoints(1),CrossCorrelationChannel);
 WholeImageOne = IMnormalise(WholeImageOne);
 FirstTrapInfo = ttacObject.TimelapseTraps.cTimepoint(Timepoints(1)).trapInfo;
%% loop through the rest of the timepoints
for TP = Timepoints
    
    tic;
    fprintf('timepoint %d \n',TP)
    
        
    WholeImage = ttacObject.ReturnImage(TP,CrossCorrelationChannel);
    WholeImage = IMnormalise(WholeImage);
    
    TrapInfo = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo;
    
    TrapsToCheck = ttacObject.TrapsToCheck(TP);
    
    if TP>= TPtoStartSegmenting;
        
        RegistrationOffset = FindRegistrationForImageStack(cat(3,WholeImageOne,WholeImage),1,MaxOffsetRegistration,Inf,Inf);
        RegistrationOffset = RegistrationOffset(2,:);

        %begin prep for parallelised slow section
        
        SliceableTrapInfo = TrapInfo(TrapsToCheck);
        SliceableTrapInfoToWrite = SliceableTrapInfo;
        
        SliceableFirstTrapInfo = FirstTrapInfo(TrapsToCheck);

        SliceableTrapMaxCell = TrapMaxCell(TrapsToCheck);
        

        %parfor actually looking for cells
        %fprintf('CHANGE BACK TO PARFOR IN SegmentConsecutiveTimepointsCrossCorrelationParallel\n')
        for TI = 1:length(TrapsToCheck)
        
        %for TI = 1:length(TrapsToCheck)
        %fprintf('lin 348 SegmentConsecutive....: make parallel again\n')

            CurrentFirstTrapInfo = SliceableFirstTrapInfo(TI);

            ParCurrentTrapInfo = SliceableTrapInfo(TI);

            ParCurrentTrapInfo.cell = NewCellStruct;
            ParCurrentTrapInfo.cellsPresent = false;
            ParCurrentTrapInfo.cellLabel = [];
            %look for new cells
            for NCI = 1:length(CurrentFirstTrapInfo.cell)

                    %write new cell info
                    ParCurrentTrapInfo.cell(NCI) = NewCellStruct;

                    ParCurrentTrapInfo.cellLabel(NCI) = CurrentFirstTrapInfo.cellLabel(NCI);
                        
                    ParCurrentTrapInfo.cell(NCI).cellCenter = double(CurrentFirstTrapInfo.cell(NCI).cellCenter) - fliplr(RegistrationOffset);
                    ParCurrentTrapInfo.cellsPresent = true;
                    
                    
                    %do active contour
                    
                   
                    
                    %write active contour result and change cross
                    %correlation matrix and decision image.
                    
                    RadiiResult = CurrentFirstTrapInfo.cell(NCI).cellRadii;
                    AnglesResult = CurrentFirstTrapInfo.cell(NCI).cellAngle;
                    
                    %if the cell has been added manually it won't have a
                    %radii or angle entry.
                    if isempty(RadiiResult)
                        RadiiResult = ones(1,OptPoints) *double(CurrentFirstTrapInfo.cell(NCI).cellRadius);
                        AnglesResult = linspace(0,2*pi,OptPoints+1);
                        AnglesResult = AnglesResult(1:(end-1));
                    end
                    
                    ParCurrentTrapInfo.cell(NCI).cellRadii = RadiiResult;
                    ParCurrentTrapInfo.cell(NCI).cellAngle = AnglesResult;
                    ParCurrentTrapInfo.cell(NCI).cellRadius = mean(RadiiResult);
                    
                    [px,py] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult',AnglesResult',double(ParCurrentTrapInfo.cell(NCI).cellCenter),TrapImageSize);
                    
                    SegmentationBinary = false(TrapImageSize);
                    SegmentationBinary(py+TrapImageSize(1,1)*(px-1))=true;
                    
                    
                    ParCurrentTrapInfo.cell(NCI).segmented = sparse(SegmentationBinary);
  
                
            end %loop over cells
            
            SliceableTrapInfoToWrite(TI) = ParCurrentTrapInfo;

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
        %ugly piece of code. If a cells is added by hand (not by this
        %program) it has no cell label. This if statement is suppose to
        %give it a cellLabel and thereby prevent errors down the line.
        %Hasto adjust the trapMaxTP fields, which may cause problems.
        for TI = TrapsToCheck
            for CI = 1:length(TrapInfo(TI).cell)
                if CI>length(TrapInfo(TI).cellLabel)
                    ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellLabel(CI) = ttacObject.TimelapseTraps.cTimepoint(1).trapMaxCell(TI)+1;
                    ttacObject.TimelapseTraps.cTimepoint(ttacObject.TimelapseTraps.timepointsToProcess(1)).trapMaxCell(TI) = ttacObject.TimelapseTraps.cTimepoint(ttacObject.TimelapseTraps.timepointsToProcess(1)).trapMaxCell(TI)+1;
                    for TPtemp = TP:ttacObject.TimelapseTraps.timepointsToProcess(end)
                        if isfield(ttacObject.TimelapseTraps.cTimepoint(TPtemp),'trapMaxCellUTP')
                            ttacObject.TimelapseTraps.cTimepoint(TPtemp).trapMaxCellUTP(TI) = ttacObject.TimelapseTraps.cTimepoint(ttacObject.TimelapseTraps.timepointsToProcess(1)).trapMaxCell(TI);
                        end
                    end
                    FirstTrapInfo = ttacObject.TimelapseTraps.cTimepoint(Timepoints(1)).trapInfo;
                end
                
                
            end
        end
    end

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

