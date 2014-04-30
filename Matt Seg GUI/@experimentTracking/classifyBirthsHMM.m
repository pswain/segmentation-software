function classifyBirthsHMM(cExperiment)
% this function extracts the training states that will be used by the HMM
% to determine the times of birth for the daughter cells. The functions
% extractLineageInfo and compileLineageInfo must be run before this
% function has been called.

if isempty(cExperiment.lineageInfo.motherInfo.daughterLabel)
    errdlg('Must load a HMM or run trainBirthHMM');
end
cExperiment.lineageInfo.HMMbirths=[];
cExperiment.lineageInfo.motherInfo.birthTimeHMM=[];

for i=1:length(cExperiment.lineageInfo.daughterHMMTrainingStates)

state=hmmdecode(cExperiment.lineageInfo.daughterHMMTrainingStates{i},cExperiment.lineageInfo.birthHMM.estTrans,cExperiment.lineageInfo.birthHMM.estEmis);
cExperiment.lineageInfo.HMMbirths(i,:)=state(2,:);
end

cExperiment.lineageInfo.motherInfo.birthTimeHMM=[];
for i=1:size(cExperiment.lineageInfo.HMMbirths,1)
    
    temp=cExperiment.lineageInfo.HMMbirths(i,:)>.5;
    temp(2:end+1)=temp;
    temp(1)=0;
    birth=diff(temp);
    birthTimes=find(birth>0);
    cExperiment.lineageInfo.motherInfo.birthTimeHMM(i,1:length(birthTimes))=birthTimes;
end

cExperiment.saveExperiment
