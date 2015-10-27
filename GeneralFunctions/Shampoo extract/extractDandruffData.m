function data=extractDandruffData(currFileName)
%Input currFileName can be a file folder path or a cExperiment object

mStartTime=12;
mEndTime=240;
bb=6;
if ischar(currFileName)
    load(currFileName);
else
    cExperiment=currFileName;
end
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
    data.bTime=cExperiment.lineageInfo.motherInfo.birthTimeHMM(motherLongEnough,:);

%if strfind(currFileName,'ZpT')
%     expTime='\d{1,2}h';
%     expTimeStr=regexp(currFileName,expTime,'match');
%     for tLen=1:length(0)
%         t=regexp(expTimeStr{tLen},'\d{1,2}','match');
%         data.switchTimes(tLen)=str2num(t{1});
%     end
%     
%     expConc='\d{1,2}uM';
%     expConcStr=regexp(currFileName,expConc,'match');
%     temp=regexp(expConcStr{1},'\d{1,2}','match');
%     data.expConcStr=temp{1};
%     
%     
%     %determine number of buds
%     sTimes=[mStartTime data.switchTimes*12+bb mEndTime];
%     ssData=[];
%     radiusMother=full(cExperiment.cellInf(1).radius(motherLoc,:));
%     radiusMother(radiusMother==0)=NaN;
%     for switchIndex=1:length(sTimes)-1
%         tDur=sTimes(switchIndex+1)-sTimes(switchIndex);
%         tDur=tDur/12;
%         temp=data.bTime>sTimes(switchIndex);
%         temp=temp & (data.bTime<sTimes(switchIndex+1));
%         data.birthsPerSeg(switchIndex,:)=sum(temp,2)/tDur;
%         
%         
%         ssData.radius(switchIndex,:)=nanmean(radiusMother(:,sTimes(switchIndex):sTimes(switchIndex+1)),2);
%     end
%     
%     
%     x=data.birthsPerSeg(1,:)';
%     y=data.birthsPerSeg(2,:)';
%     data.ssCorBirths=corr(x,y,'type','Pearson','rows','complete');
%     
%     
%     x=ssData.radius(1,:)';
%     y=data.birthsPerSeg(2,:)';
%     data.ssCorRadBirthsNext=corr(x,y,'type','Pearson','rows','complete');
%     
%     x=ssData.radius(1,:)';
%     y=data.birthsPerSeg(1,:)';
%     data.ssCorRadBirthsSame=corr(x,y,'type','Pearson','rows','complete');
%end
binaryBirths=zeros(size(data.bTime,1),mEndTime);
for cellInd=1:size(data.bTime,1)
    bTimeTemp=data.bTime(cellInd,:);
    bTimeTemp(bTimeTemp==0)=[];
    binaryBirths(cellInd,bTimeTemp)=1;
end

data.cumsumBirths=cumsum(binaryBirths(:,mStartTime:mEndTime),2);
