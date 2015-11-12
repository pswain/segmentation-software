function overwriteHMMwithManualBirths(cExperiment)

%method is either 'overwrite' or 'update'. If overwrite, it goes through
%all of the cellsToPlot and extracts the information from the saved
%Timelapses. If method is 'update', it finds the cells that have been added
%to the cellsToPlot and adds their inf to the cellInf, and removes those
%that have been removed.

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