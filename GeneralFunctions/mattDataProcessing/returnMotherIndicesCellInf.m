function loc=returnMotherIndicesCellInf(cExperiment,channel,durThresh,motherLongEnough)

if nargin<2 || isempty(channel)
    channel=1;
end

motherDur=diff(cExperiment.lineageInfo.motherInfo.motherStartEnd,1,2);

if nargin<3 || isempty(durThresh)
    durThresh=min(motherDur);
end

if nargin<4 || isempty(motherLongEnough)
    motherLongEnough=motherDur>=durThresh;
end

mTrap=cExperiment.lineageInfo.motherInfo.motherTrap;
mPos=cExperiment.lineageInfo.motherInfo.motherPosNum;
mCell=cExperiment.lineageInfo.motherInfo.motherLabel;

mTrap=mTrap(motherLongEnough);
mPos=mPos(motherLongEnough);
mCell=mCell(motherLongEnough);


infSize=length(cExperiment.cellInf(channel).posNum);
mSize=length(mPos);

if size(cExperiment.cellInf(channel).posNum,2)>1
    loc=repmat(cExperiment.cellInf(channel).posNum',1,mSize) == repmat(mPos,infSize,1);
    loc=loc & repmat(cExperiment.cellInf(channel).trapNum',1,mSize)== repmat(mTrap,infSize,1);
    loc=loc & repmat(cExperiment.cellInf(channel).cellNum',1,mSize) == repmat(mCell,infSize,1);
else
    loc=repmat(cExperiment.cellInf(channel).posNum,1,mSize) == repmat(mPos,infSize,1);
    loc=loc & repmat(cExperiment.cellInf(channel).trapNum,1,mSize)== repmat(mTrap,infSize,1);
    loc=loc & repmat(cExperiment.cellInf(channel).cellNum,1,mSize) == repmat(mCell,infSize,1);
end

loc=max(loc,[],2);


