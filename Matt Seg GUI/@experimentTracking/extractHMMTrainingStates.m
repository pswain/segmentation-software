function extractHMMTrainingStates(cExperiment)
% this function extracts the training states that will be used by the HMM
% to determine the times of birth for the daughter cells. The functions
% extractLineageInfo and compileLineageInfo must be run before this
% function has been called.

if isempty(cExperiment.lineageInfo.motherInfo.daughterLabel)
    errdlg('Must run extractLineageInfo first');
end


indTrapCells{1}.rad=[];

motherTraps=cExperiment.lineageInfo.motherInfo.motherTrap;
for trapIndex=1:length(motherTraps);%(cTimelapse.extractedData(1).trapNum)
    trap=motherTraps(trapIndex);
    index=1;
    loc=cExperiment.lineageInfo.motherInfo.daughterLabel(trapIndex,:)>0;
    currPos=cExperiment.lineageInfo.motherInfo.motherPosNum(trapIndex);
        for cellIndex=1:sum(loc)
            cellL=cExperiment.lineageInfo.motherInfo.daughterLabel(trapIndex,cellIndex);
            tempPos=cExperiment.cellInf(1).posNum==currPos;
            tempTrap=cExperiment.cellInf(1).trapNum==trap;
            tempCell=cExperiment.cellInf(1).cellNum==cellL;
            daughterLoc=tempPos & tempTrap & tempCell;
            indTrapCells{trapIndex}.rad(index,:)=cExperiment.cellInf(1).radius(daughterLoc,:);
            index=index+1;
        end
end

for trap=1:length(indTrapCells)
    rad=indTrapCells{trap}.rad>0;
    rad=double(rad);
    convMat=size(indTrapCells{trap}.rad,2)+99:-1:100;
    c=rad.*repmat(convMat,[size(rad,1) 1]);
    
    rMax=max(c,[],2);
    c=c-repmat(rMax, [1 size(c,2)]);
    c=c+10;
    c(c<1)=1;
    
    indTrapCells{trap}.newborn=c;
    trainingStates{trap}=max(indTrapCells{trap}.newborn);
end

cExperiment.lineageInfo.daughterHMMTrainingStates=trainingStates;