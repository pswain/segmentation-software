function [ paramRLS, nRLS ] = returnRLSGrowthRate(cExperiment,paramInfo,motherLocLogical,motherLinLoc )
%RETURNPARAMRLS returns the parameter from cellInf centered around each of
%the daughters born to the mother
%   Detailed explanation goes here

% paramInfo.nDiv
% paramInfo.startDiv

if nargin<3 || isempty(motherLocLogical) 
    [motherLocLogical mLongEnough]=returnMotherIndicesCellInf(cExperiment);
end
if nargin<4 || isempty(motherLinLoc) 
    motherLinLoc=1:size(cExperiment.lineageInfo.motherInfo.birthTimeHMM,1);
end
%
birthTimes=cExperiment.lineageInfo.motherInfo.birthTimeHMM;

motherLoc=find(motherLocLogical);
paramRLS=zeros(length(motherLoc),1);
nRLS=[];
for i=1:length(motherLoc)
    mPos=cExperiment.cellInf(1).posNum(motherLoc(i));
    mCell=cExperiment.cellInf(1).cellNum(motherLoc(i));
    mTrap=cExperiment.cellInf(1).trapNum(motherLoc(i));
    mLocTemp = cExperiment.lineageInfo.motherInfo.motherPosNum==mPos;
    mLocTemp = mLocTemp & (cExperiment.lineageInfo.motherInfo.motherLabel==mCell);
        mLocTemp = mLocTemp & (cExperiment.lineageInfo.motherInfo.motherTrap==mTrap);
    mLocTemp=find(mLocTemp);
    bTimeIndex1=birthTimes(mLocTemp,:);
    bTimeIndex1(bTimeIndex1<1)=[];
    if length(bTimeIndex1) > paramInfo.nDiv + paramInfo.startDiv
        paramRLS(i,1)=bTimeIndex1(paramInfo.nDiv + paramInfo.startDiv)-bTimeIndex1(paramInfo.startDiv);
    end
    nRLS(i)=length(bTimeIndex1) ;
end
