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
    load([cExperiment.rootFolder '/' cExperiment.dirs{experimentPos}]);
    testTrackingMethod(cTimelapse,cellMovementThresh)
    cExperiment.posTracked(experimentPos)=1;
    save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
    save([cExperiment.rootFolder '/' cExperiment.dirs{experimentPos}],'cTimelapse');
end



function testTrackingMethod(cTimelapse,cellMovementThresh)

for timepoint=1:length(cTimelapse.cTimepoint)
    disp(['Timepoint ' int2str(timepoint)]);
    for trap=1:length(cTimelapse.cTimepoint(1).trapInfo)
        if timepoint==1
            cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel=1:length(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell);
            trapMaxCell(trap)=length(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell);
        else
             
            cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel=zeros(1,length(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell));
            circen=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellCenter];
            circen=reshape(circen,2,length(circen)/2)';
            cirrad=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellRadius]';
            pt2=[circen cirrad];
            
            circen=[cTimelapse.cTimepoint(timepoint-1).trapInfo(trap).cell(:).cellCenter];
            circen=reshape(circen,2,length(circen)/2)';
            cirrad=[cTimelapse.cTimepoint(timepoint-1).trapInfo(trap).cell(:).cellRadius]';
            pt1=[circen cirrad];
            
%             try
%                 pt1=[cTimelapse.cTimepoint(timepoint-1).trapInfo(trap).cellCenters cTimelapse.cTimepoint(timepoint-1).trapInfo(trap).cellRadius];
%             catch
%                 pt1=[cTimelapse.cTimepoint(timepoint-1).trapInfo(trap).cellCenters cTimelapse.cTimepoint(timepoint-1).trapInfo(trap).cellRadius'];
%             end
%             try
%                 pt2=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellCenters cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellRadius];
%             catch
%                 pt2=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellCenters cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellRadius'];
%             end
              
            if timepoint>2
                circen=[cTimelapse.cTimepoint(timepoint-2).trapInfo(trap).cell(:).cellCenter];
                circen=reshape(circen,2,length(circen)/2)';
                cirrad=[cTimelapse.cTimepoint(timepoint-2).trapInfo(trap).cell(:).cellRadius]';
                pt3=[circen cirrad];
%                 try
%                     pt3=[cTimelapse.cTimepoint(timepoint-2).trapInfo(trap).cellCenters cTimelapse.cTimepoint(timepoint-2).trapInfo(trap).cellRadius];
%                 catch
%                     pt3=[cTimelapse.cTimepoint(timepoint-2).trapInfo(trap).cellCenters cTimelapse.cTimepoint(timepoint-2).trapInfo(trap).cellRadius'];
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
            dist=pdist2(pt1,pt2,'euclidean');
            dist2=ones(size(dist))*Inf;
            index=1;
            if all(size(dist)>0);
                for i=1:size(dist,2)
                    [val loc]=min(dist(:));
                    [row col]=ind2sub(size(dist),loc);
                    
                    if val<cellMovementThresh
                        %cell number update
                        temp_val=cTimelapse.cTimepoint(timepoint-1).trapInfo(trap).cellLabel(row);
                        cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel(1,col)=temp_val;
                        dist(:,col)=Inf;
                        dist(row,:)=Inf;
                        dist2(:,col)=Inf;
                        index=index+1;
                    elseif (min(dist2(:))==Inf) & timepoint>2
                        dist2=pdist2(pt3,pt2,'euclidean');
                    end
                    %below is to compare to timepoint-2 to see if a cell was
                    %just accidentally not foundd during one timepoint.
                    if min(dist2(:,col))<cellMovementThresh/2
                        [val2 loc2]=min(dist2(:,col));
                        dist2(:,col)=Inf;
                        %cell number update
                        temp_val=cTimelapse.cTimepoint(timepoint-2).trapInfo(trap).cellLabel(loc2);
                        cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel(1,col)=temp_val;
                        index=index+1;
                    end
                end
            end
            
            %for all cells that are "new" cells to the image, update them
            %and the maxCell value
            unlabelledCellNum=length(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell)-sum(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel>0);
            if unlabelledCellNum>0
                locsUnlabelled=find(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel==0);
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel(locsUnlabelled(1:unlabelledCellNum))=trapMaxCell(trap)+1:trapMaxCell(trap)+unlabelledCellNum;
                trapMaxCell(trap)=trapMaxCell(trap)+unlabelledCellNum;
            end
        end
    end
end