function ttacObject = SegmentConsecutiveTimePoints(ttacObject,FirstTimepoint,LastTimepoint,varargin)


if size(varargin,2)>0
    
    FixFirstTimePointBoolean = varargin{1};
else
    FixFirstTimePointBoolean = false;
    
end

slice_size = 2;%slice of the timestack you look at in one go
keepers = 1;%number of timpoints from that slice that you will keep (normally slice_size-1)
SubImageSize = 61;
OptPoints = 6;
ITparameters = struct;%image transformation parameters
SEGparameters = struct; %SegmentConsecutiveTimepoints parameters


if false
SEGparameters.ImageTransformFunction = 'radial_gradient_DICangle_and_radialaddition';
ITparameters.DICangle = 135;
ITparameters.Rdiff = 3;
ITparameters.anglediff = 2*pi/40;
end

if true
    SEGparameters.ImageTransformFunction = 'radial_gradient';
    ITparameters.invert = true;
end

ACparameters.alpha = 0.01;%weighs non image parts (none at the moment)
ACparameters.beta =100; %weighs difference between consecutive time points.
ACparameters.R_min = 5;%5;
ACparameters.R_max = 18;%30; %was initial radius of starting contour. Now it is the maximum size of the cell (must be larger than 5)
ACparameters.opt_points = OptPoints;
ACparameters.visualise = 1; %degree of visualisation (0,1,2,3)
ACparameters.EVALS = 6000; %maximum number of iterations passed to fmincon
ACparameters.spread_factor = 2; %used in particle swarm optimisation. determines spread of initial particles.
ACparameters.spread_factor_prior = 0.5; %used in particle swarm optimisation. determines spread of initial particles.
ACparameters.seeds = 60;
ACparameters.TerminationEpoch = 150;%number of epochs of one unchanging point being the best before optimisation closes.

ACparameters = ttacObject.Parameters.ActiveContour;
ITparameters = ttacObject.Parameters.ImageTransformation;
slice_size = ttacObject.Parameters.ImageSegmentation.slice_size; %2;%slice of the timestack you look at in one go
keepers = ttacObject.Parameters.ImageSegmentation.keepers;    %1;%number of timpoints from that slice that you will keep (normally slice_size-1)
SubImageSize = ttacObject.Parameters.ImageSegmentation.SubImageSize;%61;
OptPoints = ttacObject.Parameters.ImageSegmentation.OptPoints;%6;

CellPreallocationNumber = 200;

%protects program from super crashing out by opening and closing a million
%images.
if LastTimepoint-FirstTimepoint>50
    ACparameters.visualise = 0;
end


%FauxCentersStack is just a filler for the PSO optimisation that takes centers
%(because in this code the centers are always at the centers of the image).
%Better to assign it here than every time in the loop.
FauxCentersStack = round(SubImageSize/2)*ones(slice_size,2);

%size of trap image stored in Timelapse. If there are no traps, this is the
%size of the image.


Timepoints = FirstTimepoint:LastTimepoint;

%% NOTES

%load in images for the slice size
%construct transformed image stacks for each cell at those timepoints
%run those stacks through the segmentation
%BEGIN LOOP
%delete the first image of the stack
%load the next image image
%transform for all the cells in the latest image
%update all the little stacks
%segment all of those
%END LOOP


%celllabel(1) corresponds to cell(1) information
%cell centre is in xy coordinates relative to trapimage edge, so need to
%subtract half trap image dimensions and add trap centre to cell centre to get
%true centre.

%store cell information in a structure array


% CellInfo.TrapNumber
% CellInfo.CellLabel
% CellInfo.Centre
% CellInfo.TransformedImageStack
% CellInfo.Priors
% CellInfo.SegmentationResult
% CellInfo.PreviousTimepointResult
%
%


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

CellCentreStrings = cell(1,slice_size);
TrapCentreStrings = cell(1,slice_size);
TransformedImageStrings = cell(1,slice_size);
PriorRadiiStrings = cell(1,slice_size);
PriorAnglesStrings = cell(1,slice_size);
CellNumberTimelapseStrings = cell(1,slice_size);
TimePointStrings = cell(1,slice_size);

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
end



InitialisedCellInfo = CellInfo;

CellInfo(1:CellPreallocationNumber) = InitialisedCellInfo;

EmptyCellEntries = true(1,CellPreallocationNumber);

%% take the first timpoint,load the image, and put all the data into the CellInfo structure

TP = Timepoints(1);

NumberOfCellsUpdated = 0;

fprintf('timepoint %d \n',TP)

for TI = ttacObject.TrapsToCheck(TP)
    
    for CI = ttacObject.CellsToCheck(TP,TI)
        
        
        %fprintf('timepoint %d; trap %d ; cell %d \n',TP,TI,CI)
        
        CellEntry = find(EmptyCellEntries,1);
        
        %If there are no available cell entries left initialise a
        %whole new tranch of cell entries
        if isempty(CellEntry)
            CellEntry = length(CellInfo)+1;
            CellInfo((end+1):(end+CellPreallocationNumber)) = InitialisedCellInfo;
            EmptyCellEntries = [EmptyCellEntries true(1,CellPreallocationNumber)];
        end
        
        EmptyCellEntries(CellEntry) = false;
        CellInfo(CellEntry).CellNumber = CellEntry;
        CellInfo(CellEntry).TrapNumber = TI;
        CellInfo(CellEntry).CellLabel = ttacObject.ReturnLabel(TP,TI,CI);
        CellInfo(CellEntry).(CellNumberTimelapseStrings{end}) = CI;
        CellInfo(CellEntry).(TimePointStrings{end}) = TP;
        CellInfo(CellEntry).(CellCentreStrings{end}) = ttacObject.ReturnCellCentreAbsolute(TP,TI,CI); %absolute cell position
        CellInfo(CellEntry).(TrapCentreStrings{end}) = ttacObject.ReturnTrapCentre(TP,TI);
        
        CellInfo(CellEntry).(PriorRadiiStrings{end}) = ttacObject.ReturnCellRadii(TP,TI,CI);
        CellInfo(CellEntry).(PriorAnglesStrings{end}) = ttacObject.ReturnCellAngles(TP,TI,CI);
        CellInfo(CellEntry).TimePointsPresent = CellInfo(CellEntry).TimePointsPresent+1 ;
        CellInfo(CellEntry).UpdatedThisTimepoint = true;
        NumberOfCellsUpdated = NumberOfCellsUpdated+1;
        
    end
    
    
end

%Get Subimages of Cells

CellNumbers = find([CellInfo(:).UpdatedThisTimepoint]);

ImageStack = ttacObject.ReturnTransformedImagesForSingleCell([CellInfo([CellInfo(:).UpdatedThisTimepoint]).(TimePointStrings{end})],[CellInfo([CellInfo(:).UpdatedThisTimepoint]).TrapNumber],[CellInfo([CellInfo(:).UpdatedThisTimepoint]).(CellNumberTimelapseStrings{end})]);



%redistribute amongst data structure

for CN = 1:NumberOfCellsUpdated
        CellInfo(CellNumbers(CN)).(TransformedImageStrings{end}) = ImageStack(:,:,CN);
end

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




%% loop through the rest of the timepoints
for TP = Timepoints(2:end)
    
    
fprintf('timepoint %d \n',TP)
            
    UpdatedPreviousTimepoint = [CellInfo(:).UpdatedThisTimepoint];

    for CN = find((~UpdatedPreviousTimepoint) & (~EmptyCellEntries))
        %the indexing here is difficult to follow but the idea is that if
        %no cell is present at the previous timepoint but there is data in
        %the array we need to save the 'priors' since these will be our
        %best guess at the contour since we can't do anymore searches since
        %our data for this cell has run out. So we take the slices that
        %have not been segmented and saved but have been segmented as part
        %of the segmentation of earlier cells (RN's) and save them to the
        %appropriate timepoints (TP + RN -slice_size -1). 
        
        
        %take cells which for which no cell was present at the previous
        %timepoint and makes the segmentation result the prior result for
        %all cells.
        for RN = setdiff((1:slice_size-1),1:(mod(CellInfo(CN).TimePointsPresent+1-slice_size,keepers)))
            %this is set_diff(all entries with priors, those already written to data structure by segmentation )
            
            %write the results to keep to the cTimelapse object
            ttacObject.WriteACResults(CellInfo(CN).(TimePointStrings{RN}),CellInfo(CN).TrapNumber,CellInfo(CN).(CellNumberTimelapseStrings{RN}),CellInfo(CN).(PriorRadiiStrings{RN}),CellInfo(CN).(PriorAnglesStrings{RN}))
        end
        
        
    CellInfo(CN) = InitialisedCellInfo;
    EmptyCellEntries(CN) = true;
    end
    %move data 'back in time' and update update info
    [CellInfo(UpdatedPreviousTimepoint).UpdatedThisTimepoint] = deal(false);
    for SN = 1:(slice_size-1)
       
        [CellInfo(UpdatedPreviousTimepoint).(CellCentreStrings{SN})] =deal(CellInfo(UpdatedPreviousTimepoint).(CellCentreStrings{SN+1}));
        [CellInfo(UpdatedPreviousTimepoint).(TrapCentreStrings{SN})] =deal(CellInfo(UpdatedPreviousTimepoint).(TrapCentreStrings{SN+1}));
        [CellInfo(UpdatedPreviousTimepoint).(TransformedImageStrings{SN})] =deal(CellInfo(UpdatedPreviousTimepoint).(TransformedImageStrings{SN+1}));
        [CellInfo(UpdatedPreviousTimepoint).(PriorRadiiStrings{SN})] = deal(CellInfo(UpdatedPreviousTimepoint).(PriorRadiiStrings{SN+1}));          
        [CellInfo(UpdatedPreviousTimepoint).(PriorAnglesStrings{SN})] = deal(CellInfo(UpdatedPreviousTimepoint).(PriorAnglesStrings{SN+1}));          
        [CellInfo(UpdatedPreviousTimepoint).(CellNumberTimelapseStrings{SN})] = deal(CellInfo(UpdatedPreviousTimepoint).(CellNumberTimelapseStrings{SN+1}));          
        [CellInfo(UpdatedPreviousTimepoint).(TimePointStrings{SN})] = deal(CellInfo(UpdatedPreviousTimepoint).(TimePointStrings{SN+1}));          
        
    end
    
    

    NumberOfCellsUpdated = 0;
    %checksum =0;
    
    PreviousTrapNumbers = [CellInfo(:).TrapNumber];
    PreviousCellLabels = [CellInfo(:).CellLabel];
    
    
    
    for TI = ttacObject.TrapsToCheck(TP)
        for CI = ttacObject.CellsToCheck(TP,TI);
            
            
            %fprintf('timepoint %d; trap %d ; cell %d \n',TP,TI,CI)
            
            %if the cell was previously recorded, put it
            %there.Otherwise, put in an empty place
            CellEntry = find((PreviousTrapNumbers==TI) & (PreviousCellLabels==ttacObject.ReturnLabel(TP,TI,CI)));
            if isempty(CellEntry)
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
                
            end
            
            
            % Properties updated on ever occurrence of a cell
            
            CellInfo(CellEntry).(CellNumberTimelapseStrings{end}) = CI;
            CellInfo(CellEntry).(TimePointStrings{end}) = TP;
            CellInfo(CellEntry).(CellCentreStrings{end}) = ttacObject.ReturnCellCentreAbsolute(TP,TI,CI);
            CellInfo(CellEntry).(TrapCentreStrings{end}) = ttacObject.ReturnTrapCentre(TP,TI);
            CellInfo(CellEntry).TimePointsPresent = CellInfo(CellEntry).TimePointsPresent+1 ;
            CellInfo(CellEntry).UpdatedThisTimepoint = true;
            NumberOfCellsUpdated = NumberOfCellsUpdated+1;
            %checksum = sum([CellInfo(:).UpdatedThisTimepoint],2);
            
        end
        
        
    end
    
    %Get Subimages of Cells
    
    CellNumbers = find([CellInfo(:).UpdatedThisTimepoint]);

    ImageStack = ttacObject.ReturnTransformedImagesForSingleCell([CellInfo([CellInfo(:).UpdatedThisTimepoint]).(TimePointStrings{end})],[CellInfo([CellInfo(:).UpdatedThisTimepoint]).TrapNumber],[CellInfo([CellInfo(:).UpdatedThisTimepoint]).(CellNumberTimelapseStrings{end})]);

 
    
    %redistribute amongst data structure
    
    for CN = 1:NumberOfCellsUpdated
        CellInfo(CellNumbers(CN)).(TransformedImageStrings{end}) = ImageStack(:,:,CN);
    end
    
    %% actually do the segmentation function
    for CN = find([CellInfo(:).UpdatedThisTimepoint] & ([CellInfo(:).TimePointsPresent]==slice_size) )
        if TP>=TPtoStartSegmenting
            
            
            %do first timepoint segmentation - so no previous timepoint
            [TranformedImageStack,PriorRadiiStack] = getStacksFromCellInfo(CellInfo,PriorRadiiStrings,TransformedImageStrings,CN);
            [RadiiResult,AnglesResult] = ACMethods.PSORadialTimeStack(TranformedImageStack,ACparameters,FauxCentersStack,PriorRadiiStack);
            %fprintf('Segmenting Timepoint %d ;  trap %d ;  cell  %d ;\n',TP,TI,CN)
            
            %For debugging
            %         RadiiResult = PriorRadiiStack;
            %         AnglesResult = repmat(DefaultAngles,slice_size,1);
            
            %put all radii in the CellInfoarray
            for RN = 1:slice_size
                CellInfo(CN).(PriorRadiiStrings{RN}) = RadiiResult(RN,:);
                CellInfo(CN).(PriorAnglesStrings{RN}) = AnglesResult(RN,:);
            end
            
            %write results to keep to the timelapse object
            for RN = 1:keepers
                
                %write the results to keep (1:keepers) to the cTimelapse object
                ttacObject.WriteACResults(CellInfo(CN).(TimePointStrings{RN}),CellInfo(CN).TrapNumber,CellInfo(CN).(CellNumberTimelapseStrings{RN}),CellInfo(CN).(PriorRadiiStrings{RN}),CellInfo(CN).(PriorAnglesStrings{RN}))
                
            end
            
            CellInfo(CN).PreviousTimepointResult = RadiiResult(keepers,:);
            
            
        else
            
            CellInfo(CN).PreviousTimepointResult = CellInfo(CN).((PriorRadiiStrings{1}));
        end
        
    end
    
    for CN = find([CellInfo(:).UpdatedThisTimepoint] & ([CellInfo(:).TimePointsPresent]>slice_size) &(mod([CellInfo(:).TimePointsPresent]-slice_size,keepers)==0) )
        
        %do later timepoint segmentations
        [TranformedImageStack,PriorRadiiStack] = getStacksFromCellInfo(CellInfo,PriorRadiiStrings,TransformedImageStrings,CN);
        [RadiiResult,AnglesResult] = ACMethods.PSORadialTimeStack(TranformedImageStack,ACparameters,FauxCentersStack,PriorRadiiStack,CellInfo(CN).PreviousTimepointResult);
        %fprintf('Segmenting Timepoint %d ;  trap %d ;  cell  %d ;\n',TP,TI,CN)
        
        
        %For debugging
        %         RadiiResult = PriorRadiiStack;
        %         AnglesResult = repmat(DefaultAngles,slice_size,1);
        %
        %put all radii in the CellInfoarray
        for RN = 1:slice_size
            CellInfo(CN).(PriorRadiiStrings{RN}) = RadiiResult(RN,:);
            CellInfo(CN).(PriorAnglesStrings{RN}) = AnglesResult(RN,:);
        end
        
        %write results to keep to the timelapse object
        for RN = 1:keepers
            %write the results to keep (1:keepers) to the cTimelapse object
            ttacObject.WriteACResults(CellInfo(CN).(TimePointStrings{RN}),CellInfo(CN).TrapNumber,CellInfo(CN).(CellNumberTimelapseStrings{RN}),CellInfo(CN).(PriorRadiiStrings{RN}),CellInfo(CN).(PriorAnglesStrings{RN}))
            
        end
        
        CellInfo(CN).PreviousTimepointResult = RadiiResult(keepers,:);
        
        
        
        
    end
    
    
    
    
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
