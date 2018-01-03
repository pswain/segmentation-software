function addCell(cTimelapse,timepoint,trap_index,new_cell_centre)
% addCell(cTimelapse,cCellVision,cCellMorph,timepoint,trap_index,new_cell_centre)
%
% cTimelapse        :   object of the timelapseTraps class (which is
%                       changed to include the new cell). This is expected
%                       to have cCellVision and cCellMorph properties
%                       populated with the appropriate objects to identify
%                       cells:
%       cCellVision       :   object of the cellVision class
%       cCellMorph        :   object of the cellMorphologyModel class
%
% timepoint         :   the timepoint at which a cell should be added
% trap_index        :   index of the trap from which a cell should be added
%                       or removed
% new_cell_centre   :   the centre of the new cell  (i.e. [x,y]
%                       with y positive in the downward direction).
%
% uses the active contour method to add a cell at the specified
% timepoint/trap with a centre at point new_cell_centre.
% mostly cut and pasted from segmentACexperimental.


%% %%%%%%%%%%%%%%%%%%%%%%%%%   EXTRACTING GENERAL PARAMETERS   %%%%%%%%%%%%%%%%%%%%%%%%%

cCellMorph = cTimelapse.cCellMorph;

% for any unspecified parameters use the default values.
ACParams = parse_struct(cTimelapse.ACParams,timelapseTraps.LoadDefaultACParams);

ActiveContourParameters = ACParams.ActiveContour;

% logical: whether to use the decision image to find the edge.
EdgeFromDecisionImage = ACParams.ImageTransformation.EdgeFromDecisionImage;
% size of image used in AC edge identification. Set to just encompass the largest cell possible.
SubImageSize = 2*ACParams.ActiveContour.R_max + 1;

% bwdist value of cell pixels which will not be allowed in the cell area
% (so inner (1-cellPixExcludeThresh) fraction will be ruled out of future
% other cell areas)
CellPixExcludeThresh = ACParams.ActiveContour.CellPixExcludeThresh;

% probability that the trap edge (the part with value of 0.5 or greater) is
% a centre,edge or BG.
pTrapIsCentreEdgeBG = ACParams.ImageTransformation.pTrapIsCentreEdgeBG;

%variable assignments,mostly for convenience and parallelising.
TransformParameters = ACParams.ImageTransformation.TransformParameters;
TrapImageSize = size(cTimelapse.defaultTrapDataTemplate);

% this should only be used by the algorithm if it is not making the edge
% from the decision image.
if ~isempty(ACParams.ImageTransformation.ImageTransformFunction);
    ImageTransformFunction = str2func(['ACImageTransformations.' ACParams.ImageTransformation.ImageTransformFunction]);
end


TrapMaxCell = cTimelapse.returnMaxCellLabel(trap_index);

TrapInfo = cTimelapse.cTimepoint(timepoint).trapInfo(trap_index);

% active contour code throws errors if asked to visualise in the parfor
% loop.
ACparametersPass = ActiveContourParameters;
ACparametersPass.visualise = 0;


%% GENERATE SEGMENTATION IMAGES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[TrapDecisionImage, TrapEdgeImage,TrapTrapImage,TrapACImage,RawDecisionIms]...
    = cTimelapse.generateSegmentationImages(timepoint,trap_index,ACParams);

have_raw_dims = ~isempty(RawDecisionIms);
% calculate log P 's for each pixel type
% correcting trap pixels if the correction value is non nan
if have_raw_dims
    RawBgDIM = RawDecisionIms{1};
    RawCentreDIM = RawDecisionIms{2};
    
    PCentreTrap =  -log(1 + exp(RawBgDIM)) -log(1 + exp(RawCentreDIM)) ;
    if ~any(isnan(pTrapIsCentreEdgeBG))
        PCentreTrap(TrapTrapImage>=0.5) = log(pTrapIsCentreEdgeBG(1));
    end
    PCentreTrap(TrapTrapImage==1) = min(PCentreTrap(:));
    
    
    PEdgeTrap   =  RawCentreDIM -log(1 + exp(RawBgDIM)) -log(1 + exp(RawCentreDIM));
    if ~any(isnan(pTrapIsCentreEdgeBG))
        PEdgeTrap(TrapTrapImage>=0.5) = log(pTrapIsCentreEdgeBG(2));
    end
    PEdgeTrap(TrapTrapImage==1) = min(PEdgeTrap(:));
    
    
    PBGTrap     = RawBgDIM - log(1 + exp(RawBgDIM));
    if ~any(isnan(pTrapIsCentreEdgeBG))
        PBGTrap(TrapTrapImage>=0.5) = log(pTrapIsCentreEdgeBG(3));
    end
    PBGTrap(TrapTrapImage==1) = max(PBGTrap(:));
    
    
    PTot = exp(PCentreTrap) + exp(PEdgeTrap) + exp(PBGTrap);
    
    % normalise
    PCentreTrap = log(exp(PCentreTrap)./PTot);
    PEdgeTrap = log(exp(PEdgeTrap)./PTot);
    PBGTrap = log(exp(PBGTrap)./PTot);
else
    % to stop parfor loop bugging out.
    PCentreTrap = zeros(size(TrapDecisionImage));
    PEdgeTrap = PCentreTrap;
    PBGTrap = PCentreTrap;
end

% This is a slightly confusing chunk of code that identified an inner
% region of every extant cell by doing bwdistm normalising, and taking this
% as a sort of probability of a pixel being part of another cell. 
% It could most likely be replaced by a simple erosion on the segmented
% cell outline, but I have left it this way since this is how it was done
% for the paper and how it is done in the
% timelapseTraps.segmentACexperimental
AllCellPixels = zeros(TrapImageSize);
AllCellPixelsBinary = false(TrapImageSize);
if TrapInfo.cellsPresent
    for ci = 1:length(TrapInfo.cell)
        SegmentationBinary = imfill(full(TrapInfo.cell(ci).segmented),'holes');
        EdgeConfidenceImage = bwdist(~SegmentationBinary);
        EdgeConfidenceImage = EdgeConfidenceImage./max(EdgeConfidenceImage(:));
        AllCellPixels = AllCellPixels + EdgeConfidenceImage;
    end
end

% experimental modification
% make the interior regions of already identified cells background.
if have_raw_dims
    AllCellPixelsBinary = AllCellPixels>0;
    PNotEdge = exp(PCentreTrap(AllCellPixelsBinary))+exp(PBGTrap(AllCellPixelsBinary));
    PCentreTrap(AllCellPixelsBinary) = ...
        min(log(0.1*PNotEdge),PCentreTrap(AllCellPixelsBinary));
    PBGTrap(AllCellPixelsBinary) = ...
        max(log(0.9*PNotEdge),PBGTrap(AllCellPixelsBinary));
end

NotCellsCellImage = ACBackGroundFunctions.get_cell_image(AllCellPixels,...
    SubImageSize,...
    new_cell_centre,...
    false);

CellTrapImage = ACBackGroundFunctions.get_cell_image(TrapTrapImage,...
    SubImageSize, ...
    new_cell_centre );

if have_raw_dims && EdgeFromDecisionImage
    % use the decision image result to get the edge
    PCentreCell = ACBackGroundFunctions.get_cell_image(PCentreTrap,SubImageSize,new_cell_centre );
    PEdgeCell = ACBackGroundFunctions.get_cell_image(PEdgeTrap,SubImageSize,new_cell_centre );
    PBGCell = ACBackGroundFunctions.get_cell_image(PBGTrap,SubImageSize,new_cell_centre );
    
    
    TransformedCellImage = -PEdgeCell + log(1-exp(PEdgeCell));
    CellRegionImage = log(1-exp(PCentreCell))-PCentreCell;
else
    % use some function to pick out edge
    CellImage = ACBackGroundFunctions.get_cell_image(TrapACImage,...
        SubImageSize,...
        new_cell_centre );
    
    TransformedCellImage = ImageTransformFunction(CellImage,TransformParameters,CellTrapImage);
    
    % subtraction of the median has been left in for
    % legacy. Shouldn't effect procedure anymore.
    TransformedCellImage = TransformedCellImage - median(TransformedCellImage(:));
    CellRegionImage = zeros(size(TransformedCellImage));
end
% this region is (roughly) forcibly excluded, so that
% it cannot be included in the cell.
ExcludeLogical = (CellTrapImage>=1)| (NotCellsCellImage>=CellPixExcludeThresh);

if ~any(ExcludeLogical(:))
    ExcludeLogical = [];
end

%%%%%%%%%%% do active contour edge identification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[RadiiResult,AnglesResult,~] = ...
    ACMethods.PSORadialTimeStack(TransformedCellImage,ACparametersPass,[],ExcludeLogical,CellRegionImage,cCellMorph);

%%%%%%%%%%% write new cell info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NCI = new cell index
if TrapInfo.cellsPresent
    NCI = length(TrapInfo.cell) +1;
    % can cause problems with older timelapses and not really necessary.
    %TrapInfo.cell(NCI) = cTimelapse.cellInfoTemplate;

else
    NCI = 1;
    % assigning this way causes less errors if the cTimelapse is an old one
    % and the fields of the cell structure are a bit wrong.
    TrapInfo.cell = cTimelapse.cellInfoTemplate;

end



TrapInfo.cellLabel(NCI) = TrapMaxCell+1;

TrapInfo.cell(NCI).cellCenter = double(new_cell_centre);
TrapInfo.cellsPresent = true;

%write active contour result and change cross
%correlation matrix and decision image.

TrapInfo.cell(NCI).cellRadii = RadiiResult;
TrapInfo.cell(NCI).cellAngle = AnglesResult;
TrapInfo.cell(NCI).cellRadius = mean(RadiiResult);

SegmentationBinary = ACBackGroundFunctions.get_outline_from_radii(RadiiResult',AnglesResult',double(TrapInfo.cell(NCI).cellCenter),TrapImageSize);
TrapInfo.cell(NCI).segmented = sparse(SegmentationBinary);

cTimelapse.cTimepoint(timepoint).trapInfo(trap_index) = TrapInfo;

end




