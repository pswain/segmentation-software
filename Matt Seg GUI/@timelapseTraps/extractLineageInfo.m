function extractLineageInfo(cTimelapse,params)

%% identifies the mother cell that is present for the longest time
%motherDistCutoff is the number of motherRadiuses that the daughter can be
%from the mother and still be considered a daughter.

cTimelapse.correctSkippedFramesInf;

if nargin<2
    params.motherDurCutoff=(.6);
    params.motherDistCutoff=2.1;
    params.budDownThresh=0;
    params.birthRadiusThresh=8;
    params.daughterGRateThresh=-1;
    
    
    num_lines=1;clear prompt; clear def;
    prompt(1) = {'Fraction of timelapse a mother must be present'};
    prompt(2) = {'Multiple of daugther radius a daughter can be from the mother (plus mother Radius)'};
    prompt(3) = {'Fraction of daughters that must be budded through the trap to be considered'};
    prompt(4) = {'Daughter birth radius cutoff thresh (less than)'};
        prompt(5) = {'Daughter growth rate (in radius pixels)'};

    
    dlg_title = 'Tracklet params';
    def(1) = {num2str(params.motherDurCutoff)};def(2) = {num2str(params.motherDistCutoff)};
    def(3) = {num2str(params.budDownThresh)};
    def(4) = {num2str(params.birthRadiusThresh)};
    def(5) = {num2str(params.daughterGRateThresh)};
    
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    params.motherDurCutoff=str2double(answer{1});
    params.motherDistCutoff=str2double(answer{2});
    params.budDownThresh=str2double(answer{3});
    params.birthRadiusThresh=str2double(answer{4});
    params.daughterGRateThresh=str2double(answer{5});
    
end


onlyUseBottomBuds=false;

%this is the fraction of buds that must be down (btween the trap outlet)
%for the cell to be classified as downward budding and used.

if params.motherDurCutoff<1
    motherDurCutoff=length(cTimelapse.timepointsProcessed)*params.motherDurCutoff;
else
    motherDurCutoff=params.motherDurCutoff;
end
motherDistCutoff=params.motherDistCutoff;
budDownThresh=params.budDownThresh;


if ~isfield(cTimelapse.lineageInfo,'motherIndex')
    fprintf('finding mother index \n')
    cTimelapse.findMotherIndex;
end

%the trackCells function must be run prior to this

histLabels=zeros(length(cTimelapse.cTimepoint(1).trapInfo),1e5);

for tp=1:length(cTimelapse.timepointsToProcess)
    if cTimelapse.timepointsProcessed(tp)
        timepoint=cTimelapse.timepointsToProcess(tp);
        trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
        for trap=1:length(cTimelapse.cTimepoint(1).trapInfo)
            if trapInfo(trap).cellsPresent
                %                 histLabels(trap,trapInfo(trap).cellLabel)=histLabels(trap,trapInfo(trap).cellLabel)+ones(1,length(trapInfo(trap).cellLabel));
                t=cTimelapse.lineageInfo.motherIndex(trap,timepoint);
                if t
                    if numel(trapInfo(trap).cellLabel)>0
                        histLabels(trap,trapInfo(trap).cellLabel(t))=histLabels(trap,trapInfo(trap).cellLabel(t))+1;
                    end
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
cTimelapse.lineageInfo.motherInfo.motherLabel=[];
cTimelapse.lineageInfo.motherInfo.motherTrap=[];
fitFun=fittype('poly1');

for trap=1:length(cTimelapse.cTimepoint(1).trapInfo)
    for mCell=1:2
        if motherDuration(trap,mCell)<motherDurCutoff
            break;
        end
        mother=cTimelapse.lineageInfo.motherLabel(trap,mCell);
        trapL=find(cTimelapse.extractedData(1).trapNum==trap);
        motherLoc=find(cTimelapse.extractedData(1).trapNum==trap & cTimelapse.extractedData(1).cellNum==mother);

        tpCheck=full(cTimelapse.extractedData(1).xloc(motherLoc,:))>0;
        if length(trapL)<1 || ~all(size(tpCheck)) || sum(tpCheck)==0
            break;
        end
        
        tpBefore=find(diff(smooth(double(tpCheck),3)>0,1)>0);
        tpCheckBefore=zeros(size(tpCheck));
        if ~isempty(tpBefore)
            tpCheckBefore(:,1:tpBefore)=1;
        end
        tpCheckBefore=tpCheckBefore>0;
        
        %cells must be pres when the mother is, but not at any other time
        presDuringMother=full(max(cTimelapse.extractedData(1).xloc(:,tpCheck)>0,[],2));
        if ~isempty(presDuringMother) & size(presDuringMother,1)~=size(cTimelapse.extractedData(1).trapNum,1)
%             presDuringMother=presDuringMother';
            presDuringMother=reshape(presDuringMother,size(cTimelapse.extractedData(1).trapNum));
        end

        onlyPresDuringMother=full(~max(cTimelapse.extractedData(1).xloc(:,tpCheckBefore)>0,[],2));
        if ~isempty(onlyPresDuringMother) & size(onlyPresDuringMother,1)~=size(cTimelapse.extractedData(1).trapNum,1)
            onlyPresDuringMother=reshape(onlyPresDuringMother,size(cTimelapse.extractedData(1).trapNum));
        end
        if isempty(onlyPresDuringMother)
            onlyPresDuringMother=presDuringMother>-1;
        end
        trapLDaughters=find(cTimelapse.extractedData(1).trapNum==trap & ~(cTimelapse.extractedData(1).cellNum==mother) & presDuringMother & onlyPresDuringMother );
        
        xlocDaughters=full(cTimelapse.extractedData(1).xloc(trapLDaughters,tpCheck));
        ylocDaughters=full(cTimelapse.extractedData(1).yloc(trapLDaughters,tpCheck));
        daughterRadius=full(cTimelapse.extractedData(1).radius(trapLDaughters,tpCheck));
        daughterRSmooth=[];daughterRStart=[];
        
        motherRadius=full(cTimelapse.extractedData(1).radius(motherLoc,tpCheck));
        motherRadius(motherRadius<7)=7;
        motherRadius=smooth(motherRadius,20,'moving')';
        motherXLoc=full(cTimelapse.extractedData(1).xloc(motherLoc,tpCheck));
        motherYLoc=full(cTimelapse.extractedData(1).xloc(motherLoc,tpCheck));

                xlocDaughters(xlocDaughters==0)=NaN;
        ylocDaughters(ylocDaughters==0)=NaN;

        daughterRStart=500;
        daughterGRate=0;
        daughtersCloseToMother=[];
        if isempty(xlocDaughters)
            xlocDaughters=zeros(1,sum(tpCheck));
            ylocDaughters=zeros(1,sum(tpCheck));
            daughterGRate=0;
            daughtersCloseToMother=0;
        else
            for d=1:size(daughterRadius,1)
                tempLoc=daughterRadius(d,:)>0;
                if sum(tempLoc)
                    tempSmooth=smooth(daughterRadius(d,tempLoc),5);
                    daughterRSmooth(d,tempLoc)=tempSmooth;
                    len=length(tempSmooth);
                    len=min([5 len]);
                    daughterRStart(d)=min(tempSmooth(1:len));
                    
                    
                    xDistToMother=xlocDaughters(d,:)-motherXLoc;
                    yDistToMother=ylocDaughters(d,:)-motherYLoc;
                    
                    %only look at the first three tp a cell is there to see
                    %if it is nearby a mother
                    indThere=find(tempLoc);
                    indThere=indThere(1:len);
                    %if cell is to the right of the mother (between trap), be more
                    %lenient in the distance
                    xDistToMother(xDistToMother>3)=xDistToMother(xDistToMother>3)-3;
                    
                    distToMother=sqrt(xDistToMother.^2 + yDistToMother.^2);
                    nearbyMother=distToMother(indThere) <= 1+motherDistCutoff + daughterRSmooth(indThere) + motherRadius(indThere);
                    daughtersCloseToMother(d)=max(nearbyMother);
                    
                    %don't really use the growth rate thing anymore
                    if len>100
                        tFit=fit([1:length(tempSmooth)]',tempSmooth,fitFun);
                        daughterGRate(d)=tFit.p1;
                    else
                        daughterGRate(d)=0;
                    end
                else
                        t1=ones(size(daughterRadius(1,:)))*1e3;
                        daughterRSmooth(d,1:length(t1))=t1;
                    daughterRStart(d)=1e3;
                    daughterGRate(d)=0;
                    daughtersCloseToMother(d)=0;
                end
                
            end
            daughterRadius=daughterRSmooth;
        end
        
        
        xDistToMother=xlocDaughters-repmat(motherXLoc,size(xlocDaughters,1),1);
        yDistToMother=ylocDaughters-repmat(motherYLoc,size(ylocDaughters,1),1);
        
%         %if cell is to the right of the mother (between trap), be more
%         %lenient in the distance
        xDistToMother(xDistToMother>0)=xDistToMother(xDistToMother>0)-3;
%         
%         %throw away cells that are too far from the mother, and are too big
%         distToMother=sqrt(xDistToMother.^2 + yDistToMother.^2);
%         daughtersCloseToMother=distToMother < repmat(1+motherDistCutoff*(params.birthRadiusThresh-1) + motherRadius,size(distToMother,1),1);
% 
%         actualDaughters=max((daughtersCloseToMother),[],2);
        actualDaughters=daughtersCloseToMother';
        
        daughtersPassRadTest=daughterRStart<params.birthRadiusThresh;
        daughtersPassGrowthRadTest=daughterGRate>params.daughterGRateThresh;
        actualDaughters=actualDaughters & daughtersPassRadTest' & daughtersPassGrowthRadTest';
        
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
        if onlyUseBottomBuds
            temp=daughterXLoc(actualDaughters)>median(motherXLoc);
            b=zeros(size(actualDaughters));
            b(actualDaughters)=temp;
            actualDaughters=b>0;
        end
        
        
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
        distToMother=sqrt(xDistToMother.^2 + yDistToMother.^2);

        minMothDist=distToMother(actualDaughterPos(actualDaughters,:));
        
        daughterDuration=sum(xlocDaughters(actualDaughters,:)>0,2);
        
        
        %need to make sure only the daughters within the distance cutoff are
        %selected
        daughterMinRad=daughterMinRad(actualDaughters);
        daughterLabel=cTimelapse.extractedData(1).cellNum(trapLDaughters);
        daughterLabel=daughterLabel(actualDaughters);
        daughterTrapNum=cTimelapse.extractedData(1).trapNum(trapLDaughters);
        daughterTrapNum=daughterTrapNum(actualDaughters);
        t=find(tpCheck);
        motherStart=t(1);
        motherEnd=t(end);
        
        cTimelapse.lineageInfo.motherInfo.daughterXLoc(end+1,1:length(daughterXLoc))=daughterXLoc;
        cTimelapse.lineageInfo.motherInfo.daughterYLoc(end+1,1:length(daughterYLoc))=daughterYLoc;
        cTimelapse.lineageInfo.motherInfo.minMothDist(end+1,1:length(minMothDist))=minMothDist;
        cTimelapse.lineageInfo.motherInfo.daughterDuration(end+1,1:length(daughterDuration))=daughterDuration;
        cTimelapse.lineageInfo.motherInfo.motherLabel(end+1)=mother;

        
        cTimelapse.lineageInfo.motherInfo.birthTime(end+1,1:length(birthTimes))=birthTimes;
        cTimelapse.lineageInfo.motherInfo.birthRadius(end+1,1:length(daughterMinRad))=daughterMinRad;
        cTimelapse.lineageInfo.motherInfo.daughterLabel(end+1,1:length(daughterLabel))=daughterLabel;
        cTimelapse.lineageInfo.motherInfo.daughterTrapNum(end+1,1:length(daughterTrapNum))=daughterTrapNum(:,1);
        cTimelapse.lineageInfo.motherInfo.motherTrap(end+1)=trap;

        cTimelapse.lineageInfo.motherInfo.motherStartEnd(end+1,1:2)=[motherStart motherEnd];
    end
end