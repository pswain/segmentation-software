function extractCellDataStandard(cTimelapse)
% extractCellDataStandard(cTimelapse)
%
% standard extraction function to extract all the commonly used
% measurement for the cells. Uses the parameters structure
%
%       cTimelapse.extractionParameters.functionParameters
%
% with fields:
% channels                  : array of channels to extract or the string 'all', in
%                             which case all channels are extracted
%
% type                      : string max,min,sum or std - specifies how to handle
%                             channels referring to z stacks. Stack is retrieved as
%                             stack, turned into a double, and the following
%                             appropriate statistical procedure applied along the
%                             3rd axis.
%                                    max  - takes maximum z projection
%                                    min  - takes maximum z projection
%                                    sum  - takes the sum of z projection
%                                    std  - takes standard deviation of z
%                                           projection
%
% nuclearMarkerChannel    : If a nuclear tag is used, the number of that channel.
%                           if NaN then this is ignored and nuclear
%                           localisation set to zero.
% maxPixOverlap           : number of nuclear pixels used to calculate
%                           nuclearTagLoc. Also used for max5 and membrane max5.
%
% maxAllowedOverlap       : number of candidate nuclear pixels
%
% The standard data extraction method. Calculates a raft of statistics,
% hopefully mostly self explanatory, about the cell pixels. Also allows for
% nuclear localisation measurement by specifying a nuclearMarkerChannel :
% a channel of the timelapse which is a nuclear marker. The max z
% projection of this channel is then used to define nuclear pixels and the
% mean of the maxAllowedOverlap brightest pixels in this nuclear channel is
% used as a candidate set of nuclear pixels. The maxPixOverlap brightest
% pixels in the measurement channel of these candidate pixels are
% determined to be the nuclear ones and the mean of these divided by the
% median of the whole cell are stored as nuclearTagLoc field of
% extractedData.
%
% size and position information common to all cells is stored in the first
% entry of extractedData only.

parameters = cTimelapse.extractionParameters.functionParameters;

type = parameters.type;
channels = parameters.channels;
nuclearMarkerChannel = parameters.nuclearMarkerChannel;
maxPixOverlap = parameters.maxPixOverlap;
maxAllowedOverlap = parameters.maxAllowedOverlap;

%number of candidate pixels should not be larger than number of finally
%allowed centre pixels.
if maxAllowedOverlap<maxPixOverlap
    maxAllowedOverlap = maxPixOverlap;
end


if strcmp(channels,'all')
    channels = 1:length(cTimelapse.channelNames);
end

if ~ismember(nuclearMarkerChannel,channels)
    nuclearMarkerChannel = NaN;
end

numCells=sum(cTimelapse.cellsToPlot(:));
[trap, cells]=find(cTimelapse.cellsToPlot);

%reorder so cells in the same trap contiguous, nicer for viewing later.
[trap,I] = sort(trap);
cells =cells(I);

se2=strel('disk',2);

%preallocate cellInf
for channel=1:length(channels)
    
    extractedData(channel).eccentricity=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).mean=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).median=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).max5=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).std=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).smallmean=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).smallmedian=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).smallmax5=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).min=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).imBackground=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).area=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).radius=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).radiusAC=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).distToNuc=sparse(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).nucArea=sparse(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).radiusFL=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).segmentedRadius=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).xloc=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).yloc=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    
    extractedData(channel).membraneMax5=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).membraneMedian=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).nuclearTagLoc=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    
    %for Elco's data extraction
    extractedData(channel).pixel_sum=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).pixel_variance_estimate=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    %end elcos section
    
    extractedData(channel).trapNum = trap';
    extractedData(channel).cellNum = cells';
    
end

% cell array of images for each channel extracted at each timpoint
tpStacks = cell(size(channels));

for timepoint=find(cTimelapse.timepointsProcessed)
    disp(['Timepoint Number ',int2str(timepoint)]);
    
    for channel=1:length(channels)
        channel_number = channels(channel);
        
        %switch to doube so that mathematical operations are as expected.
        tpStack=cTimelapse.returnSingleTimepoint(timepoint,channel_number,'stack');
        
        % if the channels is the nuclear marker channel, populate the
        % nuclearStack array with max projection, which is taken as a
        % marker of nuclearity.
        if channel_number == nuclearMarkerChannel
            nuclearStack = cTimelapse.returnTrapsFromImage(max(tpStack,[],3),timepoint);
        end
        
        switch type
            case 'max'
                tpStack = max(tpStack,[],3);
            case 'min'
                tpStack = min(tpStack,[],3);
            case 'mean'
                tpStack = mean(tpStack,3);
            case 'std'
                tpStack = std(tpStack,[],3);
            case 'sum'
                tpStack = sum(tpStack,3);
        end
        
        tpStacks{channel} = cTimelapse.returnTrapsFromImage(tpStack,timepoint);
        
    end
    
    trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
    
    seg_areas=tpStacks{channel}(:,:,1);
    cellLocAll=false([size(seg_areas) length(trap)]);
    cellLocAllSmall=false([size(seg_areas) length(trap)]);
    for allIndex =1:length(trap)
        temp_loc=find(trapInfo(trap(allIndex)).cellLabel==cells(allIndex));
        if ~isempty(temp_loc)
            seg_areas=full(trapInfo(trap(allIndex)).cell(temp_loc).segmented);
            loc=double(trapInfo(trap(allIndex)).cell(temp_loc).cellCenter);
            if ~isempty(loc)
                cellLocAll(:,:,allIndex)=seg_areas(:,:,1);
            end
        end
    end
    
    cellLocAllCellsBkg=false([size(seg_areas) length(trap)]);
    for allTrapIndex=1:length(trap)
        if trapInfo(trap(allIndex)).cellsPresent
            for allCells=1:length(trapInfo(trap(allIndex)).cellLabel)
                tSeg=full(trapInfo(trap(allIndex)).cell(allCells).segmented);
                cellLocAllCellsBkg(:,:,allTrapIndex)=cellLocAllCellsBkg(:,:,allTrapIndex)|tSeg;
            end
        end
    end
    
    t=size(cellLocAllCellsBkg,3);
    parfor allIndex=1:size(cellLocAll,3)
        cellLocAll(:,:,allIndex)=imfill(cellLocAll(:,:,allIndex),'holes');
        cellLocAllSmall(:,:,allIndex)=imerode(cellLocAll(:,:,allIndex),se2);
        if allIndex<=t
            cellLocAllCellsBkg(:,:,allIndex)=imfill(cellLocAllCellsBkg(:,:,allIndex),'holes');
        end
    end
    
    
%     
%     parfor allTrapIndex=1:size(cellLocAllCellsBkg,3)
%         cellLocAllCellsBkg(:,:,allTrapIndex)=imfill(cellLocAllCellsBkg(:,:,allTrapIndex),'holes');
%     end
    
    trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
    for channel=1:length(channels)
        channel_number = channels(channel);
        
        if ~all(tpStacks{channel}(:)==0)
            %if empty do nothing
            
            %for Elco's data extraction
            %get background correction and shift in the same way as the actual image for pixel_variance:
            if length(cTimelapse.BackgroundCorrection)>=channel_number && ~isempty(cTimelapse.BackgroundCorrection{channel_number})
                BGcorrection = cTimelapse.BackgroundCorrection{channel_number};
                TimepointBoundaries = fliplr(cTimelapse.offset(channel_number,:));
                BGcorrection = padarray(BGcorrection,abs(TimepointBoundaries));
                LowerTimepointBoundaries = abs(TimepointBoundaries) + TimepointBoundaries +1;
                HigherTimepointBoundaries = cTimelapse.imSize + TimepointBoundaries + abs(TimepointBoundaries);
                BGcorrection = BGcorrection(LowerTimepointBoundaries(1):HigherTimepointBoundaries(1),LowerTimepointBoundaries(2):HigherTimepointBoundaries(2),:);
                BGcorrectionTraps = cTimelapse.returnTrapsFromImage(BGcorrection,timepoint);
                
            else
                BGcorrectionTraps = ones(size(tpStacks{channel}));
            end
            %end elcos section
            
            
            uniqueTraps=unique(trap);
            
            extData=[];
            %pre-allocate so parfor works
            tDatS=sparse(1,length(trap));
            ed_max5=tDatS; ed_mean=tDatS; ed_median=tDatS; ed_min=tDatS;
            ed_std=tDatS;  ed_pixel_sum=tDatS;  ed_membraneMedian=tDatS;
            ed_membraneMax5=tDatS;  ed_smallmax5=tDatS; ed_smallmedian=tDatS;
            ed_smallmean=tDatS; ed_imBackground=tDatS; ed_area=tDatS;  ed_radius=tDatS;
            ed_eccentricity=tDatS;  ed_radiusFL=tDatS; ed_segmentedRadius=tDatS;
            ed_nucArea=tDatS;  ed_distToNuc=tDatS;  ed_radiusAC=tDatS;
            ed_xloc=tDatS;ed_yloc=tDatS;ed_pixel_variance_estimate=tDatS;
            
            tpImCh=tpStacks{channel};
            
            
            
            for allIndex =1:length(trap)
                trapImage=tpImCh(:,:,trap(allIndex));
                
                %for Elco's variance estimate
                BGtrapImage = BGcorrectionTraps(:,:,trap(allIndex));
                temp_loc=find(trapInfo(trap(allIndex)).cellLabel==cells(allIndex));
                
                
                cellLoc=cellLocAll(:,:,allIndex)>0;
                % give the row in cellInf in which data for this cell
                % shoud be inserted.
                if ~isempty(temp_loc) && sum(cellLoc(:))
                    seg_areas=full(trapInfo(trap(allIndex)).cell(temp_loc).segmented);
                    
                    %                     cellLoc=zeros(size(seg_areas));
                    %                     loc=double(trapInfo(trap(allIndex)).cell(temp_loc).cellCenter);
                    %                     if ~isempty(loc)
                    %                         cellLoc=imfill(seg_areas(:,:,1),'holes');
                    %                     end
                    %logical of cell pixels
                    
                    
                    %logical of membrane pixels
                    membraneLoc = seg_areas >0;
                    
                    %vector of cell pixels
                    cellFL=trapImage(cellLoc);
                    
                    %vector of cell membrane pixels
                    membraneFL = trapImage(membraneLoc);
                    
                    %below is the function to extract the fluorescence information
                    %from the cells. Change to mean/median FL etc
                    flsorted=sort(cellFL(:),'descend');
                    mflsorted=sort(membraneFL(:),'descend');
                    
                    %                     numberOverlapPixels = min(maxPixOverlap,length(cellFL));
                    ratioOverlap=ceil(length(cellFL(:))*.025);
                    ratioOverlapCont=length(cellFL(:))*.025;
                    numberOverlapPixels = min(ratioOverlap,length(cellFL));
                    
                    
                    %                         extData{j}.max5(cellIndex)=mean(flsorted(1:numberOverlapPixels));
                    ed_max5(allIndex)=mean(flsorted(1:numberOverlapPixels));
                    ed_mean(allIndex)=mean(cellFL(:));
                    ed_median(allIndex)=median(cellFL(:));
                    ed_std(allIndex)=std(cellFL(:));
                    ed_min(allIndex)=min(cellFL(:));
                    ed_pixel_sum(allIndex)=sum(cellFL(:));
                    ed_membraneMedian(allIndex)=median(membraneFL(:));
                    ed_membraneMax5(allIndex)=mean(mflsorted(1:numberOverlapPixels));
                    
%                     cellLocSmall=imerode(cellLoc,se2);
                    cellLocSmall=cellLocAllSmall(:,:,allIndex);
                    cellFLsmall=trapImage(cellLocSmall);
                    
                    convMatrix=zeros(3,3);
                    convMatrix(2,:)=1;
                    convMatrix(:,2)=1;
                    convMatrix=imresize(convMatrix,ratioOverlapCont/5);

                    flPeak=conv2(double(trapImage),convMatrix,'same');
                    flPeak=flPeak(cellLoc);
                    
                    ed_smallmax5(allIndex)=max(flPeak(:));
                    ed_smallmean(allIndex)=mean(cellFLsmall(:));
                    ed_smallmedian(allIndex)=median(cellFLsmall(:));
                    
                    seg_areas=cellLocAllCellsBkg(:,:,allIndex);
                    seg_areas=~seg_areas;
                    
                    bkg=trapImage(seg_areas);
                    bkg=bkg(~isnan(bkg(:)));
                    if isempty(bkg)
                        bkg=trapImage;
                    end
                    ed_imBackground(allIndex)=median(bkg(:));
                    
                    % information common to all channels (basically
                    % shape information) is stored only in the
                    % channel 1 structure.
                    if channel==1
                        ed_area(allIndex)=length(cellFL);
                        ed_radius(allIndex)= trapInfo(trap(allIndex)).cell(temp_loc).cellRadius;
                        tP=regionprops(cellLoc,'Eccentricity');
                        ed_eccentricity(allIndex)= tP.Eccentricity;
                        %radiusFL populated by extractSegAreaFl
                        %method.
                        if isfield(trapInfo(trap(allIndex)).cell(temp_loc),'cellRadiusFL');
                            ed_radiusFL(allIndex)= trapInfo(trap(allIndex)).cell(temp_loc).cellRadiusFL;%trapInfo(trap(allIndex)).cell(temp_loc).cellRadius;
                        end
                        ed_segmentedRadius(allIndex)= sqrt(sum(cellLoc(:))/pi);%trapInfo(trap(allIndex)).cell(temp_loc).cellRadius;
                        
                        % nucArea populated by extractNucAreaFL method.
                        if isfield(trapInfo(trap(allIndex)).cell(temp_loc),'nucArea');
                            if isempty(trapInfo(trap(allIndex)).cell(temp_loc).nucArea)
                                ed_nucArea(allIndex)=NaN;
                                ed_distToNuc(allIndex)=NaN;
                            else
                                ed_nucArea(allIndex)=trapInfo(trap(allIndex)).cell(temp_loc).nucArea;
                                ed_distToNuc(allIndex)=trapInfo(trap(allIndex)).cell(temp_loc).distToNuc;
                            end
                        end
                        
                        % populated by the active contour methods
                        % run through timelapseTrapsActiveContour
                        if isfield(trapInfo(trap(allIndex)).cell(temp_loc),'radiusAC');
                            ed_radiusAC(allIndex)=trapInfo(trap(allIndex)).cell(temp_loc).radiusAC;
                        end
                        ed_xloc(allIndex)= trapInfo(trap(allIndex)).cell(temp_loc).cellCenter(1);
                        ed_yloc(allIndex)=trapInfo(trap(allIndex)).cell(temp_loc).cellCenter(2);
                        
                    end
                    
                    %for Elco's data extraction
                    if length(cTimelapse.ErrorModel)>=channel_number && ~isempty(cTimelapse.ErrorModel{channel_number})
                        correction_values = BGtrapImage(cellLoc);
                        ErrorModel = cTimelapse.ErrorModel{channel_number};
                        %use cTimelapse ErrorModel (object of error model class) to estimate
                        %variance and expected value of data. division by correction values
                        %is to return data to raw estimate state. In time may want to adjust
                        %to use value estimates if encounter biased errors
                        estimatedVariance = ErrorModel.evaluateError(cellFL./correction_values,[],[],true);
                        
                        %correct variance estimate to take account of multiplication
                        estimatedVariance = estimatedVariance.*(correction_values.^2);
                    else
                        estimatedVariance = zeros(size(cellFL));
                        
                    end
                    ed_pixel_variance_estimate(allIndex) = sum(estimatedVariance);
                    %end elcos section
                end
                
            end
            
            extractedData(channel).max5(:,timepoint)=ed_max5;
            extractedData(channel).mean(:,timepoint)=ed_mean;
            extractedData(channel).median(:,timepoint)=ed_median;
            extractedData(channel).min(:,timepoint)=ed_min;
            extractedData(channel).std(:,timepoint)=ed_std;
            extractedData(channel).pixel_sum(:,timepoint)=ed_pixel_sum;
            extractedData(channel).membraneMedian(:,timepoint)=ed_membraneMedian;
            extractedData(channel).membraneMax5(:,timepoint)=ed_membraneMax5;
            extractedData(channel).smallmax5(:,timepoint)=ed_smallmax5;
            extractedData(channel).smallmedian(:,timepoint)=ed_smallmedian;
            extractedData(channel).smallmean(:,timepoint)=ed_smallmean;
            extractedData(channel).imBackground(:,timepoint)=ed_imBackground;
            if channel==1
                extractedData(channel).area(:,timepoint)=ed_area;
                extractedData(channel).radius(:,timepoint)=ed_radius;
                extractedData(channel).eccentricity(:,timepoint)=ed_eccentricity;
                extractedData(channel).radiusFL(:,timepoint)=ed_radiusFL;
                extractedData(channel).segmentedRadius(:,timepoint)=ed_segmentedRadius;
                extractedData(channel).nucArea(:,timepoint)=ed_nucArea;
                extractedData(channel).distToNuc(:,timepoint)=ed_distToNuc;
                extractedData(channel).radiusAC(:,timepoint)=ed_radiusAC;
                extractedData(channel).xloc(:,timepoint)=ed_xloc;
                extractedData(channel).yloc(:,timepoint)=ed_yloc;
            end
            extractedData(channel).pixel_variance_estimate(:,timepoint)=ed_pixel_variance_estimate;
            
            
            
            
            
        end
    end
end
cTimelapse.extractedData=extractedData;
end
