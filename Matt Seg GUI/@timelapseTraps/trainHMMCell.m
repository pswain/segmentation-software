function hmmCell=trainHMMCell(cTimelapse,params)
% this function takes a timelapse class variable and uses the tracked cells
% to create a HMM of the cell birth state. State 2 of the HMM most closely
% corresponds to the new cell born state. Tried with additional numbers of
% states, but didn't seem to work much better, and occasionally much worse
if nargin<2
    params.trans = [0.9 0.1 0; ...
        .2 .7 .1; ...
        .2  0 .8];
    
    params.emis=[];
    params.emis(1,:)=1:-.1:.1;
    params.emis(2,:)=.1:.1:1;
    params.emis(3,:)=ones(size(params.emis(1,:)));
    params.emis=params.emis./repmat(sum(params.emis,2),1,size(params.emis,2));
    
    % "cells" should be presen for 30+ mins in the tracking to make sure
    % that they are real cells and not just abberant tracking items. This
    % ensures that small blips won't be counted as newborn cells. 
    params.fraction=.1; %fraction of timelapse length that cells must be present or
    params.duration=7; %number of frames cells must be present
    params.framesToCheck=length(cTimelapse.timepointsProcessed);
    params.framesToCheckEnd=1;
end
% 
% cTimelapse.automaticSelectCells(params);
% cTimelapse.extractCellParamsOnly;

cTimelapse.correctSkippedFramesInf;
rad=cTimelapse.extractedData(1).radius;

%
indTrapCells{1}.rad=[];

for trap=1:max(cTimelapse.extractedData(1).trapNum)
    index=1;
    for i=1:length(cTimelapse.extractedData(1).trapNum)
        if cTimelapse.extractedData(1).trapNum(i)==trap
            indTrapCells{trap}.rad(index,:)=cTimelapse.extractedData(1).radius(i,:);
            index=index+1;
        end
    end
end

%
for trap=1:max(cTimelapse.extractedData(1).trapNum)
    duration=sum(indTrapCells{trap}.rad>0,2);
    [v locLongest]=max(duration);

    rad=indTrapCells{trap}.rad>0;
    rad=double(rad);
    convMat=size(indTrapCells{trap}.rad,2)+99:-1:100;
    c=rad.*repmat(convMat,[size(rad,1) 1]);
    
    rMax=max(c,[],2);
    c=c-repmat(rMax, [1 size(c,2)]);
    c=c+10;
    
    c(locLongest,:)=1;
    c(c<1)=1;
    
    indTrapCells{trap}.newborn=c;
    trainingStates{trap}=max(indTrapCells{trap}.newborn);
end

for trap=max(cTimelapse.extractedData(1).trapNum):-1:1
    if sum(trainingStates{trap}==1)/length(trainingStates{trap}) >.9
        trainingStates{trap}=[];
    end
end


trguess=params.trans;
emguess=params.emis;
[hmmCell.estTrans,hmmCell.estEmis] =hmmtrain(trainingStates,trguess,emguess,'Algorithm','BaumWelch','Maxiterations',100,'Tolerance',1e-3);
hmmCell.params=params;