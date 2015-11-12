function [ param, nRLS ] = returnParamRLS(cExperiment,paramInfo,motherLocLogical,motherLinLoc,birthTimes )
%RETURNPARAMRLS returns the parameter from cellInf centered around each of
%the daughters born to the mother
%   Detailed explanation goes here
% returns parma.RLS - the parameter at each daughter birth
% param.Chron - the parameter aligned to t=0 when the cell was first
% identified
% param.Abs - the raw parameter data
%param.RLScycle - parameter for 12 timepoints after the birth event

% paramInfo.channel
% paramInfo.name

% can pass a parameter bTimes which contains the birthTimes, otherwise it
% defaults to the HMM birth times.

if nargin<3 || isempty(motherLocLogical) 
    [motherLocLogical mLongEnough]=returnMotherIndicesCellInf(cExperiment);
end
if nargin<4 || isempty(motherLinLoc) 
    motherLinLoc=1:size(cExperiment.lineageInfo.motherInfo.birthTimeHMM,1);
end
%
useDefBT=false;
if nargin<5 || isempty(birthTimes) 
    birthTimes=cExperiment.lineageInfo.motherInfo.birthTimeHMM;
    useDefBT=true;
end
param.RLS=[];param.Chron=[];param.Abs=[];param.RLScycle=[];
motherLoc=find(motherLocLogical);
bb=20;nRLS=[];
for i=1:length(motherLoc)
    mPos=cExperiment.cellInf(1).posNum(motherLoc(i));
    mCell=cExperiment.cellInf(1).cellNum(motherLoc(i));
    mTrap=cExperiment.cellInf(1).trapNum(motherLoc(i));
    mLocTemp = cExperiment.lineageInfo.motherInfo.motherPosNum==mPos;
    mLocTemp = mLocTemp & (cExperiment.lineageInfo.motherInfo.motherLabel==mCell);
        mLocTemp = mLocTemp & (cExperiment.lineageInfo.motherInfo.motherTrap==mTrap);
    mLocTemp=find(mLocTemp);
    
    if useDefBT
        bTimeIndex1=birthTimes(mLocTemp,:);
    else
        bTimeIndex1=birthTimes(i,:);
    end
    bTimeIndex1(bTimeIndex1<1)=[];
    bTimeIndex1=[cExperiment.lineageInfo.motherInfo.motherStartEnd(mLocTemp,1) bTimeIndex1];
    if strcmp(paramInfo.name,'nuc')
        param.Abs(i,:)=cExperiment.cellInf(paramInfo.channel).max5(motherLoc(i),:)./cExperiment.cellInf(paramInfo.channel).median(motherLoc(i),:);
    else
        param.Abs(i,:)=cExperiment.cellInf(paramInfo.channel).(paramInfo.name)(motherLoc(i),:);
    end
    t=param.Abs(i,cExperiment.lineageInfo.motherInfo.motherStartEnd(mLocTemp,1) : cExperiment.lineageInfo.motherInfo.motherStartEnd(mLocTemp,2));
    param.Chron(i,1:length(t))=t;
    for j=1:length(bTimeIndex1)
        bTimeIndex=bTimeIndex1(j);
        if j>1 && bTimeIndex>1
            bTimeIndex=bTimeIndex-1;
        end
        bTimeEnd=bTimeIndex+bb;
        if bTimeEnd>size(cExperiment.cellInf(1).radius,2)
            bTimeEnd=size(cExperiment.cellInf(1).radius,2);
        end
        try
            t=param.Abs(i,bTimeIndex:bTimeEnd);
        catch
            b=1;
        end
        t(t==0)=NaN;
        param.RLS(i,j)=nanmean(t);
        param.RLScycle(i,j,1:length(t))=full(t);
        
    end
    nRLS(i)=j;
end
param.Chron(param.Chron==0)=NaN;

maxB=max(nRLS);
for i=1:length(motherLoc)
    temp=param.RLS(i,:);
    temp(temp==0)=[];
    param.RLSdeath(i,maxB-length(temp)+1:maxB)=temp;
end

param.RLSdeath=full(param.RLSdeath);
param.RLS=full(param.RLS);
param.Chron=full(param.Chron);
param.Abs=full(param.Abs);
