function extractFitness(cExperiment, durationCutoff,filtParams)
% extractLineageInfo must be run before this is called, otherwise all of
% the relevant information won't have been created.

fitnessType='fit';
cExperiment.correctSkippedFramesInf;

%durationCutoff  - either a fraction of the timelapse that a cell must be
%present, or a number of frames the cell must be present
if nargin<2
    durationCutoff=.9;
    %     durationCutoff=40
end

if nargin<3
    filtParams.num=48;
    filtParams.std=10;
    filtParams.type='Normal';
end


% need to figure out a way to check whether the appropriate information is
% present in the cExperiment container, and not just that it is present,
% but that it matches up between the cellInf and the lineageInfo.

birthFitness=[];
daughterGrowthFitness=[];
duration=diff(cExperiment.lineageInfo.motherInfo.motherStartEnd,1,2);
index=0;

avNum=filtParams.num;
fitFilter=pdf(filtParams.type,-avNum/2:avNum/2,0,filtParams.std);

cellPres=[];
% cellPres=zeros([size(cExperiment.lineageInfo.motherInfo.birthTime,1)  max(cExperiment.lineageInfo.motherInfo.motherStartEnd(:))]);
if durationCutoff<1
    cellPresDur=duration>max(duration)*durationCutoff;
else
    cellPresDur=duration>durationCutoff;
end
fitFun=fittype('poly1');
for i=1:size(cExperiment.lineageInfo.motherInfo.birthTime,1)
    i
    if cellPresDur(i)
        %below calculates the fitness based on the times of daughter births
        tempDur=cExperiment.lineageInfo.motherInfo.motherStartEnd(i,1):cExperiment.lineageInfo.motherInfo.motherStartEnd(i,2);
        index=index+1;

        y=zeros(1,cExperiment.lineageInfo.motherInfo.motherStartEnd(i,2));
        loc=cExperiment.lineageInfo.motherInfo.birthTime(i,:);
        loc=loc(loc>0);
        y(loc)=1;
        y=y(cExperiment.lineageInfo.motherInfo.motherStartEnd(i,1):cExperiment.lineageInfo.motherInfo.motherStartEnd(i,2));
        y=conv(y,fitFilter,'same');
        
        finalY=y;
        
        birthFitness(index,cExperiment.lineageInfo.motherInfo.motherStartEnd(i,1):cExperiment.lineageInfo.motherInfo.motherStartEnd(i,2))=finalY;
        cellPres(index,tempDur)=ones(1,length(tempDur));
        
        %below calculates the fitness based on the growth rate of the
        %daughters
        loc=tempDur;
        motherFitness=zeros(length(loc),size(cExperiment.cellInf(1).radius,2));
        motherLoc=i;
        dLabels=cExperiment.lineageInfo.motherInfo.daughterLabel(motherLoc,:);
        dLabels(dLabels==0)=[];
        trap=cExperiment.lineageInfo.motherInfo.daughterTrapNum(motherLoc,1);
        pos=cExperiment.lineageInfo.motherInfo.motherPosNum(motherLoc);
        
        daughtRad=[];
        daughterFitness=zeros(length(dLabels),size(cExperiment.cellInf(1).radius,2));
        for j=1:length(dLabels)
            cellNum=dLabels(j);
            
            cellLoc=(cExperiment.cellInf(1).cellNum==cellNum)& (cExperiment.cellInf(1).trapNum==trap) & (cExperiment.cellInf(1).posNum==pos);
            cellRad=cExperiment.cellInf(1).radius(cellLoc,:);
            %check to make sure that there are at least 2 cellRad values to
            %use to fit a line to
            if sum(cellRad>0)>1

                t=cellRad;
                locD=find(t>0);
                t(t==0)=[];
                t=full(t);
                %The below fits a curve to the whole time a daughter is present
                %in a trap. This works well, except that if a cell pauses and
                %the daughter stays for a long time, in doesn't catch the
                %change in behavior
                if strcmp(fitnessType,'fit')
                    x=1:length(t);
                    t=4/3*pi*t.^3;
                    fitted=fit(x',t',fitFun);
                    locD(1)=max(1,locD(1)-3);
                    daughterFitness(j,locD(1):locD(end))=fitted.p1;
                else
                    
                    
                    % This instead calculates the moving difference in the radius of the
                    % daughter. Hopefully this should capture more the dynamic changes in
                    % daughter behavior.
                    dN=1;
                    t=smooth(t,2);
                    %             t=4/3*pi*t.^3;
                    t=full(t);
                    diffRad=diff(t,dN);
                    sN=ones(1,5);
                    tempD=conv(diffRad,sN,'same');
                    movDiff=zeros(size(t))*NaN;
                    movDiff(1:end-dN)=tempD;
                    tempD=fliplr(conv(fliplr(diffRad),sN,'same'));
                    movDiffReverse=zeros(size(t))*NaN;
                    movDiffReverse(1+dN:end)=tempD;
                    
                    movDiff(movDiff==0)=NaN;
                    movDiffReverse(movDiffReverse==0)=NaN;
                    meanRadGradient=nanmean([movDiff; movDiffReverse]);
                    meanRadGradient(isnan(meanRadGradient))=0;
                    daughterFitness(j,locD(1):locD(end))=meanRadGradient;
                    tStart=max(1,locD(1)-2);
                    daughterFitness(j,tStart:locD(1))=meanRadGradient(1);
                end
                
            end
            daughterGrowthFitness(index,:)=max(daughterFitness);
        end
        
    end
end

cExperiment.lineageInfo.birthFitness=birthFitness;
cExperiment.lineageInfo.cellPresFitness=cellPres>0;
cExperiment.lineageInfo.cellPresDuration=cellPresDur;
cExperiment.lineageInfo.dGrowthFitness=daughterGrowthFitness;

