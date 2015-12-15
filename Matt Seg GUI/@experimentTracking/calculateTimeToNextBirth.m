function calculateTimeToNextBirth(cExperiment)

% this calculates the time both from the last birth and to the next birth
% for each of the mother cells that has been identified. It only uses the
% HMM birth times, so those must be calculated before this is run. 

timeToBirthAll=[];
timeFromBirthAll=[];
for i=1:size(cExperiment.lineageInfo.motherInfo.birthTimeHMM,1)
    loc=cExperiment.lineageInfo.motherInfo.birthTimeHMM(i,:);
    loc=loc(loc>0);
    bTimesBW=zeros(length(loc),max(cExperiment.lineageInfo.motherInfo.birthTimeHMM(:)));
    for j=1:length(loc)
        bTimesBW(j,loc(j))=1;
    end
    timeToBirth=[];
    timeFromBirth=[];
    for j=1:size(bTimesBW,1)-1
        if j<size(bTimesBW,1)
            convMax=diff(cExperiment.lineageInfo.motherInfo.birthTimeHMM(i,j:j+1));
        else
            convMax=diff([cExperiment.lineageInfo.motherInfo.birthTimeHMM(i,j) cExperiment.lineageInfo.motherInfo.motherStartEnd(i,2)]);
        end
        convM=convMax:-1:1;
        temp=conv(bTimesBW(j,:),convM,'full');
        timeToBirth(j,1:length(temp))=temp;
        convM=1:convMax;
        temp=conv(bTimesBW(j,:),convM,'full');
        timeFromBirth(j,1:length(temp))=temp;

    end
    temp=max(timeToBirth);
    timeToBirthAll(i,1:length(temp))=temp;
    temp=max(timeFromBirth);
    timeFromBirthAll(i,1:length(temp))=temp;

end

timeToBirthAll(timeToBirthAll==0)=NaN;
timeFromBirthAll(timeFromBirthAll==0)=NaN;


cExperiment.lineageInfo.motherInfo.timeToBirth=timeToBirthAll(:,1:size(cExperiment.cellInf(1).radius,2));
cExperiment.lineageInfo.motherInfo.timeFromBirth=timeFromBirthAll(:,1:size(cExperiment.cellInf(1).radius,2));
