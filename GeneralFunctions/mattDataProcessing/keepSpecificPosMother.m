function keepPos=keepSpecificPosMother(cExperiment,posToKeep)



expLen=length(cExperiment.lineageInfo.motherInfo.motherPosNum);
posKeepLen=length(posToKeep);
posToKeep=repmat(posToKeep,expLen,1);
expPos=repmat(cExperiment.lineageInfo.motherInfo.motherPosNum',1,posKeepLen);

keepPos=max(posToKeep==expPos,[],2);

