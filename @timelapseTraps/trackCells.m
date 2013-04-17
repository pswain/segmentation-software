function trackCells(cTimelapse,cellMovementThresh)

if nargin<2
    prompt = {'Max change in position and radius before a cell is classified as a new cell'};
    dlg_title = 'Tracking Threshold';
    num_lines = 1;
    def = {'8'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    cellMovementThresh=str2double(answer{1});
end



if isempty(cTimelapse.timepointsProcessed)
    tempSize=[cTimelapse.cTimepoint.trapInfo];
    cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(1).trapInfo));
end

for timepoint=1:length(cTimelapse.timepointsProcessed)
    if cTimelapse.timepointsProcessed(timepoint)
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
                
                %             if timepoint ==55 &&trap==15
                %                 b=1;
                %             end
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
                %             aPointMatrix = repmat(pt2,size(pt1,1),1);
                %             dist = (sum(((aPointMatrix-pt1).^2), 2)).^0.5;
                dist=pdist2(pt1,pt2,'euclidean');
                
                if timepoint>2
                    dist2=pdist2(pt3,pt2,'euclidean');
                else
                    dist2=ones(size(dist))*1e6;
                end
                index=1;
                noLabel=ones(1,size(dist,2));
                if all(size(dist)>0);
                    for i=1:size(dist,2)
                        [val loc]=min(dist(:));
                        [row col]=ind2sub(size(dist),loc);
                        
                        %                     if val==Inf
                        %                         col=find(trapInfo(trap).cellLabel==0);
                        %                         col=col(1);
                        %                     end
                        
                        
                        
                        if val<cellMovementThresh
                            %cell number update
                            temp_val=trapInfom1(trap).cellLabel(row);
                            trapInfo(trap).cellLabel(1,col)=temp_val;
                            dist(:,col)=Inf;
                            dist(row,:)=Inf;
                            dist2(:,col)=Inf;
                            noLabel(col)=0;
                            
                            if timepoint>2
                                locPrev=find(trapInfom2(trap).cellLabel==temp_val);
                                if ~isempty(locPrev)
                                    dist2(locPrev,:)=Inf;
                                end
                            end
                            
                            index=index+1;
                        end
                    end
                    
                    for i=1:sum(noLabel(:))
                        %below is to compare to timepoint-2 to see if a cell was
                        %just accidentally not foundd during one timepoint.
                        col=find(noLabel);
                        col=col(1);
                        noLabel(col)=0;
                        if min(dist2(:,col))<(cellMovementThresh*1)
                            [val2 loc2]=min(dist2(:,col));
                            [row2 col2]=ind2sub(size(dist2),loc2);
                            dist2(row2,:)=Inf;
                            dist2(:,col2)=Inf;
                            %cell number update
                            temp_val=trapInfom2(trap).cellLabel(row2);
                            trapInfo(trap).cellLabel(1,col)=temp_val;
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
end

cTimelapse.cTimepoint(1).trapMaxCell=trapMaxCell;
trap=1:length(cTimelapse.cTimepoint(1).trapInfo);
% for timepoint=1:length(cTimelapse.cTimepoint)
%     disp(['Timepoint ' int2str(timepoint)]);
%     alltraps=cTimelapse.returnTrapsTimepoint(trap,timepoint);
%
%     for j=1:size(alltraps,3)
%         image=alltraps(:,:,j);
%         image=double(image);
%
%         seg_areas=[cTimelapse.cTimepoint(timepoint).trapInfo(trap(j)).cell(:).segmented];
%         seg_areas=full(seg_areas);
%         seg_areas=reshape(seg_areas,[size(image,1) size(image,2) length(cTimelapse.cTimepoint(timepoint).trapInfo(trap(j)).cell)]);
% %         seg_areas=full(cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(cDisplay.traps(j)).trackLabel);
%
%         segLabel=zeros(size(seg_areas));
%         for k=1:size(seg_areas,3)
%             loc=double(cTimelapse.cTimepoint(timepoint).trapInfo(trap(j)).cell(k).cellCenter);
%             if ~isempty(loc)
%                 segLabel(:,:,k)=imfill(seg_areas(:,:,k),sub2ind(size(seg_areas(:,:,1)),loc(2),loc(1)));
%                 segLabel(:,:,k)=segLabel(:,:,k)*cTimelapse.cTimepoint(timepoint).trapInfo(trap(j)).cellLabel(k);
%             end
%         end
%         segLabel=max(segLabel,[],3);
%         cTimelapse.cTimepoint(timepoint).trapInfo(j).trackLabel=sparse((segLabel));
%     end
% end
