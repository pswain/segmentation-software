function keepPos=keepSpecificPos(cExperiment,posToKeep)

expLen=length(cExperiment.cellInf(1).xloc);
posKeepLen=length(posToKeep);
posToKeep=repmat(posToKeep,expLen,1);
expPos=repmat(cExperiment.cellInf(1).posNum,1,posKeepLen);

keepPos=max(posToKeep==expPos,[],2);

