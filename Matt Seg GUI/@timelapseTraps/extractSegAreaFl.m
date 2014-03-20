function extractSegAreaFl(cTimelapse, channelStr, type)

if nargin<3
    type='max';
end

[trapNum, cellNum]=find(cTimelapse.cellsToPlot);

s1=strel('disk',2);
% convMatrix2=single(getnhood(strel('disk',2)));


if isempty(cTimelapse.timepointsProcessed) || length(cTimelapse.timepointsProcessed)==1
    tempSize=[cTimelapse.cTimepoint.trapInfo];
    cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(1).trapInfo));
    if length(cTimelapse.timepointsProcessed)==1
        cTimelapse.timepointsProcessed=0;
    end
end

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


% check if the channel string provided by the user exists
channel = find(strcmp(cTimelapse.channelNames,channelStr));

if isempty(channel)
    error(['Channel ' channelStr ' does not exist'] )
end



% for each timepoint
% h=figure
for timepoint=1:length(cTimelapse.timepointsProcessed)
    if cTimelapse.timepointsProcessed(timepoint)
        disp(['Timepoint Number ',int2str(timepoint)]);
        
        %     uniqueTraps=unique(traps);
        %modify below code to use the cExperiment.searchString rather
        %than just channel=2;
        
        
        tpStack=cTimelapse.returnSingleTimepoint(timepoint,channel,'stack');
        
        trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
        
        for trapIndex=1:length(trapInfo)
            if cTimelapse.trapsPresent
                trapImages=returnTrapStack(cTimelapse,tpStack,trapIndex,timepoint);
            else
                trapImages=tpStack;
            end
            
            tStd=[];tMean=[];
            for l=1:size(trapImages,3)
                tempIm=double(trapImages(:,:,l));
                tStd(l)=std(tempIm(:));
                tMean(l)=mean(tempIm(:));
            end
            [b, indStd]=max(tStd);
            [b, indMean]=max(tMean);
            
            switch type
                case 'max'
                    trapImWhole(:,:,1)=max(trapImages,[],3);
                case 'std'
                    trapImWhole(:,:,1)=trapImages(:,:,indStd);
                case 'mean'
                    trapImWhole(:,:,1)=trapImages(:,:,indMean);
            end
            
            
            currTrap=trapIndex;
            trapIm=trapImWhole;
            im=medfilt2(trapIm,[3 3]);
            im=double(im);
            im=im/max(im(:));
            rawimg=im*255;
            [~, circen, cirrad] = CircularHough_Grd(rawimg, [2 10],1);
            
            for cellIndex=1:length(trapInfo(trapIndex).cell)
                cc = cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).cellCenter;
                if ~isempty(cc)
                    % get the segmented area
                    seg = returnSegmentedArea(im,cc,circen,cirrad);
                    
                    if ~isempty(seg)
                        oldSeg=cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).segmented;
                        oldSeg=imfill(full(oldSeg),'holes');
                        overlap=double(sum(seg(oldSeg(:)>0)))/double(sum(oldSeg(:)));
                        if overlap>.1
                            % store the segmented area
                            edgeSeg= bwmorph(seg,'remove');
                            cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).segmented = edgeSeg>0;
                            cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).cellRadius=sqrt(sum(seg(:))/pi);
                        else
                        end
                    else
                    end
                end
            end
        end
    end
end







function trapsTimepoint=returnTrapStack(cTimelapse,image,trap,timepoint)

cTrap=cTimelapse.cTrapSize;
bb=max([cTrap.bb_width cTrap.bb_height])+100;
bb_image=padarray(image,[bb bb]);
trapsTimepoint=zeros(2*cTrap.bb_height+1,2*cTrap.bb_width+1,size(image,3),'uint16');
for j=1:size(image,3)
    y=round(cTimelapse.cTimepoint(timepoint).trapLocations(trap).ycenter + bb);
    x=round(cTimelapse.cTimepoint(timepoint).trapLocations(trap).xcenter + bb);
    %             y=round(cTimelapse.cTimepoint(timepoint).trapLocations(traps(j),2) + bb);
    %             x=round(cTimelapse.cTimepoint(timepoint).trapLocations(traps(j),1) + bb);
    temp_im=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width,j);
    temp_im(temp_im==0)=mean(temp_im(:));
    trapsTimepoint(:,:,j)=temp_im;
end




function bwNew = returnSegmentedArea(im,ccenter,circen,cirrad)

bw=im2bw(im,1.1*graythresh(im));
rawimg=im*255;

bwNew=[];
if ~isempty(circen)
        numCells = knnsearch(circen,double(ccenter),'K',1);
        
        
    
    cirrad=cirrad+2;
    nseg=80;
    temp_im=zeros(size(bw))>0;
    
    x=circen(numCells,1);y=circen(numCells,2);r=cirrad(numCells);
    x=double(x);y=double(y);r=double(r);
    if r<11
        theta = 0 : (2 * pi / nseg) : (2 * pi);
    elseif r<18
        theta = 0 : (2 * pi / nseg/2) : (2 * pi);
    else
        theta = 0 : (2 * pi / nseg/4) : (2 * pi);
    end
    
    
    pline_x = round(r * cos(theta) + x);
    pline_y = round(r * sin(theta) + y);
    loc=find(pline_x>size(temp_im,2) | pline_x<1 | pline_y>size(temp_im,1) | pline_y<1);
    pline_x(loc)=[];pline_y(loc)=[];
    for j=1:length(pline_x)
        temp_im(pline_y(j),pline_x(j),1)=1;
    end
    locfill=[y x];
    temp_im=imfill(temp_im,round(locfill))>0;
    
    bwNew=zeros(size(bw));
    bwNew(temp_im)=bw(temp_im);
end

