function extractSegAreaFl(cTimelapse, channelStr, type,replaceOldSegmented)
% extractSegAreaFl(cTimelapse, channelStr, type,replaceOldSegmented)
%
% cTimelapse            :   object of the timelapseTraps class
% channelStr            :   string of which channel to use for getting
%                           fluorescent area - should be one of those in
%                           cTimelapse.channelNames
% type                  :   type to handle stacks passed to returnTrapsTimepoint (min/max/std)
% replaceOldSegmented   :   boolean :
%                           true - replace the cell outline
%                           with the one found from this method running
%                           active contour method on fluorescent image.
%                           false - keep original cell outline and just
%                           calculate radiusFL.
%
% The method was written by Matt and I don't follow all the steps(Elco) it
% applies the matlab activecontour function with chan Vese method to the
% fluorescent images specified by channelStr to get an active contour outline.
% Depending on the value of replaceOldSegmented it will replace the outline
% with the trapInfo.cell.segmented with the one found or simply fill in the
% radiusFL field of cell, which is taken to be a more reliable estimate of
% size. 
%
% *************************
% Having dug into it a little moreI now think I know how it works (Elco) at
% its heart - deep in its cavernous and labaryinthine chest - what it does
% is to take the chanvese result, expand the hough circle found by the
% original code by an arbitrary factor of 1.5 and then define the new
% outline as those pixels which are in BOTH the expanded circle and the
% chan-vese result. i.e. newSeg = chanvese & original_circle_seg
%
% this is in the returnSegmentedArea subfunction and I have labelled it as
% heart of the code
% *************************
%
%
% applies some other heuristics such as checking the overlap between old
% and new segmentations is above a threshold before replacing. Check code
% for more details.
%
% It also resets cTimelapse.offset to zero, so if you are using a channel
% for the segmentation that is not aligned with a channel you wish to
% extract you will need to reset cTimelapse.offset
% this is particularly strange since it doesn't do this before doing the
% chan vese - so I would guess it would offset the image relative to its
% own image.
%
% only runs on cellsToPlot - so cells need to be selected before running
% the method.
%


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

if nargin<4 
    replaceOldSegmented=true;
end


% check if the channel string provided by the user exists
channel = find(strcmp(cTimelapse.channelNames,channelStr));

if isempty(channel)
    error(['Channel ' channelStr ' does not exist'] )
end



% for each timepoint
% h=figure
for timepoint=1:length(cTimelapse.timepointsProcessed)
    PrintReportString(timepoint,40);
    if cTimelapse.timepointsProcessed(timepoint)
        % Trigger the TimepointChanged event for experimentLogging
        experimentLogging.changeTimepoint(cTimelapse,timepoint);
        
        %     uniqueTraps=unique(traps);
        %modify below code to use the cExperiment.searchString rather
        %than just channel=2;
        
        
        tpStack=cTimelapse.returnTrapsTimepoint([],timepoint,channel,type);
        trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;

        %in case ethere is no fluorescent image at that tp, make it 0
        if ~sum(tpStack(:))
            for trapIndex=1:length(trapInfo)
                for cellIndex=1:length(trapInfo(trapIndex).cell)
                    cTimelapse.cTimepoint(timepoint).trapInfo(trapIndex).cell(cellIndex).cellRadiusFL=0;%trapInfo(trapIndex).cell(cellIndex).cellRadius;
                end
            end
            
            %if there is a fluorescent image, do the following
        else
            
            bw=cell(length(trapInfo));
            bw2=cell(length(trapInfo));
            parfor trapIndex=1:length(trapInfo)
                bwStart=zeros([size(tpStack,1) size(tpStack,2)])>0;
                if trapInfo(trapIndex).cellsPresent
%                     for cellIndex=1:length(trapInfo(trapIndex).cell)
%                         bwStart=bwStart | imfill(full(trapInfo(trapIndex).cell(cellIndex).segmented),'holes');
%                     end
                    tpIm=tpStack(:,:,trapIndex);
                    flValues=tpIm(bwStart);
                    [v ind]=sort(flValues,'descend');
                    bwStartLoc=find(bwStart(:));
                    numP=1:floor(sum(bwStart(:))*.02);
                    tpIm=double(tpIm);
                    tpIm=tpIm/max(tpIm(:));
                    bwStart=im2bw((tpIm),graythresh(tpIm));
                    bwStart=imdilate(bwStart,strel('disk',1));

                    bw2{trapIndex}=bwStart;
                    tpIm(bwStartLoc(ind(numP)))=v(numP+length(numP)+3);
%                     bw{trapIndex} = activecontour(tpIm,bwStart,120,'chan-vese','SmoothFactor',.7,'ContractionBias',-.1);
                                        bw{trapIndex} = activecontour(tpIm,bwStart,110,'chan-vese',.7);
                else
                    bw{trapIndex}=bwStart;
                    bw2{trapIndex}=bwStart;
                end
            end
            
            for trapIndex=1:length(trapInfo)
                trapImages=tpStack(:,:,trapIndex);
                trapImWhole=trapImages;
                currTrap=trapIndex;
                trapIm=trapImWhole;
                im=medfilt2(trapIm,[3 3]);
                im=double(im);
                im=im/max(im(:));
                rawimg=im*255;
                
                cirrad=[trapInfo(currTrap).cell(:).cellRadius];
                if ~isempty(cirrad)
                    radRangeT=[min(cirrad)-2 max(cirrad)+1];
                    radRangeT(1)=max(radRangeT(1),3);
                    radRangeT(2)=max(radRangeT(2),4);
                    %                 [centers,radii,metric]=imfindcircles(bw2{trapIndex},radRangeT,'Sensitivity',1);
                    centers=[];radii=cirrad;
                    %returns too many circles, so if there are crazy numbers of
                    %circles, only use the most likely circles
%                     if length(cirrad)+1>radii
%                         bwCirc.centers=centers(1:length(cirrad)+1,:);bwCirc.radii=radii(1:length(cirrad)+1);
%                     else
                        bwCirc.centers=centers;bwCirc.radii=radii;
%                     end
                end
                
                for cellIndex=1:length(trapInfo(trapIndex).cell)
                    cc = cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).cellCenter;
                    if ~isempty(cc) 
                        circenT=[trapInfo(currTrap).cell(:).cellCenter];
                        circen=[];
                        circen(:,1)=circenT(1:2:end);
                        circen(:,2)=circenT(2:2:end);
                        
                        
                        % get the segmented area
                        if min(size(bwCirc.radii))>0
                            [seg, oldSeg]= returnSegmentedArea(im,bw{trapIndex},cc,circen,cirrad,bwCirc);
                        else
                            seg=[];
                        end
                        
                        if ~isempty(seg)
                            %                         oldSeg=cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).segmented;
                            %                         oldSeg=imfill(full(oldSeg),'holes');
                            overlap=double(sum(seg(oldSeg(:)>0)))/double(sum(oldSeg(:)));
                            if overlap>.2
                                % store the segmented area
                                edgeSeg= bwmorph(seg,'remove');
                                if replaceOldSegmented
                                    cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).segmented=sparse(edgeSeg>0);
                                    % overwrite the offset so that you
                                    % don't accidentally offset the image
                                    % that was segmented with the
                                    % fluorescence
                                    cTimelapse.offset=zeros(size(cTimelapse.offset));
                                else
                                    cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).segmentedFL = sparse(edgeSeg>0);
                                end
                                cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).cellRadiusFL=sqrt(sum(seg(:))/pi);
                                
                            else
                                cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).cellRadiusFL=sqrt(sum(oldSeg(:))/pi);
                            end
                        else
                            cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).cellRadiusFL=trapInfo(trapIndex).cell(cellIndex).cellRadius;
                        end
                    else
                        cTimelapse.cTimepoint(timepoint).trapInfo(currTrap).cell(cellIndex).cellRadiusFL=[];
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




function [bwNew temp_im]= returnSegmentedArea(im,bw,ccenter,circen,cirrad,bwCirc)


% bw=im2bw(im,1.1*graythresh(im));

bwNew=[];
if ~isempty(circen)
        numCells = knnsearch(circen,double(ccenter),'K',1);
     
%     cirrad=cirrad(numCells);
    nseg=80;
    temp_im=zeros(size(im))>0;
    
    x=circen(numCells,1);y=circen(numCells,2);r=cirrad(numCells);
    
    %below is to calculate the radius using the bw image based on the
    %fluorescence
%     centers=bwCirc.centers;radii=bwCirc.radii;
%     [centers,radii]=imfindcircles(bw,[3 r+4],'Sensitivity',1);
%     numCells = knnsearch([centers radii],[double(ccenter) cirrad(numCells)],'K',1);
%     x=centers(numCells,1);y=centers(numCells,2);r=radii(numCells);

    r=r*1.15+1;
% x=circen(:,1);y=circen(:,2);r=cirrad;

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
    
    %%%%% HEART OF THE CODE
    bwNew(temp_im)=bw(temp_im);
    %%%%%%
    
    bwT=double(bw);bwT(bwNew>0)=2;
    %figure;imshow(bwT,[]);impixelinfo;title(num2str(r-1));pause(.1);
    
    %to calculate the original segmentation in case active contour was used
            numCells = knnsearch(circen,double(ccenter),'K',1);

        cirrad=cirrad;
            x=circen(numCells,1);y=circen(numCells,2);r=cirrad(numCells);
    temp_im=zeros(size(im))>0;
    r=double(r);
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
end

