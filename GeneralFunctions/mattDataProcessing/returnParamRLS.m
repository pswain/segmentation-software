function [ param, nRLS ] = returnParamRLS(cExperiment,paramInfo,motherLocLogical,motherLinLoc )
%RETURNPARAMRLS returns the parameter from cellInf centered around each of
%the daughters born to the mother
%   Detailed explanation goes here
% returns parma.RLS - the parameter at each daughter birth
% param.Chron - the parameter aligned to t=0 when the cell was first
% identified
% param.Abs - the raw parameter data

% paramInfo.channel
% paramInfo.name

if nargin<3 || isempty(motherLocLogical) 
    [motherLocLogical mLongEnough]=returnMotherIndicesCellInf(cExperiment);
end
if nargin<4 || isempty(motherLinLoc) 
    motherLinLoc=1:size(cExperiment.lineageInfo.motherInfo.birthTimeHMM,1);
end
%
birthTimes=cExperiment.lineageInfo.motherInfo.birthTimeHMM;

param.RLS=[];param.Chron=[];param.Abs=[];
motherLoc=find(motherLocLogical);
bb=8;nRLS=[];
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
    bTimeIndex1=[cExperiment.lineageInfo.motherInfo.motherStartEnd(mLocTemp,1) bTimeIndex1];
    param.Abs(i,:)=cExperiment.cellInf(paramInfo.channel).(paramInfo.name)(motherLoc(i),:);
    t=param.Abs(i,cExperiment.lineageInfo.motherInfo.motherStartEnd(mLocTemp,1) : cExperiment.lineageInfo.motherInfo.motherStartEnd(mLocTemp,2));
    param.Chron(i,1:length(t))=t;
    for j=1:length(bTimeIndex1)
        bTimeIndex=bTimeIndex1(j);
        bTimeEnd=bTimeIndex+bb;
        if bTimeEnd>size(cExperiment.cellInf(1).radius,2)
            bTimeEnd=size(cExperiment.cellInf(1).radius,2);
        end
        t=param.Abs(i,bTimeIndex:bTimeEnd);
        t(t==0)=NaN;
        param.RLS(i,j)=nanmean(t);
    end
    nRLS(i)=j;
end
param.Chron(param.Chron==0)=NaN;