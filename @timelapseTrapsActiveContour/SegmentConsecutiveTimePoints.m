function ttacObject = SegmentConsecutiveTimePoints(ttacObject,FirstTimepoint,LastTimepoint)


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

%make the image transform function indicated by the string in SEGparameters
%a function handle to act on image stacks.
ImageTransformFunction = str2func(['ACImageTransformations.' ttacObject.Parameters.ImageSegmentation.ImageTransformFunction]);

% DICangle = -45;
% 
% sub_image_size = 30; %subimage is a size 2*sub_image_size +1 square.

%FauxCentersStack is just a filler for the PSO optimisation that takes centers
%(because in this code the centers are always at the centers of the image).
%Better to assign it here than every time in the loop.
FauxCentersStack = round(SubImageSize/2)*ones(slice_size,2);

%size of trap image stored in Timelapse. If there are no traps, this is the
%size of the image.
if ttacObject.TrapPresentBoolean
    TrapImageSize = 2*[ttacObject.TimelapseTraps.cTrapSize.bb_width ttacObject.TimelapseTraps.cTrapSize.bb_height]+1;
else
    TrapImageSize = size(ttacObject.TimelapseTraps.returnSingleTimepoint(FirstTimepoint));
end
%angles vector given as a default when no other is provided
DefaultAngles = linspace(0,2*pi,(OptPoints+1));
DefaultAngles = DefaultAngles(1:(end-1));

Timepoints = FirstTimepoint:LastTimepoint;


%CellsToSegment is a logical encoding which cells to plot (and therefore to
%active contour segment) as true points at [trapinfo CellLabel]
CellsToPlotGiven = ttacObject.Parameters.ImageSegmentation.CellsToPlotGiven;
if ~isempty(ttacObject.TimelapseTraps.cellsToPlot)
    CellsToSegment = full(ttacObject.TimelapseTraps.cellsToPlot);
else
    CellsToPlotGiven = false;
end

CellsToSegment(1,1) = true;
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


if ~any(ismember(Timepoints,1:length(ttacObject.TimelapseTraps.cTimepoint)))
    error('timpoints passed to SegmentConsecutiveTimePoints are not valid timepoints\n')
end

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
end



InitialisedCellInfo = CellInfo;

CellInfo(1:CellPreallocationNumber) = InitialisedCellInfo;

EmptyCellEntries = true(1,CellPreallocationNumber);

%% take the first timpoint,load the image, and put all the data into the CellInfo structure

TP = Timepoints(1);

Image = ttacObject.TimelapseTraps.returnSingleTimepoint(TP);
% Image = imread([ttacObject.TimelapseTraps.timelapseDir '\' ttacObject.TimelapseTraps.cTimepoint(TP).filename{1}((end-33):end)]);
% Image = imrotate(Image,ttacObject.TimelapseTraps.image_rotation,'bilinear','loose');
if ttacObject.TrapPresentBoolean
    TrapImage = conv2(1*full(ttacObject.TrapLocation{TP}),ttacObject.TrapPixelImage,'same');
end
NumberOfCellsUpdated = 0;

fprintf('timepoint %d \n',TP)
            
for TI = 1:size(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo,2)
    
    if ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellsPresent
        for CI = 1:size(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell,2)
            
            if (CellsToPlotGiven && CellsToSegment(TI,ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellLabel(CI))) || ~CellsToPlotGiven
            
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
            CellInfo(CellEntry).CellLabel = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellLabel(CI);
            CellInfo(CellEntry).(CellNumberTimelapseStrings{end}) = CI;
            CellInfo(CellEntry).(CellCentreStrings{end}) =double(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).cellCenter);
            
            if ttacObject.TrapPresentBoolean
                CellInfo(CellEntry).(TrapCentreStrings{end}) = [ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(TI).xcenter ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(TI).ycenter];
            else
                CellInfo(CellEntry).(TrapCentreStrings{end}) = [0 0];
            end
            
            CellInfo(CellEntry).(PriorRadiiStrings{end}) = double(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).cellRadius)*ones(1,OptPoints);%set prior to be the radus found by matt's hough transform
            CellInfo(CellEntry).(PriorAnglesStrings{end}) = DefaultAngles;%set prior angles to be evenly spaced
            CellInfo(CellEntry).TimePointsPresent = CellInfo(CellEntry).TimePointsPresent+1 ;
            CellInfo(CellEntry).UpdatedThisTimepoint = true;
            NumberOfCellsUpdated = NumberOfCellsUpdated+1;
            end   
        end
    end
    
end

%Get Subimages of Cells
CellCentres = reshape([CellInfo([CellInfo(:).UpdatedThisTimepoint]).(CellCentreStrings{end})],2,[]);
TrapCentres = reshape([CellInfo([CellInfo(:).UpdatedThisTimepoint]).(TrapCentreStrings{end})],2,[]);

if ttacObject.TrapPresentBoolean
    TrueCentres = CellCentres +TrapCentres - repmat([ttacObject.TimelapseTraps.cTrapSize.bb_width;ttacObject.TimelapseTraps.cTrapSize.bb_height],1,NumberOfCellsUpdated);
else
    TrueCentres = CellCentres;
end

CellNumbers = find([CellInfo(:).UpdatedThisTimepoint]);

%shouldn't happen, but it has.
TrueCentres(TrueCentres<1 | TrueCentres>512) = 1;

ImageStack = ACBackGroundFunctions.get_cell_image(Image,SubImageSize,TrueCentres');

%transform images

if ttacObject.TrapPresentBoolean  
    TrapImageStack = ACBackGroundFunctions.get_cell_image(TrapImage,SubImageSize,TrueCentres');
    %ImageStack = ACImageTransformations.radial_gradient_DICangle_and_radialaddition(ImageStack,ITparameters,TrapImageStack);
    ImageStack = ImageTransformFunction(ImageStack,ITparameters,TrapImageStack);
    
else
    ImageStack = ImageTransformFunction(ImageStack,ITparameters);
end

%redistribute amongst data structure

for CN = 1:NumberOfCellsUpdated
        CellInfo(CellNumbers(CN)).(TransformedImageStrings{end}) = ImageStack(:,:,CN);
end

%% loop through the rest of the timepoints
for TP = Timepoints(2:end)
    
    
fprintf('timepoint %d \n',TP)
            
    UpdatedPreviousTimepoint = [CellInfo(:).UpdatedThisTimepoint];

    for CN = find((~UpdatedPreviousTimepoint) & (~EmptyCellEntries))
        
        %take cells which for which no cell was present at the previous
        %timepoint and makes the segmentation result the prior result for
        %all cells.
        for RN = (keepers - (mod(CellInfo(CN).TimePointsPresent-slice_size,keepers))):(slice_size-1)
            [px,py] = ACBackGroundFunctions.get_full_points_from_radii((CellInfo(CN).(PriorRadiiStrings{RN}))',(CellInfo(CN).(PriorAnglesStrings{RN}))',CellInfo(CN).(CellCentreStrings{RN}),TrapImageSize);
            TempResultImage = false(TrapImageSize);
            TempResultImage(py+TrapImageSize(1,1)*(px-1))=true;
            %write the results to keep (1:keepers) to the cTimelapse object
            ttacObject.TimelapseTraps.cTimepoint(TP+RN-slice_size).trapInfo(CellInfo(CN).TrapNumber).cell(CellInfo(CN).(CellNumberTimelapseStrings{RN})).segmented = sparse(TempResultImage);  
            
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
        
    end
    
    

    
    Image = ttacObject.TimelapseTraps.returnSingleTimepoint(TP);
    %Image = imread([ttacObject.TimelapseTraps.timelapseDir '\' ttacObject.TimelapseTraps.cTimepoint(TP).filename{1}((end-33):end)]);
    %Image = imrotate(Image,ttacObject.TimelapseTraps.image_rotation,'bilinear','loose');
    
    if ttacObject.TrapPresentBoolean
        TrapImage = conv2(1*full(ttacObject.TrapLocation{TP}),ttacObject.TrapPixelImage,'same');
    end
    NumberOfCellsUpdated = 0;
    %checksum =0;
    
    PreviousTrapNumbers = [CellInfo(:).TrapNumber];
    PreviousCellLabels = [CellInfo(:).CellLabel];
    
    
    
    for TI = 1:size(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo,2)
        if ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellsPresent
            for CI = 1:size(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell,2)
                if (CellsToPlotGiven && CellsToSegment(TI,ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellLabel(CI))) || ~CellsToPlotGiven
            
                
                %fprintf('timepoint %d; trap %d ; cell %d \n',TP,TI,CI)
                
                %if the cell was previously recorded, put it
                %there.Otherwise, put in an empty place
                CellEntry = find((PreviousTrapNumbers==TI) & (PreviousCellLabels==ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellLabel(CI)));
                if isempty(CellEntry)
                    CellEntry = find(EmptyCellEntries,1);
                    
                    %If there are no available cell entries left initialise a
                    %whole new tranch of cell entries
                    if isempty(CellEntry)
                        CellEntry = length(CellInfo)+1;
                        CellInfo((end+1):(end+CellPreallocationNumber)) = InitialisedCellInfo;
                        EmptyCellEntries = [EmptyCellEntries true(1,CellPreallocationNumber)];
                    end
                    
                    CellInfo(CellEntry).CellNumber = CellEntry;
                    CellInfo(CellEntry).TrapNumber = TI;
                    CellInfo(CellEntry).CellLabel = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellLabel(CI);
                    CellInfo(CellEntry).CellNumber = CellEntry;
                    CellInfo(CellEntry).(PriorRadiiStrings{end}) = double(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).cellRadius)*ones(1,OptPoints);%set prior to be the radus found by matt's hough transform
                    CellInfo(CellEntry).(PriorAnglesStrings{end}) = DefaultAngles;%set prior angles to be evenly spaced
                    EmptyCellEntries(CellEntry) = false;
                
                end
                
                
                

                CellInfo(CellEntry).(CellNumberTimelapseStrings{end}) = CI;
                CellInfo(CellEntry).(CellCentreStrings{end}) =double(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).cellCenter);
                
                if ttacObject.TrapPresentBoolean
                    CellInfo(CellEntry).(TrapCentreStrings{end}) = [ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(TI).xcenter ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(TI).ycenter];
                else
                    CellInfo(CellEntry).(TrapCentreStrings{end}) = [0 0];
                end
                
                CellInfo(CellEntry).TimePointsPresent = CellInfo(CellEntry).TimePointsPresent+1 ;
                CellInfo(CellEntry).UpdatedThisTimepoint = true;
                NumberOfCellsUpdated = NumberOfCellsUpdated+1;
                %checksum = sum([CellInfo(:).UpdatedThisTimepoint],2);
                end
            end
        end
        
    end
    
    %Get Subimages of Cells
    

    CellCentres = reshape([CellInfo([CellInfo(:).UpdatedThisTimepoint]).(CellCentreStrings{end})],2,[]);
    TrapCentres = reshape([CellInfo([CellInfo(:).UpdatedThisTimepoint]).(TrapCentreStrings{end})],2,[]);
    
    %if there are no traps present then cell coordinates in
    %ttacObject.TimelapseTraps are absolute coordinates.
    if ttacObject.TrapPresentBoolean
        TrueCentres = CellCentres +TrapCentres - repmat([ttacObject.TimelapseTraps.cTrapSize.bb_width ; ttacObject.TimelapseTraps.cTrapSize.bb_height],1,NumberOfCellsUpdated);
    else
        TrueCentres = CellCentres;
    end
    
    CellNumbers = find([CellInfo(:).UpdatedThisTimepoint]);
    
    %shouldn't happen, but it has.
    TrueCentres(TrueCentres<1 | TrueCentres>512) = 1;

    
    ImageStack = ACBackGroundFunctions.get_cell_image(Image,SubImageSize,TrueCentres');
    
    %transform images
    
    if ttacObject.TrapPresentBoolean
        TrapImageStack = ACBackGroundFunctions.get_cell_image(TrapImage,SubImageSize,TrueCentres');
        %ImageStack = ACImageTransformations.radial_gradient_DICangle_and_radialaddition(ImageStack,ITparameters,TrapImageStack);
        ImageStack = ImageTransformFunction(ImageStack,ITparameters,TrapImageStack);
    
    else
        ImageStack = ImageTransformFunction(ImageStack,ITparameters);
    end
    
    %redistribute amongst data structure
    
    for CN = 1:NumberOfCellsUpdated
        CellInfo(CellNumbers(CN)).(TransformedImageStrings{end}) = ImageStack(:,:,CN);
    end
    
    %% actually do the segmentation function
    
    for CN = find([CellInfo(:).UpdatedThisTimepoint] & ([CellInfo(:).TimePointsPresent]==slice_size) )
       
        %do first timepoint segmentation - so no previous timepoint
        [TranformedImageStack,PriorRadiiStack] = getStacksFromCellInfo(CellInfo,PriorRadiiStrings,TransformedImageStrings,CN);
        [RadiiResult,AnglesResult] = ACMethods.PSORadialTimeStack(TranformedImageStack,ACparameters,FauxCentersStack,PriorRadiiStack);
        %fprintf('Segmenting Timepoint %d ;  trap %d ;  cell  %d ;\n',TP,TI,CN)
        
        %For debugging
%         RadiiResult = PriorRadiiStack;
%         AnglesResult = repmat(DefaultAngles,slice_size,1);
        
        %write results to keep to the timelapse object
        for RN = 1:keepers
            [px,py] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult(RN,:)',AnglesResult(RN,:)',CellInfo(CN).(CellCentreStrings{RN}),TrapImageSize);
            TempResultImage = false(TrapImageSize);
            TempResultImage(py+TrapImageSize(1,1)*(px-1))=true;
            %write the results to keep (1:keepers) to the cTimelapse object
            ttacObject.TimelapseTraps.cTimepoint(TP+RN-slice_size).trapInfo(CellInfo(CN).TrapNumber).cell(CellInfo(CN).(CellNumberTimelapseStrings{RN})).segmented = sparse(TempResultImage);
            ttacObject.TimelapseTraps.cTimepoint(TP+RN-slice_size).trapInfo(CellInfo(CN).TrapNumber).cell(CellInfo(CN).(CellNumberTimelapseStrings{RN})).cellAngles = AnglesResult(RN,:);  
            ttacObject.TimelapseTraps.cTimepoint(TP+RN-slice_size).trapInfo(CellInfo(CN).TrapNumber).cell(CellInfo(CN).(CellNumberTimelapseStrings{RN})).cellRadii = RadiiResult(RN,:);
            ttacObject.TimelapseTraps.cTimepoint(TP+RN-slice_size).trapInfo(CellInfo(CN).TrapNumber).cell(CellInfo(CN).(CellNumberTimelapseStrings{RN})).ActiveContourParameters = ttacObject.Parameters;            

        end
        
        CellInfo(CN).PreviousTimepointResult = RadiiResult(keepers,:);
        
        %put all radii not to be kept in the CellInfoarray
        for RN = (keepers+1):slice_size
            CellInfo(CN).(PriorRadiiStrings{RN}) = RadiiResult(RN,:);
            CellInfo(CN).(PriorAnglesStrings{RN}) = AnglesResult(RN,:);
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
        
        
        %write results to keep to the timelapse object
        for RN = 1:keepers
            [px,py] = ACBackGroundFunctions.get_full_points_from_radii(RadiiResult(RN,:)',AnglesResult(RN,:)',CellInfo(CN).(CellCentreStrings{RN}),TrapImageSize);
            TempResultImage = false(TrapImageSize);
            TempResultImage(py+TrapImageSize(1,1)*(px-1))=true;
            %write the results to keep (1:keepers) to the cTimelapse object
            ttacObject.TimelapseTraps.cTimepoint(TP+RN-slice_size).trapInfo(CellInfo(CN).TrapNumber).cell(CellInfo(CN).(CellNumberTimelapseStrings{RN})).segmented = sparse(TempResultImage);  
            ttacObject.TimelapseTraps.cTimepoint(TP+RN-slice_size).trapInfo(CellInfo(CN).TrapNumber).cell(CellInfo(CN).(CellNumberTimelapseStrings{RN})).cellAngles = AnglesResult(RN,:);  
            ttacObject.TimelapseTraps.cTimepoint(TP+RN-slice_size).trapInfo(CellInfo(CN).TrapNumber).cell(CellInfo(CN).(CellNumberTimelapseStrings{RN})).cellRadii = RadiiResult(RN,:);
            ttacObject.TimelapseTraps.cTimepoint(TP+RN-slice_size).trapInfo(CellInfo(CN).TrapNumber).cell(CellInfo(CN).(CellNumberTimelapseStrings{RN})).ActiveContourParameters = ttacObject.Parameters;

        end
        
        CellInfo(CN).PreviousTimepointResult = RadiiResult(keepers,:);
        
        %put all radii not to be kept in the CellInfoarray
        for RN = (keepers+1):slice_size
            CellInfo(CN).(PriorRadiiStrings{RN}) = RadiiResult(RN,:);
            CellInfo(CN).(PriorAnglesStrings{RN}) = AnglesResult(RN,:);
        end
           
        
    end
    
    
    
    
end

%end of the timeperiod to be segmented.write remaining priors to the
%segmentation results.


for CN = find([CellInfo(:).UpdatedThisTimepoint])
    
    %take cells which for which no cell was present at the previous
    %timepoint and makes the segmentation result the prior result for
    %all cells.
    for RN = (keepers - (mod(CellInfo(CN).TimePointsPresent-slice_size,keepers))+1):slice_size
        [px,py] = ACBackGroundFunctions.get_full_points_from_radii((CellInfo(CN).(PriorRadiiStrings{RN}))',(CellInfo(CN).(PriorAnglesStrings{RN}))',CellInfo(CN).(CellCentreStrings{RN}),TrapImageSize);
        TempResultImage = false(TrapImageSize);
        TempResultImage(py+TrapImageSize(1,1)*(px-1))=true;
        %write the results to keep (1:keepers) to the cTimelapse object
        ttacObject.TimelapseTraps.cTimepoint((LastTimepoint)+RN-slice_size).trapInfo(CellInfo(CN).TrapNumber).cell(CellInfo(CN).(CellNumberTimelapseStrings{RN})).segmented = sparse(TempResultImage);
        
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
