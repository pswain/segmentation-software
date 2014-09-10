function loc=returnMotherIndicesCellInf(cExperiment,channel)

if nargin<2
    channel=1;
end

mTrap=cExperiment.lineageInfo.motherInfo.motherTrap;
mPos=cExperiment.lineageInfo.motherInfo.motherPosNum;
mCell=cExperiment.lineageInfo.motherInfo.motherLabel;

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


