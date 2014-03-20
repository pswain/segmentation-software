function extractLineageInfo(cTimelapse,params)

%% identifies the mother cell that is present for the longest time
%motherDistCutoff is the number of motherRadiuses that the daughter can be
%from the mother and still be considered a daughter.

cTimelapse.correctSkippedFramesInf;

if nargin<2
    params.motherDurCutoff=(.7);
    params.motherDistCutoff=2.6;
    params.budDownThresh=.25;
    params.birthRadiusThresh=7;

end

%this is the fraction of buds that must be down (btween the trap outlet)
%for the cell to be classified as downward budding and used.

motherDurCutoff=length(cTimelapse.timepointsProcessed)*params.motherDurCutoff;
motherDistCutoff=params.motherDistCutoff;
budDownThresh=params.budDownThresh;



%the trackCells function must be run prior to this

histLabels=zeros(length(cTimelapse.cTimepoint(1).trapInfo),1e5);

for timepoint=1:length(cTimelapse.timepointsProcessed)
    if cTimelapse.timepointsProcessed(timepoint)
        trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
        for trap=1:length(cTimelapse.cTimepoint(1).trapInfo)
            if trapInfo(trap).cellsPresent
                %                 histLabels(trap,trapInfo(trap).cellLabel)=histLabels(trap,trapInfo(trap).cellLabel)+ones(1,length(trapInfo(trap).cellLabel));
                t=cTimelapse.lineageInfo.motherIndex(trap,timepoint);
                if t
                    histLabels(trap,trapInfo(trap).cellLabel(t))=histLabels(trap,trapInfo(trap).cellLabel(t))+1;
                end
            end
        end
    end
end
%
[motherDuration motherLabel]=sort(histLabels,2,'descend');

% b(b<max(b(:))/4)=0;
% motherLabel(b==0)=0;
% m=max(b)>0;
% b(:,~m)=[];
% motherLabel(:,~m)=[];
cTimelapse.lineageInfo.motherLabel=motherLabel(:,1:2);



% The below extracts the information regarding births and coallates
cTimelapse.lineageInfo.motherInfo.birthTime=[];
cTimelapse.lineageInfo.motherInfo.birthRadius=[];
cTimelapse.lineageInfo.motherInfo.daughterLabel=[];
cTimelapse.lineageInfo.motherInfo.daughterTrapNum=[];
cTimelapse.lineageInfo.motherInfo.daughterXLoc=[];
cTimelapse.lineageInfo.motherInfo.daughterYLoc=[];
cTimelapse.lineageInfo.motherInfo.minMothDist=[];
cTimelapse.lineageInfo.motherInfo.motherStartEnd=[];
cTimelapse.lineageInfo.motherInfo.daughterDuration=[];

for trap=1:length(cTimelapse.cTimepoint(1).trapInfo)
    for mCell=1:2
        if motherDuration(trap,mCell)<motherDurCutoff
            break;
        end
        mother=cTimelapse.lineageInfo.motherLabel(trap,mCell);
        
        trapL=find(cTimelapse.extractedData(1).trapNum==trap);
        
        motherLoc=find(cTimelapse.extractedData(1).trapNum==trap & cTimelapse.extractedData(1).cellNum==mother);
        tpCheck=cTimelapse.extractedData(1).xloc(motherLoc,:)>0;
        if length(trapL)<2 || ~all(size(tpCheck)) || sum(tpCheck)==0
            break;
        end
        
        trapLDaughters=find(cTimelapse.extractedData(1).trapNum==trap & ~(cTimelapse.extractedData(1).cellNum==mother) );
        
        xlocDaughters=full(cTimelapse.extractedData(1).xloc(trapLDaughters,tpCheck));
        ylocDaughters=full(cTimelapse.extractedData(1).yloc(trapLDaughters,tpCheck));
        if isempty(xlocDaughters)
            xlocDaughters=zeros(size(tpCheck));
            ylocDaughters=zeros(size(tpCheck));
        end
        xlocDaughters(xlocDaughters==0)=NaN;
        ylocDaughters(ylocDaughters==0)=NaN;
        
        motherRadius=full(cTimelapse.extractedData(1).radius(motherLoc,tpCheck));
        motherRadius=smooth(motherRadius,length(motherRadius)/2,'lowess')';
        motherXLoc=full(cTimelapse.extractedData(1).xloc(motherLoc,tpCheck));
        motherYLoc=full(cTimelapse.extractedData(1).xloc(motherLoc,tpCheck));
        
        xDistToMother=xlocDaughters-repmat(motherXLoc,size(xlocDaughters,1),1);
        yDistToMother=ylocDaughters-repmat(motherYLoc,size(ylocDaughters,1),1);
        
        distToMother=sqrt(xDistToMother.^2 + yDistToMother.^2);
        daughtersCloseToMother=distToMother < repmat(3+motherDistCutoff*motherRadius,size(distToMother,1),1);
        actualDaughters=max(daughtersCloseToMother,[],2);
        
        %below finds the first location that the daughter cells appear
        b=xlocDaughters;
        diffB=padarray(b,[0 1],NaN,'pre');
        b1=~isnan(diffB(:,2:end));
        b2=isnan(diffB(:,1:end-1));
        firstDaughterPos=b1&b2;
        if any(sum(firstDaughterPos,2)>1)
            for r=1:size(firstDaughterPos,1)
                b=find(firstDaughterPos(r,:));
                if ~isempty(b)
                    firstDaughterPos(r,:)=0;
                    firstDaughterPos(r,b(1))=1;
                end
            end
        end
        actualDaughterPos=firstDaughterPos & repmat(actualDaughters,1,size(firstDaughterPos,2));
        
        daughterXLoc=zeros(size(actualDaughters));
        daughterYLoc=zeros(size(actualDaughters));
        daughterXLoc(actualDaughters)=xlocDaughters(actualDaughterPos);
        daughterYLoc(actualDaughters)=ylocDaughters(actualDaughterPos);
        
        
        %         daughterXLoc=nanmin(xlocDaughters(actualDaughters,:),[],2);
        %         daughterYLoc=nanmin(ylocDaughters(actualDaughters,:),[],2);
        
        %see if the cell is budding down (through the trap), and if it is
        %keep on going, if not, don't extract lineage info from this Mother
        tempLoc=daughterXLoc;
        temp=tempLoc>median(motherXLoc);
        temp=double(temp);
        temp(tempLoc==0)=NaN;
        budDown= nanmean(temp);
       
        budDown=budDown>budDownThresh;
        
        if ~budDown
            break;
        end
        
        %then remove any cells that are on top of the mother since we know
        %it is budding out of the bottom.
        temp=daughterXLoc(actualDaughters)>median(motherXLoc);
        b=zeros(size(actualDaughters));
        b(actualDaughters)=temp;
        actualDaughters=b>0;
        actualDaughterPos=firstDaughterPos & repmat(actualDaughters,1,size(firstDaughterPos,2));
        daughterXLoc=xlocDaughters(actualDaughterPos);
        daughterYLoc=ylocDaughters(actualDaughterPos);


        
        daughterRad=full(cTimelapse.extractedData(1).radius(trapLDaughters,:));
        daughterRad(daughterRad==0)=NaN;
        daughterMinRad=nanmin(daughterRad,[],2);
        selmat=repmat(1:size(xlocDaughters,2),sum(actualDaughters),1);
        t=(actualDaughterPos(actualDaughters,:)).*selmat;
        t(t==0)=NaN;
        birthTimes=nanmin(t,[],2);
        
        %these birthTimes are relative to when the mother appears. Find the
        %actual times and change the birthTimes to be in absolute times not
        %relative to the start of the mother
        actualTimes=find(tpCheck);
        birthTimes=actualTimes(birthTimes);
        
        %fidn the min distance of the daugther when born
        %         minMothDist=nanmin(distToMother(actualDaughters,:),[],2);
        minMothDist=distToMother(actualDaughterPos(actualDaughters,:));
        
        daughterDuration=sum(xlocDaughters(actualDaughters,:)>0,2);

        
        %need to make sure only the daughters within the distance cutoff are
        %selected
        daughterMinRad=daughterMinRad(actualDaughters);
        daughterLabel=cTimelapse.extractedData(1).cellNum(trapLDaughters,:);
        daughterLabel=daughterLabel(actualDaughters);
        daughterTrapNum=cTimelapse.extractedData(1).trapNum(trapLDaughters,:);
        daughterTrapNum=daughterTrapNum(actualDaughters);
        t=find(tpCheck);
        motherStart=t(1);
        motherEnd=t(end);
        
        cTimelapse.lineageInfo.motherInfo.daughterXLoc(end+1,1:length(daughterXLoc))=daughterXLoc;
        cTimelapse.lineageInfo.motherInfo.daughterYLoc(end+1,1:length(daughterYLoc))=daughterYLoc;
        cTimelapse.lineageInfo.motherInfo.minMothDist(end+1,1:length(minMothDist))=minMothDist;
        cTimelapse.lineageInfo.motherInfo.daughterDuration(end+1,1:length(daughterDuration))=daughterDuration;


        cTimelapse.lineageInfo.motherInfo.birthTime(end+1,1:length(birthTimes))=birthTimes;
        cTimelapse.lineageInfo.motherInfo.birthRadius(end+1,1:length(daughterMinRad))=daughterMinRad;
        cTimelapse.lineageInfo.motherInfo.daughterLabel(end+1,1:length(daughterLabel))=daughterLabel;
        cTimelapse.lineageInfo.motherInfo.daughterTrapNum(end+1,1:length(daughterTrapNum))=daughterTrapNum(:,1);
        cTimelapse.lineageInfo.motherInfo.motherStartEnd(end+1,1:2)=[motherStart motherEnd];
    end
end