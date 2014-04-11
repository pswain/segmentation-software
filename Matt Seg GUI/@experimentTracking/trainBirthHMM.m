function trainBirthHMM(cExperiment)
% this function extracts the training states that will be used by the HMM
% to determine the times of birth for the daughter cells. The functions
% extractHMMTrainingStates must run before this function has been called.

if isempty(cExperiment.lineageInfo.daughterHMMTrainingStates)
    errdlg('Must run extractHMMTrainingStates first');
end




trans = [0.9 0.1 0; ...
    .2 .7 .1; ...
    .2  0 .8];

emis=[];
emis(1,:)=1:-.1:.1;
emis(2,:)=.1:.1:1;
emis(3,:)=ones(size(emis(1,:)));


emis=emis./repmat(sum(emis,2),1,size(emis,2));

trguess=trans;
emguess=emis;
[ESTTR,ESTEMIT] =hmmtrain(cExperiment.lineageInfo.daughterHMMTrainingStates,trguess,emguess,'Algorithm','BaumWelch','Maxiterations',100,'Tolerance',1e-3);



cExperiment.lineageInfo.birthHMM.estTrans=ESTTR;
cExperiment.lineageInfo.birthHMM.estEmis=ESTEMIT;
