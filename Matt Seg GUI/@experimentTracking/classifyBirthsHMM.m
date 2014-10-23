function classifyBirthsHMM(cExperiment,birthHMM)
% this function extracts the training states that will be used by the HMM
% to determine the times of birth for the daughter cells. The functions
% extractLineageInfo and compileLineageInfo must be run before this
% function has been called.

if isempty(cExperiment.lineageInfo.motherInfo.daughterLabel)
    errdlg('Must load a HMM or run trainBirthHMM');
end

if nargin<2 && isempty(cExperiment.lineageInfo.birthHMM.estTrans)
    errdlg('Must load a HMM or run trainBirthHMM');
end

if nargin<2
    birthHMM=cExperiment.lineageInfo.birthHMM;
end

cExperiment.lineageInfo.HMMbirths=[];
cExperiment.lineageInfo.motherInfo.birthTimeHMM=[];

for i=1:length(cExperiment.lineageInfo.daughterHMMTrainingStates)

state=hmmdecode(cExperiment.lineageInfo.daughterHMMTrainingStates{i},birthHMM.estTrans,birthHMM.estEmis);
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

% the below matches up the daughterlabels and radius now that a bunch of
% the daughters have been removed as a result of the HMM
cExperiment.lineageInfo.motherInfo.birthRadiusHMM=[];
cExperiment.lineageInfo.motherInfo.daughterLabelHMM=[];
for i=1:size(cExperiment.lineageInfo.motherInfo.birthTimeHMM,1)
    bTimeHMM=cExperiment.lineageInfo.motherInfo.birthTimeHMM(i,:);
    bTime=cExperiment.lineageInfo.motherInfo.birthTime(i,:);
    
    %this makes sure there is only one cell at each timepoint that is
    %classified as a daughter. Not the best way to do it, and should use
    %the radius/location information for a more informed guess.
    bTimeUnique=[1 diff(bTime)]>0;
    
    bTimeHMMarray=repmat(bTimeHMM',1,length(bTime));
    bTimeArray=repmat(bTime,length(bTimeHMM),1);
    
    loc=max(bTimeHMMarray == bTimeArray) & bTimeUnique;
    
    temp=cExperiment.lineageInfo.motherInfo.birthRadius(i,loc);
    temp=temp(temp>0);
    cExperiment.lineageInfo.motherInfo.birthRadiusHMM(i,1:length(temp))=temp;
    temp=cExperiment.lineageInfo.motherInfo.daughterLabel(i,loc);
        temp=temp(temp>0);
        cExperiment.lineageInfo.motherInfo.daughterLabelHMM(i,1:length(temp))=temp;
    
end

cExperiment.saveExperiment
