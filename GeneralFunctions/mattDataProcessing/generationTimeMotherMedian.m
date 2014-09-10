function medianGenTime=generationTimeMotherMedian(cExperiment,motherToUse,duplCutoff)

birthTimes=cExperiment.lineageInfo.motherInfo.birthTime;
duplicateBirth=diff(birthTimes,1,2)<duplCutoff;
birthTimesRemovedDuplicates=[];
for i=1:size(duplicateBirth,1)
    temp=birthTimes(i,:);
    temp(duplicateBirth(i,:))=[];
    birthTimesRemovedDuplicates(i,1:length(temp))=temp;
end

gTime=diff(birthTimesRemovedDuplicates(motherToUse,:),1,2);
gTime(gTime<1)=NaN;
medianGenTime=nanmedian(gTime,2);