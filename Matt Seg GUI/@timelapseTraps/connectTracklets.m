% function connectTracklets(cTimelapse,params)
% % THis creates the individual tracklets using the trackcells function.
% 
% 
% if isempty(cTimelapse.timepointsProcessed)
%     tempSize=[cTimelapse.cTimepoint.trapInfo];
%     cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(1).trapInfo));
% end
% 
% if nargin<2
%     prompt = {'Max change in position and radius before a cell is classified as a new cell'};
%     dlg_title = 'Tracking Threshold';
%     num_lines = 1;
%     def = {'5'};
%     answer = inputdlg(prompt,dlg_title,num_lines,def);
%     cellMovementThresh=str2double(answer{1});
%     
%     
%     params.fraction=.1; %fraction of timelapse length that cells must be present or
%     params.duration=3; %number of frames cells must be present
%     params.framesToCheck=length(cTimelapse.timepointsProcessed);
%     params.framesToCheckEnd=1;
% end
% 
% 
% 
% notdone=true;
% while notdone
%     cTimelapse.automaticSelectCells(params);
%     cTimelapse.extractCellParamsOnly;
%     cTimelapse.correctSkippedFramesInf;    
%     
%     
%     duration=sum(cTimelapse.extractedData(1).radius>0,2);
%     sameCell=[];
%     sameTracklets=[];
%     for trap=1:max(cTimelapse.extractedData(1).trapNum)
%         
%         cellsToLookAt=find(duration>median(duration)*2 & cTimelapse.extractedData(1).trapNum==trap);
%         
%         tempRad=cTimelapse.extractedData(1).radius;
%         endThresh=4; %num tp after end of tracklet to look for cells
%         sameThresh=4; 
%         classThresh=4; %classification threshold
%         for i=1:length(cellsToLookAt)
%             
%             cellsCurTrap=cTimelapse.extractedData(1).trapNum==trap;
%             currCellNum=cTimelapse.extractedData(1).cellNum(cellsCurTrap);
%             currCell.radius=cTimelapse.extractedData(1).radius(cellsToLookAt(i),:);
%             currCell.xloc=cTimelapse.extractedData(1).xloc(cellsToLookAt(i),:);
%             currCell.yloc=cTimelapse.extractedData(1).yloc(cellsToLookAt(i),:);
%             currCell.cellNum=cTimelapse.extractedData(1).cellNum(cellsToLookAt(i));
%             
%             tempPres=tempRad(cellsToLookAt(i),:)>0;
%             
%             cellsNotPresent=sum(tempRad(cellsCurTrap,tempPres),2)==0;
%             
%             currEnd=max(find(tempPres));
%             tpCheck=currEnd+1:min(currEnd+endThresh,size(tempRad,2));
%             
%             if ~isempty(tpCheck)
%                 
%                 cellsStartNearEnd=max(tempRad(cellsCurTrap,tpCheck),[],2)>0;
%                 
%                 potentialCells=find(cellsStartNearEnd & cellsNotPresent);
%                 if ~isempty(potentialCells)
%                     xLoc=cTimelapse.extractedData(1).xloc(cellsCurTrap,:);
%                     yLoc=cTimelapse.extractedData(1).yloc(cellsCurTrap,:);
%                     radius=cTimelapse.extractedData(1).radius(cellsCurTrap,:);
%                     
%                     tpSame=currEnd+1:min(currEnd+sameThresh,size(tempRad,2));
%                     xLoc=median(xLoc(potentialCells,tpSame),2);
%                     yLoc=median(yLoc(potentialCells,tpSame),2);
%                     radius=median(radius(potentialCells,tpSame),2);
%                     
%                     tpSameCurr=max(currEnd-sameThresh,1):currEnd;
%                     currCell.medRadius=median(currCell.radius(tpSameCurr));
%                     currCell.medXLoc=median(currCell.xloc(tpSameCurr));
%                     currCell.medYLoc=median(currCell.yloc(tpSameCurr));
%                     
%                     pt1=[xLoc yLoc radius];
%                     pt2=[currCell.medXLoc currCell.medYLoc currCell.medRadius];
%                     
%                     %             sameDistance=sqrt(sum((pt1-pt2).^2));
%                     sameDistance=alternativeDist(pt2, pt1);
%                     if min(sameDistance)<classThresh
%                         [v loc]=min(sameDistance);
%                         cellLoc=find((cTimelapse.extractedData(1).trapNum==trap)& cTimelapse.extractedData(1).cellNum==potentialCells(loc));
%                         sameCell(cellsToLookAt(i),cellLoc)=1;
%                         
%                         sameTracklets(cTimelapse.extractedData(1).cellNum(cellsToLookAt(i)),currCellNum(potentialCells(loc)),trap)=1;
%                         % need to go through and relabel all the cells based on
%                         % this new information
%                         
%                         %                 pause(2)
%                     end
%                 end
%             end
%         end
%     end
%     
%     sameCell=sparse(sameCell);
%     
%     %                 cTrapDisplay(cTimelapse,[],[],[],trap)
%     
%     notdone=false;
%     for trap=1:size(sameTracklets,3)
%         [r c]=find(sameTracklets(:,:,trap));
%         if ~isempty(r)
%             for cell=1:length(r)
%                 for tp=1:length(cTimelapse.cTimepoint)
%                     cellLabel=cTimelapse.cTimepoint(tp).trapInfo(trap).cellLabel;
%                     loc=find(cellLabel==c(cell));
%                     if ~isempty(loc)
%                         cellLabel(loc)=r(cell);
%                         cTimelapse.cTimepoint(tp).trapInfo(trap).cellLabel=cellLabel;
%                         notdone=true;
%                     end
%                 end
%             end
%         end
%     end
%     
% end