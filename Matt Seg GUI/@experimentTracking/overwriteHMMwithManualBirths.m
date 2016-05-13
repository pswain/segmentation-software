function overwriteHMMwithManualBirths(cExperiment)
% overwriteHMMwithManualBirths(cTimelapse)
%
% this overwrites the birthTimeHMM with the manually annotated births.
% Manually annotated birth events are kept separate so that they don't
% accidentally get overwritten by the HMM script. This replaces the HMM
% birth events so that if code has been written to call the birthTimeHMM,
% that code doesn't have to be changed and can easily be used with manually
% anntated birth events


cExperiment.lineageInfo.motherInfo.motherTrap;

cExperiment.lineageInfo.motherInfo.birthTimeHMM=cExperiment.lineageInfo.motherInfo.birthTime;
cExperiment.lineageInfo.motherInfo.daughterLabelHMM=cExperiment.lineageInfo.motherInfo.daughterLabel;
cExperiment.lineageInfo.motherInfo.birthRadiusHMM=cExperiment.lineageInfo.motherInfo.birthRadius;

mTrap=cExperiment.lineageInfo.motherInfo.motherTrap;

manTrap=cExperiment.lineageInfo.motherInfo.manualInfo.trapNum;
manPos=cExperiment.lineageInfo.motherInfo.manualInfo.posNum;

for trapInd=1:length(mTrap)
    currTrap=manTrap(trapInd);
    currPos=manPos(trapInd);
    
    bTManual=cExperiment.lineageInfo.motherInfo.birthTimeManual(trapInd,:);
    
    loc = find(cExperiment.lineageInfo.motherInfo.motherTrap== currTrap ...
        & cExperiment.lineageInfo.motherInfo.motherPosNum == currPos);
    if ~isempty(loc)
        cExperiment.lineageInfo.motherInfo.birthTimeHMM(loc,1:length(bTManual))=bTManual;
    end
end
cExperiment.lineageInfo.motherInfo.manualInfo.oldManualBT=cExperiment.lineageInfo.motherInfo.birthTimeManual;
cExperiment.lineageInfo.motherInfo.birthTimeManual=[];

cExperiment.saveExperiment;