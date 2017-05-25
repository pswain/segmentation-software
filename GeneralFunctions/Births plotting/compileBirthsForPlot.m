function data=compileBirthsForPlot(cExperiment,mStartTime, mEndTime)
%Creates the data structure used by methods in this folder for plotting
%birth results

%Set default parameters
if nargin<2
    mStartTime=1;
    if nargin<3
        mEndTime=length(cExperiment.timepointsToProcess);
    end
end

totalTimepoints=length(cExperiment.timepointsToProcess);
data=[];
%only use mothers there for most of the run
% motherDur=diff(cExperiment.lineageInfo.motherInfo.motherStartEnd,1,2);
% motherDurThresh=max(motherDur)*.5;
% motherLongEnough=motherDur>=motherDurThresh;
% motherLongEnough=motherLongEnough&cExperiment.lineageInfo.motherInfo.motherStartEnd(:,1)<=mStartTime;
% motherLongEnough=motherLongEnough&cExperiment.lineageInfo.motherInfo.motherStartEnd(:,2)>=mEndTime;

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
