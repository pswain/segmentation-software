function extractNucAreaFL(cTimelapse, channelStr, type,flThresh)

if nargin<3
    type='sum';
end

if nargin<4
    flThresh=500;
end

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

%
se2=strel('disk',1);
% for each timepoint
%% h=figure
for timepoint=1:length(cTimelapse.timepointsProcessed)
    if cTimelapse.timepointsProcessed(timepoint)
        disp(['Timepoint Number ',int2str(timepoint)]);
        
        %     uniqueTraps=unique(traps);
        %modify below code to use the cExperiment.searchString rather
        %than just channel=2;
        
        
        tpStack=cTimelapse.returnTrapsTimepoint([],timepoint,channel,type);
        trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
        
        %in case ethere is no fluorescent image at that tp, just copy the
        %current radius over
        if ~sum(tpStack(:)) || max(tpStack(:))<flThresh
            
            %if there is a fluorescent image, do the following
        else
            for trapIndex=1:length(trapInfo)
                tpIm=tpStack(:,:,trapIndex);
                if trapInfo(trapIndex).cellsPresent && max(tpIm(:))>flThresh
                    im=double(tpIm);
                    im=im/max(im(:))*255;
                    image=im;
                    
                    % subpixel detection
                    threshold = max(max(gradient(image)*.1));
                    edges = subpixelEdges(image, threshold, 'SmoothingIter', 1);
                    
                    %
                    tp=timepoint;
                    %                     nK2=length(cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell);
                    image=image-min(image(:));
                    image=image/max(image(:))*255;
                    
                    bwStart=im2bw(image/255,graythresh(image/255)*1);
                    bwStart=imdilate(bwStart,se2);
                    D = bwdist(~bwStart);
                    D = -D;
                    D(~bwStart) = -Inf;
                    L = watershed(D);
                    
                    %                     [centers,~] = imfindcircles(image,[2 8]);
                    bwl=bwlabel(L>1);
                    bwNew=zeros(size(bwl));
                    for labelInd=1:max(bwl(:))
                        numP=sum(sum(bwl==labelInd));
                        if numP>9
                            bwNew(bwl==labelInd)=1;
                        end
                    end
                    bwl=bwlabel(bwNew);
                    distIm=bwdist(bwl>0);
                    distToCell=distIm(edges.position);
                    closeEnough=distToCell<2;
%                     e
%                     sIm=size(bwl);
%                     tY=floor(edges.y);tX=floor(edges.x);
%                     tSmall=tY<=0 | tX<=0;
%                     tY(tSmall)=[];tX(tSmall)=[];
%                     tSmall=tY>size(bwl,1) | tX>size(bwl,2);
%                     tY(tSmall)=[];tX(tSmall)=[];
% 
% %                     tY(tY<=0)=1;tX(tX==0)=1;
%                     edgesSub=sub2ind(sIm,tY,tX);
%                     edgesSub(edgesSub<1)=1;
%                     edgesSub(edgesSub>(size(bwl,1)*size(bwl,2)))=size(bwl,1)*size(bwl,2);
%                     edgesSub(isnan(edgesSub))=[];
%                     t=bwl(edgesSub);
%                     t(t==0)=[];
                    
                    fieldN=fieldnames(edges);
                    for fieldInd=1:length(fieldN)
                        edges.(fieldN{fieldInd})=edges.(fieldN{fieldInd})(closeEnough);
                    end

                    tIm=zeros(size(bwStart));
                    bwFinal=tIm;
                    tIm(edges.position)=1;
                    distIm=bwdist(tIm);closeEnoughEdge=[];
                    for labelInd=1:max(bwl(:))
                        distToEdge=min(min(distIm(bwl==labelInd)));
                        closeEnoughEdge(labelInd)=distToEdge<5;
                        bwFinal(bwl==labelInd)=closeEnoughEdge(labelInd);
                    end
                    bwlFinal=bwlabel(bwFinal);
                    nK=max(bwlFinal(:));

%                     sIm=size(bwl);
% %                     sIm(1)=sIm(1)+1;
%                     tY=floor(edges.y);tX=floor(edges.x);
%                     tSmall=tY<=0 | tX<=0;
%                     tY(tSmall)=[];tX(tSmall)=[];
%                     tSmall=tY>size(bwl,1) | tX>size(bwl,2);
%                     tY(tSmall)=[];tX(tSmall)=[];
% 
% %                     tY(tY<=0)=1;tX(tX==0)=1;
%                     edgesSub=sub2ind(sIm,tY,tX);
%                     edgesSub(edgesSub<1)=1;
%                     edgesSub(edgesSub>(size(bwl,1)*size(bwl,2)))=size(bwl,1)*size(bwl,2);
%                     edgesSub(isnan(edgesSub))=[];
%                     t=bwl(edgesSub);
%                     t(t==0)=[];
%                     uniqueLoc=unique(t);
%                     nK=length(uniqueLoc);
%                     props=regionprops(bwl);
                    
                    %error checking in case there are no edges within the
                    %range, so there are no clusters to make
                    locEdge=[edges.x edges.y];
                    if length(nK)>0 && nK>0 && length(locEdge)>2
                        %                     bwprops=regionprops(bwl,'basic');
                        %                     nK=max(bwl(:));
                        %                     nK=min([nK,nK2]);
                        %                     nK=length(centers);
                        
%                         propsCenters=[props(uniqueLoc).Centroid];
%                         propsCenters=reshape(propsCenters,2,length(propsCenters)/2)';
                        %                         [kInd kCent]=kmeans(locEdge,nK,'Start',propsCenters);
                        silh=[];
                        startK=max(nK-1,1);
                        kIndAll=[];kCentAll=[];
%                         for silInd=startK:nK+1
% %                             [kInd, kCent]=kmeans(locEdge,silInd,'Replicates',3,'Distance','sqEuclidean');
%                             [kInd, kCent]=kmedoids(locEdge,silInd,'Replicates',1);
% 
%                             temp= (silhouette(locEdge,kInd));
%                             silh(silInd) =mean(temp);
%                             kIndAll{silInd}=kInd;
%                             kCentAll{silInd}=kCent;
%                         end
%                         [v nK]=nanmax(silh);
% %                         nK=nK+startK-1;
%                         temp=silh(~isnan(silh));
%                         if length(temp)<2
%                             temp=[temp temp(end)];
%                         end
%                         temp=diff(temp);
%                         if v<.7 && nK==2 && max(abs(temp))<.07
%                             nK=1;
%                         end
%                         if nK==1
%                             [kInd kCent]=kmeans(locEdge,nK,'Replicates',5,'Distance','sqEuclidean');
%                         else
%                             kInd=kIndAll{nK};
%                             kCent=kCentAll{nK};
%                         end
                            
                        
                        [kInd kCent]=kmeans(locEdge,nK,'Replicates',5,'Distance','sqEuclidean','Start','sample');
%                         [kInd, kCent]=kmedoids(locEdge,nK,'Replicates',2);

%                         [kInd kCent]=kmeans(locEdge,nK,'Start',propsCenters);

                        edgesPerCell=[];
                        fieldN=fieldnames(edges);
                        for cellInd=1:max(kInd)
%                             distToCentK=pdist2(propsCenters(cellInd,:),locEdge(kInd==cellInd,:));
                            distToCentK=pdist2(kCent(cellInd,:),locEdge(kInd==cellInd,:));

                            edgePts=distToCentK<median(distToCentK(distToCentK<5))*1.3;
                            for fieldInd=1:length(fieldN)
                                temp=edges.(fieldN{fieldInd})(kInd==cellInd);
                                edgesPerCell(cellInd).(fieldN{fieldInd})=temp(edgePts);
                            end
                            edgesPerCell(cellInd).center=kCent(cellInd,:);
                        end
                        
                        %
                        % compare to center
                        cellMovementThresh=12;
                        pt1=[edgesPerCell(:).center];
                        if length(pt1)>2
                            pt1=reshape(pt1,2,length(pt1)/2)';
                        end
                        pt2=[cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(:).cellCenter];
                        if length(pt2)>2
                            pt2=reshape(pt2,2,length(pt2)/2)';
                        end
                        %pt1 = nuc
                        %pt2 = cells
                        pt1=double(pt1);
                        pt2=double(pt2);
                        dist=pdist2(pt1,pt2);
                        index=1;
                        cellNum=1:size(pt2,1);
                        actualCellNum=[];
                        actualCellDist=[];
                        for i=1:size(dist,2)
                            [val loc]=min(dist(:));
                            [row col]=ind2sub(size(dist),loc);
                            if val<cellMovementThresh
                                %cell number update
                                %                             temp_val=cellNum(col);
                                actualCellNum(row)=col;
                                actualCellDist(row)=val;
                                dist(:,col)=Inf;
                                dist(row,:)=Inf;
                                index=index+1;
                            end
                        end
                        %
                        
                        cellArea=[];imNew=[];
                        for cellInd=1:length(edgesPerCell)
                            
                            % error chechicking in case some cells don't have
                            % enough points for a radii/spline fitting
                            if length(edgesPerCell(cellInd).x)<6
                                cellArea(cellInd)=NaN;
                            else
                                cellCenter=edgesPerCell(cellInd).center;
                                X=edgesPerCell(cellInd).x-cellCenter(1);
                                Y=edgesPerCell(cellInd).y-cellCenter(2);
                                [angles,radii] = cart2pol(X,Y);
                                
                                image_size=size(im);
                                center=cellCenter;
                                angles(angles<0)=angles(angles<0)+2*pi;
                                
                                
                                pixel_diff = 0.05;
                                angle_diff = pixel_diff/max(radii);
                                steps = (0:angle_diff:(2*pi))';
                                
                                %order the angles vector (may not be necessary)
                                [~,indices_angles] = sort(abs(angles),1);
                                angles=angles(indices_angles);
                                radii = radii(indices_angles);
                                
                                
                                % to provide different break points for the spline fitting, and
                                % hopefully determin the radii more accurately
                                radii_full=[];
                                for incSpline=2:5
                                    r_spline = splinefit([angles; angles(1:floor(length(angles)/3))],[radii;radii(1:floor(length(radii)/3))],[0 ;angles(1:incSpline:end); 2*pi],.6,'p',4);%make the spline
                                    temp=ppval(r_spline,steps);
                                    radii_full(end+1,:) = temp;
                                end
                                radii_full=median(radii_full)';
                                %convert radial coords to x y coords
                                px = round(center(1)+radii_full.*cos(steps));%radial cords
                                py = round(center(2)+radii_full.*sin(steps));
                                
                                %check they are sensible
                                px(px<1) = 1;
                                px(px>image_size(2)) = image_size(2);
                                
                                py(py<1) = 1;
                                py(py>image_size(1)) = image_size(1);
                                
                                I = (diff(px)|diff(py));
                                px = px(I);
                                py = py(I);
                                
                                imNew(:,:,cellInd)=im;
                                newVal=max(im(:))*1.5;
                                for i=1:length(px)
                                    imNew(py(i),px(i),cellInd)=newVal;
                                end
%                                     figure;imshow(imNew,[]);
                                
                                X = (center(1)+radii_full.*cos(steps));%radial cords
                                Y = (center(2)+radii_full.*sin(steps));
                                cellArea(cellInd) = 1/2*abs(sum(X.*Y([2:end,1])-Y.*X([2:end,1])));
                            end
                        end
                        
                        for cellInd=1:length(cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell)
                            [cellLoc]=find(actualCellNum==cellInd);
                            %                             temp_val=actualCellNum(cellInd);
                            if ~isempty(cellLoc)
                                if cellArea(cellLoc)>100;
                                    t=1;
                                end
                                cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(cellInd).nucArea=cellArea(cellLoc);
                                
                                %compute how far the nucleus is from the
                                %cell center
                                pt1=edgesPerCell(cellLoc).center;
                                pt2=[cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(cellInd).cellCenter];
                                distToNuc=pdist2(double(pt1),double(pt2));
                                
                                if distToNuc>12
                                    t=1;
                                end
                                cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(cellInd).distToNuc=distToNuc;
                            else
                                cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(cellInd).nucArea=NaN;
                                cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(cellInd).distToNuc=NaN;
                                %     cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(temp_val).nucRadius=sqrt(cellArea(cellInd)/pi);
                            end
                        end
                    end
                end
            end
        end
    end
end
