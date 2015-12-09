function data=extractDandruffData(currFileName)
%Input currFileName can be a file folder path or a cExperiment object
mStartTime=12;
mEndTime=196;
bb=6;
if ischar(currFileName)
    load(currFileName);
else
    cExperiment=currFileName;
end
totalTimepoints=length(cExperiment.timepointsToProcess);
data=[];
data.filename=currFileName;
%only use mothers there for most of the run
motherDur=diff(cExperiment.lineageInfo.motherInfo.motherStartEnd,1,2);
motherDurThresh=max(motherDur)*.5;
motherLongEnough=motherDur>=motherDurThresh;
motherLongEnough=motherLongEnough&cExperiment.lineageInfo.motherInfo.motherStartEnd(:,1)<=mStartTime;
motherLongEnough=motherLongEnough&cExperiment.lineageInfo.motherInfo.motherStartEnd(:,2)>=mEndTime;

motherLoc=returnMotherIndicesCellInf(cExperiment,[],motherDurThresh,motherLongEnough);
data.motherIndices=find(motherLoc);
data.bTime=cExperiment.lineageInfo.motherInfo.birthTimeHMM(motherLongEnough(1:size(cExperiment.lineageInfo.motherInfo.birthTimeHMM,1)),:);


binaryBirths=zeros(size(data.bTime,1),totalTimepoints);
for cellInd=1:size(data.bTime,1)
    bTimeTemp=data.bTime(cellInd,:);
    bTimeTemp(bTimeTemp==0)=[];
    binaryBirths(cellInd,bTimeTemp)=1;
end

data.cumsumBirths=cumsum(binaryBirths(:,1:totalTimepoints),2);
