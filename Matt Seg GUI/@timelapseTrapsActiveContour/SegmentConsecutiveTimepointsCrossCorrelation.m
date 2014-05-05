function SegmentConsecutiveTimepointsCrossCorrelation(ttacObject,FirstTimepoint,LastTimepoint,varargin)
%plan to find consecutve cell locations by cross correlation.





%% given cell number and trap numbers of cell (s) to investigate.

%% fit active contour for that cell at timepoint 1


%% Loop for all cells
%% get image of around expected location of cell at next time point

%% do cross correlation of sub cell image with this image
%% end loop


%% Loop for all cells

%% set trap and other cell pixels to be zero in cross correlation

%% pick cell with highest cross correlation score

%% decide that is centre at next time point and do cross active contour

%% add result to cell pixels to remove from other cross correlations

%% end loop





if size(varargin,2)>0
    
    FixFirstTimePointBoolean = varargin{1};
else
    FixFirstTimePointBoolean = false;
    
end


ACparameters = ttacObject.Parameters.ActiveContour;
ITparameters = ttacObject.Parameters.ImageTransformation;
slice_size = 1;%slice of the timestack you look at in one go. Fixed to 1 since this makes most sense  for looking 1 timpoint into the future.
keepers = 1;%number of timpoints from that slice that you will keep (normally slice_size-1)
SubImageSize = ttacObject.Parameters.ImageSegmentation.SubImageSize;%61;
OptPoints = ttacObject.Parameters.ImageSegmentation.OptPoints;%6;

ProspectiveImageSize = 121; %image which will be searched for next cell
CrossCorrelationChannel = ttacObject.Parameters.ImageTransformation.channel;
CrossCorrelationTrapThreshold = 0.1;
CrossCorrelationValueThreshold = 0;
CrossCorrelationPrior = fspecial('gaussian',ProspectiveImageSize,5); %filter with which prospective image is multiplied to weigh centres close to expected stronger.
CrossCorrelationPrior = CrossCorrelationPrior./max(CrossCorrelationPrior(:));


CellPreallocationNumber = 200;

%protects program from super crashing out by opening and closing a million
%images.
if LastTimepoint-FirstTimepoint>50 || (matlabpool('size') ~= 0)
    
    ACparameters.visualise = 0;
end


%FauxCentersStack is just a filler for the PSO optimisation that takes centers
%(because in this code the centers are always at the centers of the image).
%Better to assign it here than every time in the loop.
FauxCentersStack = round(SubImageSize/2)*ones(slice_size,2);

%size of trap image stored in Timelapse. If there are no traps, this is the
%size of the image.


Timepoints = FirstTimepoint:LastTimepoint;



ttacObject.CheckTimepointsValid(Timepoints)

%% create structure in which to store cell data
%it might seem the construction is strange, but it turned out to be fairly
%efficient to make a field for each slice of the final stack and then pass
%images backwards through the fields using 'deal'.

%The data structure is organised such that the most recent timepoint is the
%highest number, so that data are entered in the field 'fieldname_n', and
%then cycled back to 'fieldname_n-1',fielname_n-2' as other later data
%comes in to push them back. They are finally deposited in 'fieldname_1'
CellInfo = struct;
CellInfo.CellNumber = 0;
CellInfo.TrapNumber = 0;
CellInfo.CellLabel = 0;
CellInfo.PreviousTimepointResult = zeros(1,OptPoints);
CellInfo.TimePointsPresent = 0;
CellInfo.TimePointsAbsent = 0;
CellInfo.UpdatedThisTimepoint = false;
CellInfo.ProspectiveImage = zeros(ProspectiveImageSize);
CellInfo.ProspectiveTrapImage = zeros(ProspectiveImageSize);
CellInfo.CellCore = [];
CellInfo.ExpectedCentre = [0 0];

CellCentreStrings = cell(1,slice_size);
TrapCentreStrings = cell(1,slice_size);
TransformedImageStrings = cell(1,slice_size);
PriorRadiiStrings = cell(1,slice_size);
PriorAnglesStrings = cell(1,slice_size);
CellNumberTimelapseStrings = cell(1,slice_size);
TimePointStrings = cell(1,slice_size);
CellOultineStrings = cell(1,slice_size);
CellImageStrings = cell(1,slice_size);

for i=1:slice_size
    CellCentreStrings{i} = ['CellCentre' int2str(i)];
    CellInfo.(CellCentreStrings{i}) = zeros(1,2);
    TrapCentreStrings{i} =['TrapCentre' int2str(i)];
    CellInfo.(TrapCentreStrings{i})= zeros(1,2);
    TransformedImageStrings{i} = ['TransformedImage' int2str(i)];
    CellInfo.(TransformedImageStrings{i})= zeros(SubImageSize,SubImageSize);
    PriorRadiiStrings{i} = ['PriorRadii' int2str(i)];
    CellInfo.(PriorRadiiStrings{i}) = zeros(1,OptPoints);
    PriorAnglesStrings{i} = ['PriorAngles' int2str(i)];
    CellInfo.(PriorAnglesStrings{i}) = zeros(1,OptPoints);
    CellNumberTimelapseStrings{i} = ['CellNumberTimelapse' int2str(i)];
    CellInfo.(CellNumberTimelapseStrings{i}) = 0;
    TimePointStrings{i} = ['Timepoint' int2str(i)];
    CellInfo.(TimePointStrings{i}) = 0;
    CellOultineStrings{i} = ['CellOutline' int2str(i)];
    CellInfo.(CellOultineStrings{i}) = false(SubImageSize,SubImageSize);
    CellImageStrings{i} = ['CellImage' int2str(i)];
    CellInfo.(CellImageStrings{i}) = zeros(SubImageSize,SubImageSize);
    
end



InitialisedCellInfo = CellInfo;

CellInfo(1:CellPreallocationNumber) = InitialisedCellInfo;

EmptyCellEntries = true(1,CellPreallocationNumber);


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

%% loop through the rest of the timepoints
for TP = Timepoints
    
    tic;
    fprintf('timepoint %d \n',TP)
    
    UpdatedPreviousTimepoint = [CellInfo(:).UpdatedThisTimepoint];
    
    % not sure this chunk will be necessary in this function
    %     for CN = find((~UpdatedPreviousTimepoint) & (~EmptyCellEntries))
    %         %the indexing here is difficult to follow but the idea is that if
    %         %no cell is present at the previous timepoint but there is data in
    %         %the array we need to save the 'priors' since these will be our
    %         %best guess at the contour since we can't do anymore searches since
    %         %our data for this cell has run out. So we take the slices that
    %         %have not been segmented and saved but have been segmented as part
    %         %of the segmentation of earlier cells (RN's) and save them to the
    %         %appropriate timepoints (TP + RN -slice_size -1).
    %
    %
    %         %take cells which for which no cell was present at the previous
    %         %timepoint and makes the segmentation result the prior result for
    %         %all cells.
    %         for RN = setdiff((1:slice_size-1),1:(mod(CellInfo(CN).TimePointsPresent+1-slice_size,keepers)))
    %             %this is set_diff(all entries with priors, those already written to data structure by segmentation )
    %
    %             %write the results to keep to the cTimelapse object
    %             ttacObject.WriteACResults(CellInfo(CN).(TimePointStrings{RN}),CellInfo(CN).TrapNumber,CellInfo(CN).(CellNumberTimelapseStrings{RN}),CellInfo(CN).(PriorRadiiStrings{RN}),CellInfo(CN).(PriorAnglesStrings{RN}))
    %         end
    %
    %
    %     CellInfo(CN) = InitialisedCellInfo;
    %     EmptyCellEntries(CN) = true;
    %     end
    %move data 'back in time' and update update info
    [CellInfo(UpdatedPreviousTimepoint).UpdatedThisTimepoint] = deal(false);
%     for SN = 1:(slice_size-1)
%         
%         [CellInfo(UpdatedPreviousTimepoint).(CellCentreStrings{SN})] =deal(CellInfo(UpdatedPreviousTimepoint).(CellCentreStrings{SN+1}));
%         [CellInfo(UpdatedPreviousTimepoint).(TrapCentreStrings{SN})] =deal(CellInfo(UpdatedPreviousTimepoint).(TrapCentreStrings{SN+1}));
%         [CellInfo(UpdatedPreviousTimepoint).(TransformedImageStrings{SN})] =deal(CellInfo(UpdatedPreviousTimepoint).(TransformedImageStrings{SN+1}));
%         [CellInfo(UpdatedPreviousTimepoint).(PriorRadiiStrings{SN})] = deal(CellInfo(UpdatedPreviousTimepoint).(PriorRadiiStrings{SN+1}));
%         [CellInfo(UpdatedPreviousTimepoint).(PriorAnglesStrings{SN})] = deal(CellInfo(UpdatedPreviousTimepoint).(PriorAnglesStrings{SN+1}));
%         [CellInfo(UpdatedPreviousTimepoint).(CellNumberTimelapseStrings{SN})] = deal(CellInfo(UpdatedPreviousTimepoint).(CellNumberTimelapseStrings{SN+1}));
%         [CellInfo(UpdatedPreviousTimepoint).(TimePointStrings{SN})] = deal(CellInfo(UpdatedPreviousTimepoint).(TimePointStrings{SN+1}));
%         [CellInfo(UpdatedPreviousTimepoint).(CellOultineStrings{SN})] = deal(CellInfo(UpdatedPreviousTimepoint).(CellOultineStrings{SN+1}));
%         [CellInfo(UpdatedPreviousTimepoint).(CellImageStrings{SN})] = deal(CellInfo(UpdatedPreviousTimepoint).(CellImageStrings{SN+1}));
%         
%     end
    
    
    
    NumberOfCellsUpdated = 0;
    %checksum =0;
    
    if TP == FirstTimepoint;
        for TI = ttacObject.TrapsToCheck(TP)
            for CI = ttacObject.CellsToCheck(TP,TI);
                
                
                %fprintf('timepoint %d; trap %d ; cell %d \n',TP,TI,CI)
                
                %if the cell was previously recorded, put it
                %there.Otherwise, put in an empty place
                CellEntry = find(EmptyCellEntries,1);
                
                %If there are no available cell entries left initialise a
                %whole new tranch of cell entries
                if isempty(CellEntry)
                    CellEntry = length(CellInfo)+1;
                    CellInfo((end+1):(end+CellPreallocationNumber)) = InitialisedCellInfo;
                    EmptyCellEntries = [EmptyCellEntries true(1,CellPreallocationNumber)];
                end
                
                % Properties only updated on the first occurrence of a cell
                
                CellInfo(CellEntry).CellNumber = CellEntry;
                CellInfo(CellEntry).TrapNumber = TI;
                CellInfo(CellEntry).CellLabel = ttacObject.ReturnLabel(TP,TI,CI);
                CellInfo(CellEntry).(PriorRadiiStrings{end}) = ttacObject.ReturnCellRadii(TP,TI,CI);%set prior to be the radus found by matt's hough transform
                CellInfo(CellEntry).(PriorAnglesStrings{end}) = ttacObject.ReturnCellAngles(TP,TI,CI);%set prior angles to be evenly spaced
                %it may seem strange that both these are only taken for the
                %first occurence of a cell. This is because the prior is
                %set to the segmentation result once the cells are
                %segmented and 'left behind' to be the prior for future
                %cells. May want to change this to be more sophisticated at
                %some point.
                
                EmptyCellEntries(CellEntry) = false;
                
                
                
                % Properties updated on ever occurrence of a cell
                
                CellInfo(CellEntry).(CellNumberTimelapseStrings{end}) = CI;
                CellInfo(CellEntry).(TimePointStrings{end}) = TP;
                CellInfo(CellEntry).(CellCentreStrings{end}) = ttacObject.ReturnCellCentreAbsolute(TP,TI,CI);
                CellInfo(CellEntry).(TrapCentreStrings{end}) = ttacObject.ReturnTrapCentre(TP,TI);
                CellInfo(CellEntry).TimePointsPresent = CellInfo(CellEntry).TimePointsPresent+1 ;
                CellInfo(CellEntry).UpdatedThisTimepoint = true;
                CellInfo(CellEntry).(CellOultineStrings{end}) = ttacObject.ReturnCellOutlinesForSingleCell(TP,TI,CI);
                CellInfo(CellEntry).ExpectedCentre = CellInfo(CellEntry).(CellCentreStrings{end});
                NumberOfCellsUpdated = NumberOfCellsUpdated+1;
                
            end
            
            
        end
        
    else %not the first timepoint
        
        ExpectedCentreStack = reshape([CellInfo(UpdatedPreviousTimepoint).ExpectedCentre],2,[]);
        ExpectedCentreStack = ExpectedCentreStack';
        ProspectiveImageStack = ttacObject.ReturnSubImages([CellInfo(UpdatedPreviousTimepoint).(TimePointStrings{end})] + 1,round(ExpectedCentreStack), ProspectiveImageSize,CrossCorrelationChannel,'median');
        ProspectiveTrapImageStack = ttacObject.ReturnSubImages([CellInfo(UpdatedPreviousTimepoint).(TimePointStrings{end})] + 1,round(ExpectedCentreStack), ProspectiveImageSize,'trap','median');
        
        for CN = find(UpdatedPreviousTimepoint)
            CellInfo(CN).ProspectiveImage = ProspectiveImageStack(:,:,CN);
            CellInfo(CN).ProspectiveTrapImage = ProspectiveTrapImageStack(:,:,CN);
            
            CellInfo(CN).(TimePointStrings{end}) = TP;
            CellInfo(CN).(TrapCentreStrings{end}) = ttacObject.ReturnTrapCentre(TP,CellInfo(CN).TrapNumber);
            
            
            
        end
        
        for celli = find(UpdatedPreviousTimepoint)
            
            %make template
            
            CellImage = CellInfo(celli).(CellImageStrings{end});
            CellOutline = imfill(CellInfo(celli).(CellOultineStrings{end}),'holes');
            CellOutline = bwmorph(CellOutline,'erode');
            ProspectiveImage = CellInfo(celli).ProspectiveImage;
            TrapImageOfPredictedCellLocation = CellInfo(celli).ProspectiveTrapImage;
            
            CellMean = mean(CellImage(CellOutline));
            CellImage(~CellOutline) = CellMean;
            
            %do cross correlation
            PredictedCellLocation = normxcorr2(CellImage,ProspectiveImage);
            PredictedCellLocation = (PredictedCellLocation(ceil(SubImageSize/2):(end-floor(SubImageSize/2)),ceil(SubImageSize/2):(end-floor(SubImageSize/2))));
            PredictedCellLocation = CrossCorrelationPrior.*PredictedCellLocation;
            
            %remove trap cells. expand to remove other cells;
            TrapImageOfPredictedCellLocation = TrapImageOfPredictedCellLocation>CrossCorrelationTrapThreshold;
            TrapImageOfPredictedCellLocation = bwmorph(TrapImageOfPredictedCellLocation,'dilate');
            PredictedCellLocation(TrapImageOfPredictedCellLocation) = 0;
            [value,Index] = max(PredictedCellLocation(:));
            
            [ynewcell,xnewcell] = ind2sub(size(PredictedCellLocation),Index);
                
            if value>CrossCorrelationValueThreshold
                
                %visualising trackin
                if ttacObject.Parameters.ActiveContour.visualise>0;
                    if FirstDisplay == true;
                        pimhandle = figure;
                        ccimhandle = figure;
                        FirstDisplay = false;
                    end
                    
                    figure(pimhandle);
                    imshow(ProspectiveImage,[])
                    hold on
                    plot(xnewcell,ProspectiveImageSize-ynewcell+1,'or')
                    hold off
                    title(sprintf('timepoint %d',TP))
                    
                    figure(ccimhandle);
                    imshow(PredictedCellLocation,[]);
                    title(sprintf('max value %d',value));
                    
                    if ttacObject.Parameters.ActiveContour.visualise>2;
                        pause;
                    else
                        pause(1)
                    end
 
                end
                
                ynewcell = ynewcell - ceil(ProspectiveImageSize/2) + CellInfo(celli).ExpectedCentre(2);
                xnewcell = xnewcell - ceil(ProspectiveImageSize/2) + CellInfo(celli).ExpectedCentre(1);
                
                if ttacObject.TrapPresentBoolean
                    ynewcellRelative = round(ynewcell - CellInfo(celli).(TrapCentreStrings{end})(2) +...
                                                            ceil(ttacObject.TrapImageSize(1)/2));
                    xnewcellRelative = round(xnewcell - CellInfo(celli).(TrapCentreStrings{end})(1) +...
                                                            ceil(ttacObject.TrapImageSize(2)/2));
                else
                    ynewcellRelative = round(ynewcell);
                    xnewcellRelative = round(xnewcell);
                end
                %write new cell info. Need to make good.
                
                if ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(CellInfo(celli).TrapNumber).cellsPresent
                    if any(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(CellInfo(celli).TrapNumber).cellLabel == CellInfo(celli).CellLabel)
                        NewCellIndex = find(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(CellInfo(celli).TrapNumber).cellLabel == CellInfo(celli).CellLabel);
                    else
                        NewCellIndex = length(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(CellInfo(celli).TrapNumber).cell) +1;
                    end
                else
                    ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(CellInfo(celli).TrapNumber).cellsPresent = true;
                    NewCellIndex = 1;
                end
                
                ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(CellInfo(celli).TrapNumber).cell(NewCellIndex).cellCenter = [xnewcellRelative ynewcellRelative];
                ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(CellInfo(celli).TrapNumber).cell(NewCellIndex).cellRadius = 8;
                ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(CellInfo(celli).TrapNumber).cellLabel(NewCellIndex) = CellInfo(celli).CellLabel;
                
                
                
                CellInfo(celli).TimePointsPresent = CellInfo(celli).TimePointsPresent+1;
                CellInfo(celli).UpdatedThisTimepoint = true;
                CellInfo(celli).(CellNumberTimelapseStrings{end}) = NewCellIndex;
                CellInfo(celli).(CellCentreStrings{end}) = [xnewcell ynewcell];
                NumberOfCellsUpdated = NumberOfCellsUpdated+1;
            end
            
            
        end
        
        %get cell outline from previous timepoint
        %make template for cross correlation
        %do special cross correlation
        
    end
    
    %Get Subimages of Cells
    
    CellNumbers = find([CellInfo(:).UpdatedThisTimepoint]);
    
    [AllCellTransformedImageStack,CellImageStack] = ttacObject.ReturnTransformedImagesForSingleCell([CellInfo([CellInfo(:).UpdatedThisTimepoint]).(TimePointStrings{end})],[CellInfo([CellInfo(:).UpdatedThisTimepoint]).TrapNumber],[CellInfo([CellInfo(:).UpdatedThisTimepoint]).(CellNumberTimelapseStrings{end})]);
    
    
    
    %redistribute amongst data structure
    
    for CN = 1:NumberOfCellsUpdated
        CellInfo(CellNumbers(CN)).(TransformedImageStrings{end}) = AllCellTransformedImageStack(:,:,CN);
        CellInfo(CellNumbers(CN)).(CellImageStrings{end}) = CellImageStack(:,:,CN);
        
    end
    
    
    
    %% actually do the segmentation function
    
    %being segmented for the first time
    CellsToSegmentFirstTP = ...
        find([CellInfo(:).UpdatedThisTimepoint] & ([CellInfo(:).TimePointsPresent]==slice_size) );
    
    
    %cells that have been previously segmented and have a previous
    %timepoint to use
    CellsToSegmentPreviouslySegmented = ...
        find([CellInfo(:).UpdatedThisTimepoint] & ([CellInfo(:).TimePointsPresent]>slice_size) &(mod([CellInfo(:).TimePointsPresent]-slice_size,keepers)==0) );
    
    UsePreviousTimepoint = [false(size(CellsToSegmentFirstTP)) true(size(CellsToSegmentPreviouslySegmented))];
    
    CellsToSegment = [CellsToSegmentFirstTP CellsToSegmentPreviouslySegmented];
    
    RadiiResultsCellArray = cell(size(CellsToSegment));
    AnglesResultsCellArray = cell(size(CellsToSegment));
    
    TimePointsToWrite = zeros(keepers*length(CellsToSegment),1);
    TrapIndicesToWrite = TimePointsToWrite;
    CellIndicesToWrite = TimePointsToWrite;
    CellRadiiToWrite = zeros(size(TimePointsToWrite,1),OptPoints);
    AnglesToWrite = CellRadiiToWrite;
    
    parfor CNi = 1:length(CellsToSegment)
        %divided loop into parallel slow part and relatively fast write
        %part.
        
        if TP>=TPtoStartSegmenting
            
            
            [TranformedImageStack,PriorRadiiStack] = getStacksFromCellInfo(CellInfo,PriorRadiiStrings,TransformedImageStrings,CellsToSegment(CNi));
            
            if UsePreviousTimepoint(CNi)
                %do segmentation of previously segmented cell
                [RadiiResultsCellArray{CNi},AnglesResultsCellArray{CNi}] = ...
                    ACMethods.PSORadialTimeStack(TranformedImageStack,ACparameters,FauxCentersStack,PriorRadiiStack,CellInfo(CellsToSegment(CNi)).PreviousTimepointResult);
                
            else
                %do first timepoint segmentation - so no previous timepoint
                [RadiiResultsCellArray{CNi},AnglesResultsCellArray{CNi}] = ...
                    ACMethods.PSORadialTimeStack(TranformedImageStack,ACparameters,FauxCentersStack,PriorRadiiStack);
                
            end
            
            %put all radii in the CellInfoarray
        end
    end
    
    CellsWritten = 1;
    
    for CNi = 1:length(CellsToSegment)
        
        CN = CellsToSegment(CNi);
        
        if TP>=TPtoStartSegmenting
            for RN = 1:slice_size
                CellInfo(CN).(PriorRadiiStrings{RN}) = RadiiResultsCellArray{CNi}(RN,:);
                CellInfo(CN).(PriorAnglesStrings{RN}) = AnglesResultsCellArray{CNi}(RN,:);
            end
            
            %write results to keep to the timelapse object
            for RN = 1:keepers
                
                %write the results to keep (1:keepers) to the cTimelapse object
                %ttacObject.WriteACResults(CellInfo(CN).(TimePointStrings{RN}),CellInfo(CN).TrapNumber,CellInfo(CN).(CellNumberTimelapseStrings{RN}),CellInfo(CN).(PriorRadiiStrings{RN}),CellInfo(CN).(PriorAnglesStrings{RN}))
                
                TimePointsToWrite(CellsWritten) = CellInfo(CN).(TimePointStrings{RN});
                TrapIndicesToWrite(CellsWritten) = CellInfo(CN).TrapNumber;
                CellIndicesToWrite(CellsWritten) = CellInfo(CN).(CellNumberTimelapseStrings{RN});
                CellRadiiToWrite(CellsWritten,:) = RadiiResultsCellArray{CNi}(RN,:);
                AnglesToWrite(CellsWritten,:) = AnglesResultsCellArray{CNi}(RN,:);
                
                CellsWritten = CellsWritten+1;
                
                
                
            end
            
            CellInfo(CN).PreviousTimepointResult = RadiiResultsCellArray{CNi}(keepers,:);
            
            
        else
            
            CellInfo(CN).PreviousTimepointResult = CellInfo(CN).((PriorRadiiStrings{1}));
        end
    end
    
    %write results on mass
    if TP>=TPtoStartSegmenting && ~isempty(CellsToSegment)
        ttacObject.WriteACResults(TimePointsToWrite,TrapIndicesToWrite,CellIndicesToWrite,CellRadiiToWrite,AnglesToWrite)
    end
    
    
    for celli = CellsToSegmentPreviouslySegmented
                    CellInfo(celli).(CellOultineStrings{end}) = ttacObject.ReturnCellOutlinesForSingleCell(TP,CellInfo(celli).TrapNumber,CellInfo(celli).(CellNumberTimelapseStrings{end}));
                    CellInfo(celli).ExpectedCentre = CellInfo(celli).(CellCentreStrings{end});

    end
    
    
    TimeOfTimepoint = toc;
    fprintf('timepoint analysed in %.2f seconds \n',TimeOfTimepoint);
    
end

%end of the timeperiod to be segmented.write remaining priors to the
%segmentation results.


for CN = find([CellInfo(:).UpdatedThisTimepoint])
    
    %take cells which for which no cell was present at the previous
    %timepoint and makes the segmentation result the prior result for
    %all cells.
    for RN = setdiff((1:slice_size),1:(mod(CellInfo(CN).TimePointsPresent-slice_size,keepers+1)))
        
        %write the results to keep (1:keepers) to the cTimelapse object
        
        ttacObject.WriteACResults(CellInfo(CN).(TimePointStrings{RN}),CellInfo(CN).TrapNumber,CellInfo(CN).(CellNumberTimelapseStrings{RN}),CellInfo(CN).(PriorRadiiStrings{RN}),CellInfo(CN).(PriorAnglesStrings{RN}))
        
    end
    
    
    CellInfo(CN) = InitialisedCellInfo;
    EmptyCellEntries(CN) = true;
end

end

function [TranformedImageStack,priorRadiiStack] = getStacksFromCellInfo(CellInfo,PriorRadiiStrings,TransformedImageStrings,CN)
%function [TranformedImageStack,priorRadiiStack] = getStacksFromCellInfo(cellInfo,PriorRadiiStrings,TransformedImageStrings,CN);

%small function to get the info out of CellInfo and into a stack as the
%optimiser wants it.
L = size(PriorRadiiStrings,2);

TranformedImageStack = zeros([size(CellInfo(CN).(TransformedImageStrings{1})) L]);
priorRadiiStack = zeros([L,size(CellInfo(CN).(PriorRadiiStrings{1}),2)]);
for i=1:L
    TranformedImageStack(:,:,i) = CellInfo(CN).(TransformedImageStrings{i});
    priorRadiiStack(i,:) = CellInfo(CN).(PriorRadiiStrings{i});
end


end



