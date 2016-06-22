classdef timelapseTrapsActiveContour<handle
    %TIMELASPETRAPSACTIVECONTOUR Summary of this class goes here
    %   Detailed explanation goes here
    
    
    %This should be a class to hold active contour relevant data and
    %perform active contour segmentation of matt's trap data. Suggestions
    %of things to store are:
    
    %parameter for segmentation method
    %parameters structure
    %trap parameter structure
    %trap image
    %trap pixel image
    %trap locations as a sparse matrix

    %also a generic method for finding traps
    
    properties
        
        Parameters %structure of parameters for trap detection and segmentation
        TrapPresentBoolean = false;%boolean value to indicate if there are traps in the image
        TrapImage =[]; %DIC image of an empty trap
        TrapPixelImage=[]; %grayscale image of trappiness. Consider 1 or larger to be definitely traps.
        TrapGridImage = [];%image of field of view with no traps
        TrapLocation = []; %location of traps in timecourse
        TimelapseTraps = []; %Object of the TimelapseTraps class
        ImageSize = [512 512]; %Size of the images in the Timelapse (just as though you had done 'size')
        TrapImageSize = []; %Size of the trap images (just as though you had done 'size')
        LengthOfTimelapse = []; %number
        ChannelsToFlip = []; %sometimes channels need flipping. These ones get flipped leftright
        cCellVision = []; %if data was taken from a cellvision class, that cellvision class is stored here.
        
    end
    
    properties(Constant)
        ACmethods = {'AC method with cross correlation','AC method on found and tracked centres','Register Image with First Timepoint Image','AC method specifically for GFP stacks','nothing'}
    end
    
    methods
        
        function ttacObject= timelapseTrapsActiveContour(Parameters)
            %constructor. Doesn't do anything really except take the
            %parameters or load the default set.
            
            if nargin<1 ||isempty(Parameters)
                ttacObject.Parameters =  ttacObject.LoadDefaultParameters;
            else
                ttacObject.Parameters = Parameters;                
            end
            
           
           ttacObject.TrapImage = [];
           ttacObject.TrapPixelImage = [];
           ttacObject.TrapLocation = [];
           
        end
        
        %list of methods referring to cTimelapse
        %  passTimelapseTraps
        %  makeTrapPixelImage
        %  getTrapInfoFromCellVision
        %  findTrapLocation
        %  ExtractCentres
        
        
        %% all the below
        
        % the following are basically wrappers for timelapse functions
        % this was done to make the code easier to integrate with Ivan's
        % and to make all interactions with the outside world well
        % defined.
        
        
        function CellIndicesToSegment = CellsToCheck(ttacObject,Timepoint,TrapIndex)
            % CellIndicesToSegment = CellsToCheck(ttacObject,Timepoint,TrapIndex)
            
            % returns the cells at trap 'TrapIndex' of timepoint
            % 'Timepoint' to segment.
            
            if ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapInfo(TrapIndex).cellsPresent
                
                if ~ttacObject.Parameters.ImageSegmentation.CellsToPlotGiven
                   %Cells to Plot not given so just return all the cells at
                   %that timepoint
                   % CellIndicesToSegment = 1:size(ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapInfo(TrapIndex).cell,2);
                   %should return the same result but sometimes craps out
                   %because cell structure has a single entry when things
                   %as a space filler sometimes
                   CellIndicesToSegment = find(ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapInfo(TrapIndex).cellLabel ~=0);
                else
                    CellsToSegment = full(ttacObject.TimelapseTraps.cellsToPlot);
                    LabelsOfCellsToSegment = find(CellsToSegment(TrapIndex,:));
                    CellIndicesToSegment = find(ismember(ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapInfo(TrapIndex).cellLabel,LabelsOfCellsToSegment));
                end
                
            else
                CellIndicesToSegment = [];
            end
            
            
        end
        
        
        function CellLabel = ReturnLabel(ttacObject,Timepoint,TrapIndex,CellIndex)
            % CellLabel = ReturnLabel(ttacObject,Timepoint,TrapIndex,CellIndex)
            
            %can handle CellIndex as an array
            
            if nargin<4
                CellLabel = ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapInfo(TrapIndex).cellLabel;
            else
                CellLabel = [ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapInfo(TrapIndex).cellLabel(CellIndex)];
            end
        end
        
        
        function CellCentre = ReturnCellCentreAbsolute(ttacObject,Timepoint,TrapIndex,CellIndex)
            % CellCentre = ReturnCellCentreAbsolute(ttacObject,Timepoint,TrapIndex,CellIndex)
            %
            %returns the ABSOLUTE position (as double) of the cells in the image.
            %can handle an CellIndex as an array, in which case returns
            %column of form [x's   y's].
            
            if nargin<4 || isempty(CellIndex)
                CellIndex = 1:length(ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapInfo(TrapIndex).cell);
            end
            
            CellCentre =  reshape(double([ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapInfo(TrapIndex).cell(CellIndex).cellCenter]),2,[])';
            
            
            if ttacObject.TrapPresentBoolean && ~isempty(CellCentre)
                
                CellCentre = CellCentre + ...
                    repmat(ttacObject.ReturnTrapCentre(Timepoint,TrapIndex) - [ttacObject.TimelapseTraps.cTrapSize.bb_width ttacObject.TimelapseTraps.cTrapSize.bb_height],length(CellIndex),1) - 1;
                % the -1 on this might seem strange but think about it. if the
                % cell center relative is [1 1] it should be at the first square
                % [1 1] square of the trap image so then you should add [0 0] to
                % the first entry of the trap image which is
                %    trap_centre - bb_width
                % so then for [1 1] the answer [1 1] + trap_centre - bb_width - [1 1]
        
           end
           
           %shouldn't ever happen
           CellCentre(CellCentre<1) = 1;
           CellCentre(CellCentre(:,1)>ttacObject.ImageSize(1,2),1) = ttacObject.ImageSize(1,2);
           CellCentre(CellCentre(:,2)>ttacObject.ImageSize(1,1),2) = ttacObject.ImageSize(1,1);
           
           CellCentre = double(CellCentre);
           
           
           
        end
        
        function CellCentre = ReturnCellCentreRelative(ttacObject,Timepoint,TrapIndex,CellIndex)
            % CellCentre = ReturnCellCentre(ttacObject,Timepoint,TrapIndex,CellIndex)
            
            %returns the RELATIVE(relative to the trap centre) position of
            %the cells in the image. can handle an CellIndex as an array,
            %in which case returns column of form [x's   y's].
            
           CellCentre =  reshape([ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapInfo(TrapIndex).cell(CellIndex).cellCenter],2,[])';
           
           %shouldn't ever happen
           CellCentre(CellCentre<1) = 1;
           CellCentre(CellCentre(:,1)>ttacObject.TrapImageSize(2),1) = ttacObject.TrapImageSize(2);
           CellCentre(CellCentre(:,2)>ttacObject.TrapImageSize(1),2) = ttacObject.TrapImageSize(1);
           
           CellCentre = double(CellCentre);
           
           
        end
        
        
        function TrapCentre = ReturnTrapCentre(ttacObject,Timepoint,Trapindex)
            % TrapCentre = ReturnCellCentre(ttacObject,Timepoint,TrapIndex)
            
            %can handle an TrapIndex as an array, in which case returns
            %column of form [x's   y's].
            %If the image does not contain traps it returns [0 0] for every
            %trap requested.
            
            if ttacObject.TrapPresentBoolean
                TrapCentre = [[ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapLocations(Trapindex).xcenter]' [ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapLocations(Trapindex).ycenter]'];
                
            else
                TrapCentre = repmat([0 0],length(Trapindex),1);
            end
        end
         
        
        function CellRadii = ReturnCellRadii(ttacObject,TP,TI,CI)
            % ReturnCellRadii = ReturnRadii(ttacObject,TP,TI,CI)
            
            if TP>1 && isfield(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI),'cellRadii') && ...
                    length(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).cellRadii)==ttacObject.Parameters.ImageSegmentation.OptPoints
                
                CellRadii = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).cellRadii;
            else
                CellRadii = double(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).cellRadius)*ones(1,ttacObject.Parameters.ImageSegmentation.OptPoints);
                %set prior to be the radius found by matt's hough transform
            end
            
        end
        
        
        function CellAngles = ReturnCellAngles(ttacObject,TP,TI,CI)
            % CellAngles = ReturnCellAngles(ttacObject,TP,TI,CI)
            
            if isfield(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI),'cellAngle') && ...
                    length(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).cellAngle)==ttacObject.Parameters.ImageSegmentation.OptPoints
                
                CellAngles = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).cellAngle;
                
                        
            else
                CellAngles = linspace(0,2*pi,(ttacObject.Parameters.ImageSegmentation.OptPoints+1));
                CellAngles = CellAngles(1:(end-1));
                %angles vector given as a default when no other is provided
                
            end
            
            
            
        end
        
        function Image = ReturnImage(ttacObject,Timepoint,Channel,normalise)
            % Image = ReturnImage(ttacObject,Timepoint,Channel,normalise)
            
            % reuturns a the image from a single timepoint (Timepoint) in
            % channel (Channel).
            
            if nargin<2
                Timepoint = 1;
            end
            
            if nargin<3
                Channel = 1;
            end
            
            if nargin<4 || isempty(normalise)
                normalise = 'none';
            end
            
            Image = ttacObject.TimelapseTraps.returnSingleTimepoint(Timepoint,Channel);
            
            %%%REALLY TEMPORARY JUST TO FIX DOA1%%%%%%%%%%%
            
            if ismember(Channel,ttacObject.ChannelsToFlip)
                Image = fliplr(Image);
            end
            
            switch normalise
                case 'median'
                    Image = double(Image);
                    Image = Image./(median(Image(:)));
                case 'none'
                    Image = double(Image);
                case 'raw'
                case 'medsubiqr'
                    Image = double(Image);
                    Image = Image - (median(Image(:)));
                    image_iqr = iqr(Image(:));
                    if image_iqr ~=0
                        Image = Image/image_iqr;
                    end
            end
            
        end
        
        
        function TrapIndicesToSegment = TrapsToCheck(ttacObject,Timepoint)
            % TrapIndicesToSegment = TrapsToCheck(ttacObject,Timepoint)
            
            % currently just returns the numbers of all the traps at the
            % timepoint TrapIndicesToSegment
            
            %TrapIndicesToSegment = 1:size(ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapLocations,2);
            TrapIndicesToSegment = 1:size(ttacObject.TimelapseTraps.cTimepoint(Timepoint).trapInfo,2);
            
%             TrapIndicesToSegment = [3];
%             fprintf('USING REDUCED TRAP SET,CHANGE BACK AT 249 IN TIMELAPSETRAPSACTIVECONTOUR \n \n');
%             
        end
            
        
        function WriteACResults(ttacObject,TP,TI,CI,Radii,Angles,SegmentationBinaryStack)
            % WriteACResults(ttacObject,TP,TI,CI,Radii,Angles,SegmentationBinaryStack(optional))
            
            % all can be column vectors or matriced
            
            %writes the result Radii,Angles,Segmentation Binary to the cell
            %defined by TP,TI,CI. If no Segmentation image is given it will
            %be created using the get_full_points_radii and the
            %TrapImageSize field.
            
            %debuggery
            
            
            
            TimePointsToWrite = (unique(TP))';
            
            for TPW = TimePointsToWrite;
                
                TemporaryCTimepoint = ttacObject.TimelapseTraps.cTimepoint(TPW);
                
                for TPi = (find(TP==TPW))'
                    
                    CellArraySize = size(TemporaryCTimepoint.trapInfo(TI(TPi)).cell);
                    CellLabelSize = size(TemporaryCTimepoint.trapInfo(TI(TPi)).cellLabel);
                    
                    if any(CellArraySize~=CellLabelSize)
                        
                        fprintf('Matts code is wierd\n %d %d \n',TPW,TI(TPi))
                    end
                    
                    TemporaryCTimepoint.trapInfo(TI(TPi)).cell(CI(TPi)).cellRadii = Radii(TPi,:);
                    TemporaryCTimepoint.trapInfo(TI(TPi)).cell(CI(TPi)).cellAngle = Angles(TPi,:);
                    
                    %TemporaryCTimepoint.trapInfo(TI).cell(CI).ActiveContourParameters = ttacObject.Parameters;
                    
                    
                    if nargin<7
                        
                        
                        [px,py] = ACBackGroundFunctions.get_full_points_from_radii((Radii(TPi,:))',(Angles(TPi,:))',double(ttacObject.ReturnCellCentreRelative(TPW,TI(TPi),CI(TPi))),ttacObject.TrapImageSize);
                        
                        SegmentationBinary = false(ttacObject.TrapImageSize);
                        SegmentationBinary(py+ttacObject.TrapImageSize(1,1)*(px-1))=true;
                    else
                        SegmentationBinary = SegmentationBinaryStack(:,:,TPi);
                        
                    end
                    
                    TemporaryCTimepoint.trapInfo(TI(TPi)).cell(CI(TPi)).segmented = sparse(SegmentationBinary);
                    %TemporaryCTimepoint.trapInfo(TI(TPi)).cell(CI(TPi)).segmentedAC = sparse(SegmentationBinary);
                    seg_areas=full(SegmentationBinary);
                    segLabel=imfill(seg_areas,'holes');
                        cellLoc=segLabel>0;
                    %TemporaryCTimepoint.trapInfo(TI(TPi)).cell(CI(TPi)).radiusAC=sqrt(sum(cellLoc(:))/pi);
                    %debuggery
                    CellArraySizeAfter = size(TemporaryCTimepoint.trapInfo(TI(TPi)).cell);
                    CellLabelSizeAfter = size(TemporaryCTimepoint.trapInfo(TI(TPi)).cellLabel);
                    if any([CellArraySize~=CellArraySizeAfter CellLabelSizeAfter~=CellLabelSize] )
                        
                        fprintf('your code is broken\n %d %d %d \n',TP(TPi),TI(TPi),CI(TPi))
                    end
                    
                end
                
                ttacObject.TimelapseTraps.cTimepoint(TPW) = TemporaryCTimepoint;
            end
        end
        
        function TrapImage = ReturnImageOfSingleTrap(ttacObject,Timepoint,TrapIndex,channel)
            %TrapImage = ReturnImageOfSingleTrap(ttacObject,Timepoint,TrapIndex,channel(optional))
            
            if nargin<4
                channel = 1;
            end
            
            if ttacObject.TrapPresentBoolean
                TrapImage = returnTrapsTimepoint(ttacObject.TimelapseTraps,TrapIndex,Timepoint,channel);
            end
            
        end
        
        
        %% Do not refer to cTimelapse
        
        
        function TrapImage = ReturnTrapImage(ttacObject,timepoint)
            % TrapImage = ReturnTrapImage(ttacObject,Timepoint)
            
            % returns the trap image (boolean with trap pixels) for a particular timepoint
            
            
            %%%%%%%%%%WARNING%%%%%%%%%%%%%%%%%
            % If you are editing this the ReturnTrapPixelForSingleCell
            % method does not use this method - so may need to edit both.
            
            if ttacObject.TrapPresentBoolean
                
                if isfield(ttacObject.TimelapseTraps.cTimepoint(timepoint).trapInfo(1),'refinedTrapPixelsInner') &&...
                        ~isempty(ttacObject.TimelapseTraps.cTimepoint(timepoint).trapInfo(1).refinedTrapPixelsInner) &&...
                        isfield(ttacObject.TimelapseTraps.cTimepoint(timepoint).trapInfo(1),'refinedTrapPixelsBig') &&...
                        ~isempty(ttacObject.TimelapseTraps.cTimepoint(timepoint).trapInfo(1).refinedTrapPixelsBig)
                    
                    num_traps = length(ttacObject.TimelapseTraps.cTimepoint(timepoint).trapInfo);
                    trapOutline = zeros([ttacObject.TrapImageSize num_traps]);
                    trap_centres = zeros(num_traps,2);
                    for k=1:num_traps
                        trapOutline(:,:,k) = 0.5*full(ttacObject.TimelapseTraps.cTimepoint(timepoint).trapInfo(k).refinedTrapPixelsBig) +...
                            0.5*full(ttacObject.TimelapseTraps.cTimepoint(timepoint).trapInfo(k).refinedTrapPixelsInner);
                        trap_centres(k,:) = [ttacObject.TimelapseTraps.cTimepoint(timepoint).trapLocations(k).xcenter ...
                                                    ttacObject.TimelapseTraps.cTimepoint(timepoint).trapLocations(k).ycenter];

                    end
                    
                    TrapImage = ACBackGroundFunctions.put_cell_image(zeros(ttacObject.ImageSize), trapOutline, trap_centres);

                else
                    TrapImage = conv2(1*full(ttacObject.TrapLocation{timepoint}),ttacObject.TrapPixelImage,'same');
                end
            else
                TrapImage = zeros(size(ttacObject.ReturnImage(timepoint)));
            end
            
        end
        
        function CheckTimepointsValid(ttacObject,Timepoints)
            % CheckTimepointsValid(ttacObject,Timepoints)
            
            % check the timepoints given fall in the appropriate range for
            % the timelapse.
            
            if ~any(ismember(Timepoints,ttacObject.TimepointsToCheck))
                error('timpoints passed to SegmentConsecutiveTimePoints are not valid timepoints\n')
            end
        end
        
        function Timepoints = TimepointsToCheck(ttacObject)
            
            Timepoints = ttacObject.TimelapseTraps.timepointsToProcess;
            
        end
        
        
        function CellImage = ReturnSubImages(ttacObject,Timepoints,CentreStack,SubImageSize,channel,normalise)
            %TrapImage = ReturnImageOfSingleCell(ttacObject,Timepoint,TrapIndices,CellIndices,channel(optional))
            
            % ttacObject    -  object of the timelapseTrapsActiveContour class

            % Timepoints    -  1 x n vector of the timepoint of each cell to be transformed 
            
            % CentreStack   -  stack of [x1 y1 ; x2 y2 ; x3 y3 ;...] (image wise) location of
            %                  centres of subimages desired 
            
            %SubImageSize   -  size of image to get. Should be odd.

            % channel       -  index of the channel to use or string 'trap'
            %                  for trap pixel images.
            
            % normalise     -  whether to normalise the images (currently
            %                  only median is used), so if this input is
            %                  the string 'median' the images are divided
            %                  by the median of each timepoint

            
            if nargin<5 || isempty(channel)
                channel = 1;
            end
            
            if nargin<6 || isempty(normalise)
                normalise = 'none';
            end
                
            
            
            
            UniqueTimepoints = unique(Timepoints);
            
            CellImage = zeros(SubImageSize,SubImageSize,length(Timepoints));
            
            for TP =UniqueTimepoints
                
                if ischar(channel) && strcmp(channel,'trap')
                    Image = ttacObject.ReturnTrapImage(TP);
                else
                    Image = ttacObject.ReturnImage(TP,channel,normalise);
                end
                
                RelevantEntries = Timepoints==TP;
                
                CurrentTPCellCentres = CentreStack(RelevantEntries,:);
                
                CellImage(:,:,RelevantEntries) = ACBackGroundFunctions.get_cell_image(Image,SubImageSize,CurrentTPCellCentres);
                
                
            end
            
            
                   

        end
        
        
        function CellImage = ReturnImageOfSingleCell(ttacObject,Timepoints,TrapIndices,CellIndices,channel,normalise)
            %TrapImage = ReturnImageOfSingleCell(ttacObject,Timepoint,TrapIndices,CellIndices,channel(optional))
             
            % ttacObject    -  object of the timelapseTrapsActiveContour class
 
            % Timepoints    -  1 x n vector of the timepoint of each cell to be transformed 
 
            % TrapIndices   -  1 x n vector of the trapindex of each cell to be transformed
 
            % CellIndices   -  1 x n vector of the cellindex of each cell to be transformed
             
            % channel       -  index of the channel to use
             
            % normalise     -  whether to normalise the images (currently
            %                  only median is used), so if this input is
            %                  the string 'median' the images are divided
            %                  by the median of each timepoint
 
             
            if nargin<5
                channel = 1;
            end
             
            if nargin<6 || isempty(normalise)
                normalise = 'none';
            end
                 
             
             
             
            UniqueTimepoints = unique(Timepoints);
             
            CellImage = zeros(ttacObject.Parameters.ImageSegmentation.SubImageSize,ttacObject.Parameters.ImageSegmentation.SubImageSize,length(Timepoints));
             
            for TP =UniqueTimepoints
                
                
                for chi = 1:length(channel)
                    temp_Image = ttacObject.ReturnImage(TP,abs(channel(chi)),normalise);
                    if chi == 1
                        Image = (sign(channel(1))*temp_Image);
                
                    else
                    Image = Image + (sign(channel(chi))*temp_Image);
                    end
                end
                
                
                 
                CurrentTPCellCentres = zeros(sum(Timepoints==TP,2),2);
                 
                RelevantEntries = find(Timepoints==TP);
                 
                for TIindex = 1:length(RelevantEntries)
                     
                    CurrentTPCellCentres(TIindex,:) = ttacObject.ReturnCellCentreAbsolute(TP,TrapIndices(RelevantEntries(TIindex)),CellIndices(RelevantEntries( TIindex)));
                     
                end
                 
                CellImage(:,:,RelevantEntries) = ACBackGroundFunctions.get_cell_image(Image,ttacObject.Parameters.ImageSegmentation.SubImageSize,CurrentTPCellCentres);
                 
                 
            end
             
             
                    
 
        end
        
        function CellTrapImage = ReturnTrapPixelsForSingleCell(ttacObject,Timepoints,TrapIndices,CellIndices)
            %CellTrapImage = ReturnTrapPixelsForSingleCell(ttacObject,Timepoints,TrapIndices,CellIndices)
            
            %INPUTS
            
            % ttacObject    -  object of the timelapseTrapsActiveContour class

            % Timepoints    -  1 x n vector of the timepoint of each cell to be transformed 

            % TrapIndices   -  1 x n vector of the trapindex of each cell to be transformed

            % CellIndices   -  1 x n vector of the cellindex of each cell to be transformed

           

            
            UniqueTimepoints = unique(Timepoints);
            
            CellTrapImage = zeros(ttacObject.Parameters.ImageSegmentation.SubImageSize,ttacObject.Parameters.ImageSegmentation.SubImageSize,length(Timepoints));
            
            if ttacObject.TrapPresentBoolean
            
            for TP =UniqueTimepoints
                
                Image = full(ttacObject.TrapLocation{TP});

                CurrentTPCellCentres = zeros(sum(Timepoints==TP,2),2);
                
                RelevantEntries = find(Timepoints==TP);
                
                for TIindex = 1:length(RelevantEntries)
                    
                    CurrentTPCellCentres(TIindex,:) = ttacObject.ReturnCellCentreAbsolute(TP,TrapIndices(RelevantEntries(TIindex)),CellIndices(RelevantEntries( TIindex)));
                    
                end
                
                CellTrapImage(:,:,RelevantEntries) = convn(1*ACBackGroundFunctions.get_cell_image(Image,ttacObject.Parameters.ImageSegmentation.SubImageSize,CurrentTPCellCentres),ttacObject.TrapPixelImage,'same');
                
                
            end
            end
            
            

        end
        
        function [CellTransformedImage, CellImages] = ReturnTransformedImagesForSingleCell(ttacObject,Timepoints,TrapIndices,CellIndices)
            %[CellTransformedImage CellImages] = ReturnTransformedImagesForSingleCell(ttacObject,Timepoints,TrapIndices,CellIndices)
            
            if ~isempty(CellIndices)
                ttacTransformFunction = str2func(['ttacImageTansformationMethods.' ttacObject.Parameters.ImageSegmentation.ImageTransformMethod]);
                [CellTransformedImage, CellImages] = ttacTransformFunction(ttacObject,Timepoints,TrapIndices,CellIndices);
            else
                CellTransformedImage = [];
                CellImages = [];
            end
        end
        
        
        function CellOutlines = ReturnCellOutlinesForSingleCell(ttacObject,Timepoints,TrapIndices,CellIndices)
            %return the logical of the pixels making up the cell outline.
            
            
            CellOutlines = false(ttacObject.Parameters.ImageSegmentation.SubImageSize,ttacObject.Parameters.ImageSegmentation.SubImageSize,length(Timepoints));
            
            
            for index = 1:length(Timepoints);
                TP = Timepoints(index);
                
                TI = TrapIndices(index);
                
                CI = CellIndices(index);
                
                if CI<= length(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell) && ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellsPresent && TI<=length(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo)
                    
                    CellOutlines(:,:,index)  =  ACBackGroundFunctions.get_cell_image(full(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).segmented),ttacObject.Parameters.ImageSegmentation.SubImageSize,ttacObject.ReturnCellCentreRelative(TP,TI,CI));
                    
                end
                
                
            end
            
            
        end
        
        
        function CellIndices = ReturnCellIndex(ttacObject,Timepoints,TrapIndices,CellLabels)
            % CellIndices = ReturnCellIndex(ttacObject,Timepoint,Trapindex,CellLabel)
            %
            %returns the index of a cell from it's label,timepoint and
            %trapindex. Returns zero if no cell with those identifiers is
            %present at that timepoint.
            %
            %Timepoints,Trapindices,CellLabels are all 1 x n vectors.
            
            CellIndices = zeros(size(Timepoints));
            
            UniqueTimepoints = unique(Timepoints);
            
            for TP = UniqueTimepoints
                
                UniqueTrapIndices = unique(TrapIndices(Timepoints==TP));
                
                for TI = UniqueTrapIndices
                    
                    CellsOfInterest = find(Timepoints==TP & TrapIndices == TI);
                    
                    LabelsFromTrap = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellLabel;
                    
                    for CL = CellsOfInterest
                        
                        if ismember(CellLabels(CL),LabelsFromTrap)
                        
                            CellIndices(CL) = find(LabelsFromTrap==CellLabels(CL));
                        end
                    
                        
                    end
                    
                end
                 
            end
            
            
        end
        
        
        function AvailableChannels = ReturnAvailableChannels(ttacObject)
            %just returns a row vector of available channels
            
            
            AvailableChannels = 1:length(ttacObject.TimelapseTraps.channelNames);
            
            
        end
        
        function [ACmethod, answer_value] = SelectACMethod(ttacObject,ACmethod)
            %[ACmethod, answer_value] = SelectACMethod(ttacObject,method) method to check submitted ACmethod (either
            %number or string) and run dialog if it is not preset or inappropriate. returns string
            %for use by wrapper function below.
            %answer_value is 1 if selected ok and 0 if selected cance;.
            
            
            if nargin<2 || isempty(ACmethod)
                run_select_dialog = true;
                ACmethod = [];
            else
                if ischar(ACmethod)
                    ACindex = strcmp(ACmethod,ttacObject.ACmethods);
                    if any(ACindex)
                        ACmethod = ttacObject.ACmethods{ACindex};
                        run_select_dialog = false;
                    else
                        run_select_dialog = true;
                        ACmethod = [];
                    end
                else 
                    ACmethod = ttacObject.ACmethods(ACmethod);
                    ACmethod = ACmethod{1};
                    run_select_dialog = false;
                end
            end
            
            
            
            if run_select_dialog
            widths = cellfun(@length,ttacObject.ACmethods);
        
            [ACmethod,answer_value] = listdlg('PromptString','select an active contour method',...
                                          'SelectionMode','single',...
                                          'ListSize',[max(widths,[],2) + 10, 1.5*size(ttacObject.ACmethods,1)+2]*8 + [10 40],...
                                          'ListString',ttacObject.ACmethods);
                                      %[ACmethod,answer_value] = ttacObject.ACmethods{ACmethod};
            else
                answer_value = true;
            end
        end
        
        function  RunActiveContourMethod(ttacObject,FirstTimepoint,LastTimepoint,LeaveFirstTimepointUnchanged,ACmethod,CellsToUse)
            if nargin<5 || isempty(ACmethod)
                ACmethod = [];
            end
            
            [ACmethod,answer_value] = SelectACMethod(ttacObject,ACmethod);
            
            if answer_value == false
                fprintf('\n\n    active contour method cancelled   \n\n')
                return
            end
            
            if strcmp(ACmethod,ttacObject.ACmethods{1}) %active contour and cross correlation
                ttacObject.SegmentConsecutiveTimepointsCrossCorrelationParallel(FirstTimepoint,LastTimepoint,LeaveFirstTimepointUnchanged,CellsToUse);

            end
            
            if strcmp(ACmethod,ttacObject.ACmethods{2}) %active contour on identified and tracked cells
                ttacObject.SegmentConsecutiveTimePoints(FirstTimepoint,LastTimepoint,LeaveFirstTimepointUnchanged,CellsToUse);
            end
            
            if strcmp(ACmethod,ttacObject.ACmethods{3}) %jusy cross correlating whole image with first image and shifting accordingly (for cycloheximide datasets)
                ttacObject.SegmentConsecutiveTimepointsNoChanges(FirstTimepoint,LastTimepoint);
            end
            
            if strcmp(ACmethod,ttacObject.ACmethods{4}) % method designed specifically for bright GFP images. Has some caveats and requirements
                ttacObject.SegmentConsecutiveTimepointsCrossCorrelationParallelGFPstack(FirstTimepoint,LastTimepoint,LeaveFirstTimepointUnchanged,CellsToUse);
            end
            
            if strcmp(ACmethod,ttacObject.ACmethods{5}) %nothing - useful somtimes for instantiating timelapse and tracking traps before editing by hand
            end
            
        end
        
        function ttacObjectOUT = copy(ttacObjectIN)
            %ttacObjectOUT = copy(ttacObjectIN)
            % make a new ttacObject object with all the same field values.
            ttacObjectOUT = timelapseTrapsActiveContour(ttacObjectIN.Parameters);
            
            FieldNames = fields(ttacObjectIN);
            
            for i = 1:numel(FieldNames)
                m = findprop(ttacObjectIN,FieldNames{i});
                if ~ismember(m.SetAccess,{'immutable','none'})
                    ttacObjectOUT.(FieldNames{i}) = ttacObjectIN.(FieldNames{i});
                end
            end
            
        end
        
        
        
        
    end %methods
    
    methods(Static)
        
        function DefaultParameters = LoadDefaultParameters
            %LoadDefaultParameters(ttacObject) set ttacObject parameters
            %to be the default parameters saved in the mat file 
            DefaultParameterMatFileLocation = mfilename('fullpath');
            FileSepLocation = regexp(DefaultParameterMatFileLocation,filesep);
            DefaultParameterMatFileLocation = fullfile(DefaultParameterMatFileLocation(1:FileSepLocation(end)),'default_active_contour_parameters.mat');
            load(DefaultParameterMatFileLocation,'Parameters');
            DefaultParameters = Parameters;
        end

        
    end %staticmethods
    
end %classdef

