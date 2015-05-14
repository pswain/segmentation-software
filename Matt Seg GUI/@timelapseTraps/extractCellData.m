function extractCellData(cTimelapse,type,channels,cellSegType)

if nargin<2
    type='max';
end

if nargin<3 || isempty(channels)
    channels = 1:length(cTimelapse.channelNames);    
end

if nargin<4 || isempty(cellSegType)
    cellSegType='segmented';
end


numCells=sum(cTimelapse.cellsToPlot(:));
[trap cell]=find(cTimelapse.cellsToPlot);

s1=strel('disk',2);
% convMatrix2=single(getnhood(strel('disk',2)));

%nuclear tag extraction
channelTag=3;
channelNuclear=2;

if isempty(cTimelapse.timepointsProcessed) || length(cTimelapse.timepointsProcessed)==1
    tempSize=[cTimelapse.cTimepoint.trapInfo];
    cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(1).trapInfo));
    if length(cTimelapse.timepointsProcessed)==1
        %cTimelapse.timepointsProcessed=0; Elco commented out this line, don't know why it was there
    end
end

needChangeBackTo5=false;
switch type
    case 'all'
        numStacks=3;
    case 'max'
        numStacks=1;
    case 'mean'
        numStacks=1;
    case 'std'
        numStacks=1;
end

radiusFLData=isfield(cTimelapse.cTimepoint(find(cTimelapse.timepointsProcessed,1,'first')).trapInfo(1).cell,'cellRadiusFL');


for channel=1:length(channels)
    channel_number = channels(channel);
    BGextracted = false;
    
    if numStacks<2
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
        extractedData(channel).distToNuc=sparse(numCells,length(cTimelapse.timepointsToProcess));
        extractedData(channel).radiusFL=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        extractedData(channel).segmentedRadius=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        extractedData(channel).xloc=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        extractedData(channel).yloc=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        %         extractedData(channel).trapNum=sparse(zeros(1,numCells));
        
        extractedData(channel).membraneMax5=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        extractedData(channel).membraneMedian=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        extractedData(channel).nuclearTagLoc=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        
        %for Elco's data extraction
        extractedData(channel).pixel_sum=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        extractedData(channel).pixel_variance_estimate=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        
        %end elcos section
        
        extractedData(channel).trapNum = [];
        extractedData(channel).cellNum = [];
        
    else
        extractedData(channel).mean=(zeros(numCells,length(cTimelapse.timepointsProcessed),numStacks));
        extractedData(channel).median=(zeros(numCells,length(cTimelapse.timepointsProcessed),numStacks));
        extractedData(channel).max5=(zeros(numCells,length(cTimelapse.timepointsProcessed),numStacks));
        extractedData(channel).std=(zeros(numCells,length(cTimelapse.timepointsProcessed),numStacks));
        extractedData(channel).smallmean=(zeros(numCells,length(cTimelapse.timepointsProcessed),numStacks));
        extractedData(channel).smallmedian=(zeros(numCells,length(cTimelapse.timepointsProcessed),numStacks));
        extractedData(channel).smallmax5=(zeros(numCells,length(cTimelapse.timepointsProcessed),numStacks));
        extractedData(channel).min=(zeros(numCells,length(cTimelapse.timepointsProcessed),numStacks));
        extractedData(channel).imBackground=(zeros(numCells,length(cTimelapse.timepointsProcessed),numStacks));
        extractedData(channel).area=(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        extractedData(channel).radius=(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        extractedData(channel).xloc=(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        extractedData(channel).yloc=(zeros(numCells,length(cTimelapse.timepointsProcessed)));
        extractedData(channel).membraneMax5=zeros(numCells,length(cTimelapse.timepointsProcessed));
        extractedData(channel).membraneMedian=zeros(numCells,length(cTimelapse.timepointsProcessed));
        
        
        extractedData(channel).nuclearTagLoc=zeros(numCells,length(cTimelapse.timepointsProcessed));
        
        %for Elco's data extraction
        extractedData(channel).pixel_sum=zeros(numCells,length(cTimelapse.timepointsProcessed));
        extractedData(channel).pixel_variance_estimate=zeros(numCells,length(cTimelapse.timepointsProcessed));
        
        %end elcos section
        
        extractedData(channel).trapNum = [];
        extractedData(channel).cellNum = [];
    end
    
    
    for timepoint=find(cTimelapse.timepointsProcessed)
        
        if cTimelapse.timepointsProcessed(timepoint)
            disp(['Timepoint Number ',int2str(timepoint)]);
            %     uniqueTraps=unique(traps);
            %modify below code to use the cExperiment.searchString rather
            %than just channel=2;
            
            %             trapImages=cTimelapse.returnTrapsTimepoint(traps,timepoint,channel);
            
            tpStack=cTimelapse.returnSingleTimepoint(timepoint,channel_number,'stack');
            
            %for Elco's data extraction
            %get background correction and shift in the same way as the actual image for pixel_variance:
            if ~BGextracted
                if length(cTimelapse.BackgroundCorrection)>=channel_number && ~isempty(cTimelapse.BackgroundCorrection{channel_number})
                    BGcorrection = cTimelapse.BackgroundCorrection{channel_number};
                    TimepointBoundaries = fliplr(cTimelapse.offset(channel_number,:));
                    BGcorrection = padarray(BGcorrection,abs(TimepointBoundaries));
                    LowerTimepointBoundaries = abs(TimepointBoundaries) + TimepointBoundaries +1;
                    HigherTimepointBoundaries = [size(tpStack,1),size(tpStack,2)] + TimepointBoundaries + abs(TimepointBoundaries);
                    BGcorrection = BGcorrection(LowerTimepointBoundaries(1):HigherTimepointBoundaries(1),LowerTimepointBoundaries(2):HigherTimepointBoundaries(2),:);
                    
                else
                    BGcorrection = ones(size(tpStack,1),size(tpStack,2));
                end
                BGextracted = true;
            end
            %end elcos section
            
            
            if(channel_number==channelNuclear && length(cTimelapse.channelNames)>2)
                
                tpStack_3=cTimelapse.returnSingleTimepoint(timepoint,channelTag,'stack'); %% Extract from mCherry channel.
                
                
                
                if size(size(tpStack_3),2)==3
                    areStacks=1;
                else
                    areStacks=0;
                end
                
                
            end
            
            
            %             trapImagesStd=cTimelapse.returnTrapsTimepoint(traps,timepoint,channel,'std');
            %             trapImagesMean=cTimelapse.returnTrapsTimepoint(traps,timepoint,channel,'mean');
            
            
            trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
            uniqueTraps=unique(trap);
            dataInd=0;
            for j=1:length(uniqueTraps)%j=1:length(extractedData(channel).cellNum)
                currTrap=uniqueTraps(j);% extractedData(channel).trapNum(j);
                cellsCurrTrap=cell(trap==currTrap);
                
                
                if cTimelapse.trapsPresent
                    trapImages=returnTrapStack(cTimelapse,tpStack,currTrap,timepoint);
                    
                    %for Elco's variance estimate
                    BGtrapImage = returnTrapStack(cTimelapse,BGcorrection,currTrap,timepoint);
                    
                    %for nuclear tag extraction. Getting FL info from mCh
                    if(channel_number==channelNuclear && length(cTimelapse.channelNames)>2)
                        trapImages2= returnTrapStack(cTimelapse,tpStack_3,currTrap,timepoint);
                    end
                    
                else
                    trapImages=tpStack;
                    
                    %for Elcos' variance estimate
                    BGtrapImage = BGcorrection;
                    
                    %for nuclear tag extraction. Getting FL info from mCh:
                    if(channel_number==channelNuclear && length(cTimelapse.channelNames)>2)
                        trapImages2=tpStack_3;
                    end
                    
                end
                
                for cellIndex=1:length(cellsCurrTrap)
                    currCell=cellsCurrTrap(cellIndex);
                    temp_loc=find(trapInfo(currTrap).cellLabel==currCell);
                    
                    dataInd=dataInd+1;
                    if isempty(temp_loc)
                    else
                        
                        if isfield(trapInfo(currTrap).cell(temp_loc),cellSegType)
                            if ~isempty(trapInfo(currTrap).cell(temp_loc).(cellSegType));
                                seg_areas=full(trapInfo(currTrap).cell(temp_loc).(cellSegType));
                            else
                                seg_areas=full(trapInfo(currTrap).cell(temp_loc).segmented);
                            end
                        else
                            seg_areas=full(trapInfo(currTrap).cell(temp_loc).segmented);
                        end
                        segLabel=zeros(size(seg_areas));
                        loc=double(cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(temp_loc).cellCenter);
                        if ~isempty(loc)
                            segLabel=imfill(seg_areas(:,:,1),'holes');%sub2ind(size(seg_areas(:,:,1)),loc(2),loc(1)));
                        end
                        cellLoc=segLabel>0;
                        
                        membraneLoc = seg_areas >0;
                        
                        tStd=[];tMean=[];
                        for l=1:size(trapImages,3)
                            tempIm=double(trapImages(:,:,l));
                            tempIm=tempIm(cellLoc);
                            tStd(l)=std(tempIm(:));
                            tMean(l)=mean(tempIm(:));
                            
                            %for nuclear tag extraction. Getting FL info from mCh:
                            if(channel_number==channelNuclear && length(cTimelapse.channelNames)>2 )
                                if( areStacks==1)
                                    tempIm2=double(trapImages2(:,:,l));
                                    tempIm2=tempIm2(cellLoc);
                                    
                                else
                                    
                                    tempIm2=tempIm;
                                end
                            end
                            
                        end
                        [b indStd]=max(tStd);
                        [b indMean]=max(tMean);
                        
                        switch type
                            %                         case 'all'
                            %                             trapImWhole(:,:,1)=max(trapImages,[],3);
                            %                             trapImWhole(:,:,2)=trapImages(:,:,indStd);
                            %                             trapImWhole(:,:,3)=trapImages(:,:,indMean);
                            case 'max'
                                trapImWhole(:,:,1)=max(trapImages,[],3);
                                
                                %for nuclear tag extraction. Getting FL info from mCh:
                                if(channel_number==channelNuclear && length(cTimelapse.channelNames)>2)
                                    trapImWhole2(:,:,1)=max(trapImages2,[],3);
                                else
                                    trapImWhole2(:,:,1) =trapImWhole;
                                end
                            case 'std'
                                trapImWhole(:,:,1)=trapImages(:,:,indStd);
                            case 'mean'
                                trapImWhole(:,:,1)=trapImages(:,:,indMean);
                        end
                        
                        for k=1:size(trapImWhole,3)
                            trapIm=trapImWhole(:,:,k);
                            cellFL=trapIm(cellLoc);
                            
                            %for nuclear tag extraction. Getting FL info from mCh:
                            if(channel_number==channelNuclear && length(cTimelapse.channelNames)>2)
                                trapIm2=trapImWhole2(:,:,k);
                                cellFL2=trapIm2(cellLoc);
                            else
                                trapIm2=trapIm;
                                cellFL2=cellFL;
                            end
                            
                            membraneFL = trapIm(membraneLoc);
                            
                            %This is a silly debug to catch cells too small for
                            %a max5 calculation
                            if sum(cellLoc(:))>5
                                %below is the function to extract the fluorescence information
                                %from the cells. Change to mean/median FL etc
                                flsorted=sort(cellFL(:),'descend');
                                mflsorted=sort(membraneFL(:),'descend');
                                
                                
                                %NUCLEAR EXTRACTION
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                flsorted2=sort(cellFL2(:),'descend');
                                
                                maxPixGFP=25;
                                maxPixOverlap=5;
                                needChangeBackTo5=false;
                                
                                [max5_ indmax5_]=sort(cellFL2(:),'descend'); %nuclear tag pixels sorted
                                
                                c=zeros(size(cellFL2));
                                
                                if length(indmax5_)>maxPixGFP
                                    c(indmax5_(1:maxPixGFP))=1;
                                    nucleusValHOG=sort(cellFL(indmax5_(1:maxPixGFP)),'descend');% max values in HOG channel inside nucleus area.
                                    nuclocalization2 = double( mean( nucleusValHOG(1:maxPixOverlap) ) )./double(median(cellFL(:)));
                                else
                                    c(indmax5_(1:5))=1; %limit for very small cells.
                                    nucleusValHOG=sort(cellFL(indmax5_(1:5)),'descend');% max values in HOG channel inside nucleus area.
                                    nuclocalization2 = double( mean( nucleusValHOG(1:5) ) )./double(median(cellFL(:)));
                                end
                                %END NUCLEAR
                                %EXTRACTION%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                
                                convMatrix=zeros(3,3);
                                convMatrix(2,:)=1;convMatrix(:,2)=1;
                                %                 flPeak=conv2(single(trapIm),convMatrix);
                                %                 flPeak=flPeak(cellLoc);
                                if issparse(extractedData(channel).radius)
                                    extractedData(channel).area(dataInd,timepoint)=length(cellFL);
                                    extractedData(channel).max5(dataInd,timepoint)=mean(flsorted(1:5));
                                    extractedData(channel).mean(dataInd,timepoint)=mean(cellFL(:));
                                    extractedData(channel).median(dataInd,timepoint)=median(cellFL(:));
                                    
                                    extractedData(channel).membraneMedian(dataInd, timepoint)=median(membraneFL(:));
                                    extractedData(channel).membraneMax5(dataInd, timepoint)=mean(mflsorted(1:5));
                                    
                                    extractedData(channel).nuclearTagLoc(dataInd,timepoint)=nuclocalization2 ;
                                    
                                    cellLocSmall=imerode(cellLoc,s1);
                                    if sum(cellLocSmall)<1
                                    end
                                    cellFLsmall=trapIm(cellLocSmall);
                                    flPeak=conv2(double(trapIm),convMatrix);
                                    flPeak=flPeak(cellLoc);
                                    
                                    extractedData(channel).smallmax5(dataInd,timepoint)=max(flPeak(:));
                                    extractedData(channel).smallmean(dataInd,timepoint)=mean(cellFLsmall(:));
                                    extractedData(channel).smallmedian(dataInd,timepoint)=median(cellFLsmall(:));
                                    
                                    seg_areas=zeros(size(trapInfo(currTrap).cell(1).segmented));
                                    for allCells=1:length(trapInfo(currTrap).cellLabel)
                                        % to catch bugs when segmented channel is empty
                                        if ~isfield(trapInfo(currTrap).cell(temp_loc),cellSegType) 
                                            tSeg=full(trapInfo(currTrap).cell(allCells).segmented);
                                        else
                                            tSeg=full(trapInfo(currTrap).cell(allCells).(cellSegType));
                                        end
                                        
                                        if isempty(tSeg)
                                            tSeg=full(trapInfo(currTrap).cell(allCells).segmented);
                                        end
                                        seg_areas=seg_areas|tSeg;
                                        
                                        %                         seg_areas=imdilate(seg_areas,s1);
                                        loc=double(cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(allCells).cellCenter);
                                        if ~isempty(loc)
                                            seg_areas=imfill(seg_areas(:,:,1),'holes');%sub2ind(size(seg_areas(:,:,1))loc(2),loc(1)));
                                        end
                                    end
                                    %                     seg_areas=imdilate(seg_areas,s1);
                                    seg_areas=~seg_areas;
                                    
                                    bkg=trapIm(seg_areas);
                                    bkg=bkg(~isnan(bkg(:)));
                                    if isempty(bkg)
                                        bkg=trapIm;
                                    end
                                    extractedData(channel).std(dataInd,timepoint)=std(double(cellFL(:)));
                                    extractedData(channel).imBackground(dataInd,timepoint)=median(bkg(:));
                                    extractedData(channel).min(dataInd,timepoint)=min(cellFL(:));
                                    
                                    if channel==1
                                        extractedData(channel).radius(dataInd,timepoint)= trapInfo(currTrap).cell(temp_loc).cellRadius;
                                        if radiusFLData
                                            extractedData(channel).radiusFL(dataInd,timepoint)= trapInfo(currTrap).cell(temp_loc).cellRadiusFL;%trapInfo(currTrap).cell(temp_loc).cellRadius;
                                        end
                                        extractedData(channel).segmentedRadius(dataInd,timepoint)= sqrt(sum(cellLoc(:))/pi);%trapInfo(currTrap).cell(temp_loc).cellRadius;
                                        if isfield(trapInfo(currTrap).cell(temp_loc),'nucArea');
                                            if isempty(trapInfo(currTrap).cell(temp_loc).nucArea)
                                                extractedData(channel).nucArea(dataInd,timepoint)=NaN;
                                                extractedData(channel).distToNuc(dataInd,timepoint)=NaN;
                                            else
                                                extractedData(channel).nucArea(dataInd,timepoint)=trapInfo(currTrap).cell(temp_loc).nucArea;
                                                extractedData(channel).distToNuc(dataInd,timepoint)=trapInfo(currTrap).cell(temp_loc).distToNuc;
                                            end
                                        end
                                        if isfield(trapInfo(currTrap).cell(temp_loc),'radiusAC');
                                            extractedData(channel).radiusAC(dataInd,timepoint)=trapInfo(currTrap).cell(temp_loc).radiusAC;
                                        end
                                        extractedData(channel).xloc(dataInd,timepoint)= trapInfo(currTrap).cell(temp_loc).cellCenter(1);
                                        extractedData(channel).yloc(dataInd,timepoint)=trapInfo(currTrap).cell(temp_loc).cellCenter(2);
                                        extractedData(channel).trapNum(dataInd)=currTrap;
                                        extractedData(channel).cellNum(dataInd)=currCell;
                                    end
                                    
                                else
                                    extractedData(channel).area(dataInd,timepoint,k)=length(cellFL);
                                    extractedData(channel).max5(dataInd,timepoint,k)=mean(flsorted(1:5));
                                    extractedData(channel).mean(dataInd,timepoint,k)=mean(cellFL(:));
                                    extractedData(channel).median(dataInd,timepoint,k)=median(cellFL(:));
                                    
                                    
                                    extractedData(channel).membraneMedian(dataInd, timepoint)=median(membraneFL(:));
                                    extractedData(channel).membraneMax5(dataInd, timepoint)=mean(mflsorted(1:5));
                                    
                                    extractedData(channel).nuclearTagLoc(dataInd,timepoint)=nuclocalization2 ;
                                    
                                    cellLocSmall=imerode(cellLoc,s1);
                                    if sum(cellLocSmall)<1
                                    end
                                    
                                    cellFLsmall=trapIm(cellLocSmall);
                                    flPeak=conv2(double(trapIm),convMatrix);
                                    flPeak=flPeak(cellLoc);
                                    
                                    extractedData(channel).smallmax5(dataInd,timepoint,k)=max(flPeak(:));
                                    extractedData(channel).smallmean(dataInd,timepoint,k)=mean(cellFLsmall(:));
                                    extractedData(channel).smallmedian(dataInd,timepoint,k)=median(cellFLsmall(:));
                                    
                                    seg_areas=zeros(size(trapInfo(currTrap).cell(1).segmented));
                                    for allCells=1:length(trapInfo(currTrap).cellLabel)
                                        seg_areas=seg_areas|full(trapInfo(currTrap).cell(allCells).(cellSegType));
                                        %                         seg_areas=imdilate(seg_areas,s1);
                                        loc=double(cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(allCells).cellCenter);
                                        if ~isempty(loc)
                                            seg_areas=imfill(seg_areas(:,:,1),'holes');%sub2ind(size(seg_areas(:,:,1))loc(2),loc(1)));
                                        end
                                    end
                                    %                     seg_areas=imdilate(seg_areas,s1);
                                    seg_areas=~seg_areas;
                                    
                                    bkg=trapIm(seg_areas);
                                    bkg=bkg(~isnan(bkg(:)));
                                    if isempty(bkg)
                                        bkg=trapIm;
                                    end
                                    extractedData(channel).std(dataInd,timepoint,k)=std(double(cellFL(:)));
                                    extractedData(channel).imBackground(dataInd,timepoint,k)=median(bkg(:));
                                    extractedData(channel).min(dataInd,timepoint,k)=min(cellFL(:));
                                    
                                    if channel==1
                                        extractedData(channel).radius(dataInd,timepoint,k)= trapInfo(currTrap).cell(temp_loc).cellRadius;
                                        if radiusFLData
                                            extractedData(channel).radiusFL(dataInd,timepoint)= trapInfo(currTrap).cellRadiusFL;%trapInfo(currTrap).cell(temp_loc).cellRadius;
                                        end
                                        if isfield(trapInfo(currTrap).cell(temp_loc),'nucArea');
                                            if isempty(trapInfo(currTrap).cell(temp_loc).nucArea)
                                                extractedData(channel).nucArea(j,timepoint)=NaN;
                                                extractedData(channel).distToNuc(j,timepoint)=NaN;
                                            else
                                                extractedData(channel).nucArea(j,timepoint)=trapInfo(currTrap).cell(temp_loc).nucArea;
                                                extractedData(channel).distToNuc(j,timepoint)=trapInfo(currTrap).cell(temp_loc).distToNuc;
                                            end
                                        end
                                        extractedData(channel).segmentedRadius(dataInd,timepoint,k)= sqrt(sum(cellLoc(:))/pi);%trapInfo(currTrap).cell(temp_loc).cellRadius;
                                        extractedData(channel).xloc(dataInd,timepoint,k)= trapInfo(currTrap).cell(temp_loc).cellCenter(1);
                                        extractedData(channel).yloc(dataInd,timepoint,k)=trapInfo(currTrap).cell(temp_loc).cellCenter(2);
                                        extractedData(channel).trapNum(dataInd)=currTrap;
                                        extractedData(channel).cellNum(dataInd)=currCell;
                                    end
                                    
                                    
                                end
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
                            
                            if issparse(extractedData(channel).radius) %ensures that arrays are sparse if possible
                                extractedData(channel).pixel_variance_estimate(dataInd,timepoint) = sum(estimatedVariance);
                                extractedData(channel).pixel_sum(dataInd,timepoint) = sum(cellFL);
                            else
                                extractedData(channel).pixel_variance_estimate(dataInd,timepoint,k) = sum(estimatedVariance);
                                extractedData(channel).pixel_sum(dataInd,timepoint,k) = sum(cellFL);
                            end
                            
                            %end elcos section
                            
                            
                        end
                    end
                    
                end
            end
        end
    end
end
cTimelapse.extractedData=extractedData;

if needChangeBackTo5
    fprintf('Change back to 5 pixels for nuc extraction')
end



function trapsTimepoint=returnTrapStack(cTimelapse,image,trap,timepoint)

cTrap=cTimelapse.cTrapSize;
bb=max([cTrap.bb_width cTrap.bb_height])+100;
bb_image=padarray(image,[bb bb]);
trapsTimepoint=zeros(2*cTrap.bb_height+1,2*cTrap.bb_width+1,size(image,3),class(image));
for j=1:size(image,3)
    y=round(cTimelapse.cTimepoint(timepoint).trapLocations(trap).ycenter + bb);
    x=round(cTimelapse.cTimepoint(timepoint).trapLocations(trap).xcenter + bb);
    %             y=round(cTimelapse.cTimepoint(timepoint).trapLocations(traps(j),2) + bb);
    %             x=round(cTimelapse.cTimepoint(timepoint).trapLocations(traps(j),1) + bb);
    temp_im=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width,j);
    temp_im(temp_im==0)=mean(temp_im(:));
    trapsTimepoint(:,:,j)=temp_im;
end


