function trackCells(cTimelapse,cellMovementThresh)

if nargin<2
    prompt = {'Max change in position and radius before a cell is classified as a new cell'};
    dlg_title = 'Tracking Threshold';
    num_lines = 1;
    def = {'8'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    cellMovementThresh=str2double(answer{1});
end

%%
%Identify the mother index ... cells that are closest to the center of the
%trap and most likely to be the cells of interest. The tracking will be
%more lenient on these cells.
motherIndex=cTimelapse.findMotherIndex;

%%
if isempty(cTimelapse.timepointsProcessed)
    tempSize=[cTimelapse.cTimepoint.trapInfo];
    cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(1).trapInfo));
end

for timepoint=1:length(cTimelapse.timepointsProcessed)
    if cTimelapse.timepointsProcessed(timepoint)
        disp(['Timepoint ' int2str(timepoint)]);
        
        if timepoint>2
            trapInfom2=trapInfom1;
        end
       if timepoint>1
            trapInfom1=trapInfo;
        end
        trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
        
%         trapMaxCell=zeros(1,length(cTimelapse.cTimepoint(1).trapInfo));
        for trap=1:length(cTimelapse.cTimepoint(1).trapInfo)
            if timepoint==1
                if trapInfo(trap).cellsPresent
                    len=length(trapInfo(trap).cell);
                    trapInfo(trap).cellLabel=1:length(trapInfo(trap).cell);
                else
                    len=0;
                    trapInfo(trap).cellLabel=0;
                end
                trapMaxCell(trap)=len;            
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
                
                if timepoint>2
                    circen=[trapInfom2(trap).cell(:).cellCenter];
                    circen=reshape(circen,2,length(circen)/2)';
                    cirrad=[trapInfom2(trap).cell(:).cellRadius]';
                    pt3=[circen cirrad];
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
%                 dist=pdist2(pt1,pt2,'euclidean');
                dist=alternativeDist(pt1,pt2);
                
                if timepoint>2
                    dist2=alternativeDist(pt3,pt2);
                else
                    dist2=ones(size(dist))*1e6;
                end
                index=1;
                noLabel=ones(1,size(dist,2));
                if all(size(dist)>0);
                    for i=1:size(dist,2)
                        [val loc]=min(dist(:));
                        [row col]=ind2sub(size(dist),loc);
                        
%                         if trap==18 && timepoint==42
%                             b=1;
%                         end
                        
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
                        if min(dist2(:,col))<(cellMovementThresh*.8) %reduce thresh slightly for timepoints back in time
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
                
                % Use the motherIndex for to identify mothers that should
                % have been tracked but weren't
                if motherIndex(trap,timepoint-1) && motherIndex(trap,timepoint)
                    if ~trapInfo(trap).cellLabel(motherIndex(trap,timepoint))
                        newLabel=trapInfom1(trap).cellLabel(motherIndex(trap,timepoint-1));
                        if ~any(trapInfo(trap).cellLabel==newLabel)
                            trapInfo(trap).cellLabel(motherIndex(trap,timepoint))=newLabel;
                        end
                    end
                elseif timepoint>2 && motherIndex(trap,timepoint-2) && motherIndex(trap,timepoint)
                    newLabel=trapInfom2(trap).cellLabel(motherIndex(trap,timepoint-2));
                    if ~any(trapInfo(trap).cellLabel==newLabel)
                        trapInfo(trap).cellLabel(motherIndex(trap,timepoint))=newLabel;
                    end
                end
                
%                 if timepoint>2
%                     if motherIndex(trap,timepoint-2) && motherIndex(trap,timepoint) && ~motherIndex(trap,timepoint-1)
%                         if ~trapInfo(trap).cellLabel(motherIndex(trap,timepoint))
%                             newLabel=trapInfom2(trap).cellLabel(motherIndex(trap,timepoint-2));
%                             if ~any(trapInfo(trap).cellLabel==newLabel)
%                                 trapInfo(trap).cellLabel(motherIndex(trap,timepoint))=newLabel;
%                             end
%                         end
%                     end
%                 end

                
%                 for all cells that are "new" cells to the image, update them
%                 and the maxCell value
                if ~trapInfo(trap).cellsPresent
                    unlabelledCellNum=0;
                elseif trapInfo(trap).cellsPresent && isempty(trapInfo(trap).cell(1).cellCenter)
                    unlabelledCellNum=0;
                    trapInfo(trap).cellsPresent=0;
                else
                    unlabelledCellNum=length(trapInfo(trap).cell)-sum(trapInfo(trap).cellLabel>0);
                end
 
                
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
end

function distance= alternativeDist(pt1,pt2)
if ~isempty(pt1) && ~isempty(pt2)
    dist=[];
    for i=1:size(pt1,2)
        b=pt2(:,i);
        a=pt1(:,i);
        b=b';
        anew= repmat(a,1,size(b,2));
        bnew= repmat(b,size(a,1),1);
        temp=(((bnew-anew)));
        dist(:,:,i) = temp;
    end
    temp=dist(:,:,3);
    temp2=dist(:,:,3);
    if find(temp<0)
        %If cell shrinks, then penalize a lot
        loc=temp<0;
        tempFracShrink=(bnew-anew)./bnew;
        tempFracShrink=(tempFracShrink)*10;

%         temp(loc)=temp(loc).^2;
%         temp(loc)=(temp(loc).^2)*1.5;
        temp(loc)=(tempFracShrink(loc).^2)*1.5;

    end
    if find(temp2>0)
        %if a cell grow a lot, penalize it
        tempFracGrow=(bnew-anew)./bnew;
        tempFracGrow=(tempFracGrow)*10;

        loc=temp2>0;
%         temp(loc)=temp(loc).^1.5;
        
        temp(loc)=tempFracGrow(loc).^1.1;

    end
    dist(:,:,3)=temp;
    
    distance=sqrt(sum(dist.^2,3));
else
    distance=[];
end
end