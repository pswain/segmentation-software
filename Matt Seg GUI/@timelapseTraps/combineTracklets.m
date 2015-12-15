function combineTracklets(cTimelapse,params)
% combineTracklets(cTimelapse,params)
%--------------------------------------------------------------------------
% This combines the individual single tracklets into larger/longer tracks.
% This relies on the tracklets being rather stringently tracked. It will
% loop through until no additional tracklets have been removed in a single
% run.
%
% default params structure:
%     params.fraction=.1; %fraction of timelapse length that cells must be present or
%     params.duration=3; %number of frames cells must be present
%     params.framesToCheck=length(cTimelapse.timepointsProcessed);
%     params.framesToCheckEnd=1;
%     params.endThresh=3; %num tp after end of tracklet to look for cells
%     params.sameThresh=3; %num tp to use to see if cells are the same
%     params.classThresh=3; %classification threshold
%   
% uses 

if nargin<2
    params.fraction=.1; %fraction of timelapse length that cells must be present or
    params.duration=3; %number of frames cells must be present
    params.framesToCheck=length(cTimelapse.timepointsProcessed);
    params.framesToCheckEnd=1;
    params.endThresh=3; %num tp after end of tracklet to look for cells
    params.sameThresh=3; %num tp to use to see if cells are the same
    params.classThresh=3; %classification threshold
    
    num_lines=1;clear prompt; clear def;
    prompt(1) = {'Fraction of whole timelapse a cell must be present'};
    prompt(2) = {'OR - number of frames a cell must be present'};
    prompt(3) = {'Cell must appear in the first X frames'};
    prompt(4) = {'Cell must be present after frame X'};
    prompt(5) = {'New tracklet must appear within X frames'};
    prompt(6) = {'Number of tracklet frames to compare'};
    prompt(7) = {'Tracklet classification threshold'};
    dlg_title = 'Tracklet params';    
    def(1) = {num2str(params.fraction)};def(2) = {num2str(params.duration)};
    def(3) = {num2str(params.framesToCheck)};def(4) = {num2str(params.framesToCheckEnd)};
    def(5) = {num2str(params.endThresh)};
    def(6) = {num2str(params.sameThresh)};
    def(7) = {num2str(params.classThresh)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    params.fraction=str2double(answer{1});
    params.duration=str2double(answer{2});
    params.framesToCheck=str2double(answer{3});
    params.framesToCheckEnd=str2double(answer{4});
    params.endThresh=str2double(answer{5});
    params.sameThresh=str2double(answer{6});
    params.clasThresh=str2double(answer{7});

end


notdone=true;

while notdone
    
    cTimelapse.automaticSelectCells(params);
    cTimelapse.extractCellParamsOnly;
    cTimelapse.correctSkippedFramesInf;
        
    duration=sum(cTimelapse.extractedData(1).radius>0,2);
    sameTracklets=[];
%     durThresh=max(median(duration)*.5,params.duration);
    durThresh=params.duration;
    for trap=1:max(cTimelapse.extractedData(1).trapNum)
        
        cellsToLookAt=find(duration>durThresh & cTimelapse.extractedData(1).trapNum==trap);
        
        tempRad=cTimelapse.extractedData(1).radius;
        for i=length(cellsToLookAt):-1:1
            
            cellsCurTrap=cTimelapse.extractedData(1).trapNum==trap;
            currCellNum=cTimelapse.extractedData(1).cellNum(cellsCurTrap);
            currCell.radius=cTimelapse.extractedData(1).radius(cellsToLookAt(i),:);
            currCell.xloc=cTimelapse.extractedData(1).xloc(cellsToLookAt(i),:);
            currCell.yloc=cTimelapse.extractedData(1).yloc(cellsToLookAt(i),:);
            currCell.cellNum=cTimelapse.extractedData(1).cellNum(cellsToLookAt(i));
            
            tempPres=tempRad(cellsToLookAt(i),:)>0;
            
            cellsNotPresent=sum(tempRad(cellsCurTrap,tempPres),2)==0;
            
            currEnd=max(find(tempPres));
            tpCheck=currEnd+1:min(currEnd+params.endThresh,size(tempRad,2));
            
            if ~isempty(tpCheck)
                
                cellsStartNearEnd=max(tempRad(cellsCurTrap,tpCheck),[],2)>0;
                
                potentialCells=find(cellsStartNearEnd & cellsNotPresent);
                if ~isempty(potentialCells)
                    xLoc=cTimelapse.extractedData(1).xloc(cellsCurTrap,:);
                    yLoc=cTimelapse.extractedData(1).yloc(cellsCurTrap,:);
                    radius=cTimelapse.extractedData(1).radius(cellsCurTrap,:);
                    
                    tpSame=currEnd+1:min(currEnd+params.sameThresh,size(tempRad,2));
                    tempX=[];tempY=[];tempR=[];
                    for l=1:size(potentialCells,1)
                        temp=xLoc(potentialCells(l),tpSame);
                        tempX(l)=mean(temp(temp>0),2);
                        temp=yLoc(potentialCells(l),tpSame);
                        tempY(l)=mean(temp(temp>0),2);
                        temp=radius(potentialCells(l),tpSame);
                        tempR(l)=mean(temp(temp>0),2);
                    end
                    xLoc=tempX';yLoc=tempY';radius=tempR';
                    tpSameCurr=max(currEnd-params.sameThresh,1):currEnd;
                    currCell.medRadius=mean(currCell.radius(tpSameCurr));
                    currCell.medXLoc=mean(currCell.xloc(tpSameCurr));
                    currCell.medYLoc=mean(currCell.yloc(tpSameCurr));
                    
                    pt1=[xLoc yLoc radius];
                    pt2=[currCell.medXLoc currCell.medYLoc currCell.medRadius];
                    
                    %             sameDistance=sqrt(sum((pt1-pt2).^2));
                    sameDistance=alternativeDist(pt1, pt2);
                    if min(sameDistance)<params.classThresh
                        [v, loc]=min(sameDistance);
                        cellLoc=find((cTimelapse.extractedData(1).trapNum==trap)& cTimelapse.extractedData(1).cellNum==potentialCells(loc));
                        
                        sameTracklets(cTimelapse.extractedData(1).cellNum(cellsToLookAt(i)),currCellNum(potentialCells(loc)),trap)=1;
                        % need to go through and relabel all the cells based on
                        % this new information
                        
                        %                 pause(2)
                    end
                end
            end
        end
    end
    
    
    %                 cTrapDisplay(cTimelapse,[],[],[],trap)
    
    notdone=false;
    cTimepoint=cTimelapse.cTimepoint;
    for trap=1:size(sameTracklets,3)
        fprintf(['Trap number ' num2str(trap) '\n']);
        [r c]=find(sameTracklets(:,:,trap));
        if ~isempty(r)
            for cell=1:length(r)
                for tp=1:length(cTimelapse.timepointsProcessed)
                    if cTimelapse.timepointsProcessed(tp)
                        cellLabel=cTimepoint(tp).trapInfo(trap).cellLabel;
                        loc=find(cellLabel==c(cell));
                        if ~isempty(loc)
                            cellLabel(loc)=r(cell);
                            cTimelapse.cTimepoint(tp).trapInfo(trap).cellLabel=cellLabel;
                            notdone=true;
                        end
                    end
                end
            end
        end
    end
    
    if ~notdone
        break;
    end
    
end
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
    if find(temp<0)
        loc=temp<0;
        %         temp(loc)=temp(loc).^2;
        temp(loc)=temp(loc).^2;
        
    end
    dist(:,:,3)=temp;
    
    distance=sqrt(sum(dist.^2,3));
else
    distance=[];
end
end