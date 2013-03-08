function trackCells(cExperiment,positionsToTrack,cellMovementThresh)



if nargin<2
    positionsToTrack=find(cExperiment.posSegmented);
%     positionsToTrack=1:length(cExperiment.dirs);
end

if nargin<3
    cellMovementThresh=6;
end

%% Run the tracking on the timelapse
for i=1:length(positionsToTrack)
    experimentPos=positionsToTrack(i);
    load([cExperiment.rootFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    cTimelapse.trackCells;
    cExperiment.posTracked(experimentPos)=1;
    save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
    save([cExperiment.rootFolder '/' cExperiment.dirs{experimentPos},'cTimelapse'],'cTimelapse');
end



function testTrackingMethod(cTimelapse,cellMovementThresh)

for timepoint=1:length(cTimelapse.cTimepoint)
    disp(['Timepoint ' int2str(timepoint)]);
    trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
    if timepoint>1
        trapInfom1=cTimelapse.cTimepoint(timepoint-1).trapInfo;
    end
    if timepoint>2
        trapInfom2=cTimelapse.cTimepoint(timepoint-2).trapInfo;
    end
    for trap=1:length(cTimelapse.cTimepoint(1).trapInfo)
        if timepoint==1
            trapInfo(trap).cellLabel=1:length(trapInfo(trap).cell);
            trapMaxCell(trap)=length(trapInfo(trap).cell);
        else
             
            trapInfo(trap).cellLabel=zeros(1,length(trapInfo(trap).cell));
            circen=[trapInfo(trap).cell(:).cellCenter];
            circen=reshape(circen,2,length(circen)/2)';
            cirrad=[trapInfo(trap).cell(:).cellRadius]';
            pt2=[circen cirrad];
            
            circen=[trapInfom1(trap).cell(:).cellCenter];
            circen=reshape(circen,2,length(circen)/2)';
            cirrad=[trapInfom1(trap).cell(:).cellRadius]';
            pt1=[circen cirrad];
            
%             try
%                 pt1=[trapInfom1(trap).cellCenters trapInfom1(trap).cellRadius];
%             catch
%                 pt1=[trapInfom1(trap).cellCenters trapInfom1(trap).cellRadius'];
%             end
%             try
%                 pt2=[trapInfo(trap).cellCenters trapInfo(trap).cellRadius];
%             catch
%                 pt2=[trapInfo(trap).cellCenters trapInfo(trap).cellRadius'];
%             end
              
            if timepoint>2
                circen=[trapInfom2(trap).cell(:).cellCenter];
                circen=reshape(circen,2,length(circen)/2)';
                cirrad=[trapInfom2(trap).cell(:).cellRadius]';
                pt3=[circen cirrad];
%                 try
%                     pt3=[trapInfom2(trap).cellCenters trapInfom2(trap).cellRadius];
%                 catch
%                     pt3=[trapInfom2(trap).cellCenters trapInfom2(trap).cellRadius'];
%                 end
            else
                pt3=ones(1,3)*Inf;
            end
            pt1=double(pt1);pt2=double(pt2);pt3=double(pt3);
            if isempty(pt1)
                pt1=ones(1,3)*Inf;
            end
            if isempty(pt2) && timepoint>1
                pt2=ones(1,3)*Inf;
            end
            if isempty(pt3) && timepoint>2
                pt3=ones(1,3)*Inf;
            end
            aPointMatrix = repmat(pt2,size(pt1,1),1);
            dist = (sum(((aPointMatrix-pt1).^2), 2)).^0.5;
%             dist=pdist2(pt1,pt2,'euclidean');
            dist2=ones(size(dist))*Inf;
            index=1;
            if all(size(dist)>0);
                for i=1:size(dist,2)
                    [val loc]=min(dist(:));
                    [row col]=ind2sub(size(dist),loc);
                    
                    if val<cellMovementThresh
                        %cell number update
                        temp_val=trapInfom1(trap).cellLabel(row);
                        trapInfo(trap).cellLabel(1,col)=temp_val;
                        dist(:,col)=Inf;
                        dist(row,:)=Inf;
                        dist2(:,col)=Inf;
                        index=index+1;
                    elseif (min(dist2(:))==Inf) & timepoint>2
                        aPointMatrix = repmat(pt2,size(pt3,1),1);
                        dist2 = (sum(((aPointMatrix-pt3).^2), 2)).^0.5;
                        
%                         dist2=pdist2(pt3,pt2,'euclidean');
                    end
                    %below is to compare to timepoint-2 to see if a cell was
                    %just accidentally not foundd during one timepoint.
                    if min(dist2(:,col))<cellMovementThresh/2
                        [val2 loc2]=min(dist2(:,col));
                        dist2(:,col)=Inf;
                        %cell number update
                        temp_val=trapInfom2(trap).cellLabel(loc2);
                        trapInfo(trap).cellLabel(1,col)=temp_val;
                        index=index+1;
                    end
                end
            end
            
            %for all cells that are "new" cells to the image, update them
            %and the maxCell value
            unlabelledCellNum=length(trapInfo(trap).cell)-sum(trapInfo(trap).cellLabel>0);
            if unlabelledCellNum>0
                locsUnlabelled=find(trapInfo(trap).cellLabel==0);
                trapInfo(trap).cellLabel(locsUnlabelled(1:unlabelledCellNum))=trapMaxCell(trap)+1:trapMaxCell(trap)+unlabelledCellNum;
                trapMaxCell(trap)=trapMaxCell(trap)+unlabelledCellNum;
            end
        end
    end
    cTimelapse.cTimepoint(timepoint).trapInfo=trapInfo;
end