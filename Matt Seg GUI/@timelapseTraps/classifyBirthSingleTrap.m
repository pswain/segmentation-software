function [state trainingStates]=classifyBirthSingleTrap(cTimelapse,hmmCell,trap)

clear indTrapCells;
indTrapCells{1}.rad=[];

index=1;
for i=1:length(cTimelapse.extractedData(1).trapNum)
    if cTimelapse.extractedData(1).trapNum(i)==trap
        indTrapCells.rad(index,:)=cTimelapse.extractedData(1).radius(i,:);
        index=index+1;
    end
end

%%
duration=sum(indTrapCells.rad>0,2);
[v locLongest]=max(duration);

rad=indTrapCells.rad>0;
rad=double(rad);
convMat=size(indTrapCells.rad,2)+99:-1:100;
c=rad.*repmat(convMat,[size(rad,1) 1]);

rMax=max(c,[],2);
c=c-repmat(rMax, [1 size(c,2)]);
c=c+10;

c(locLongest,:)=1;

c(c<1)=1;

indTrapCells.newborn=c;
trainingStates=max(indTrapCells.newborn);


state=hmmdecode(trainingStates,hmmCell.estTrans,hmmCell.estEmis);
