function [ experiments ] = separateExperimentAll( cExperiment,nStrains,savePath,tags,globalFilter)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%returns 3 cExperiment files. according to nPos. assuming same nPos for all
%3 strains.

if nargin<5
    globalFilter=[];
end

cExperiment.correctSkippedFramesInf;

dirs=cExperiment.dirs;
posStr=regexp(dirs,'\d{1,3}','match');
posNum=[];
for strainInd=1:length(posStr)
    posNum(strainInd)=str2num(posStr{strainInd}{1});
end

[posNumSort posInd]=sort(posNum); %motherDurPres=motherDur(loc);

if length(nStrains)==1
    floorInd=floor(length(posNum)/nStrains); %assuming same number of positions per strain.
%     posData.wtPosLoc=posInd(1:floorInd);
%     posData.ste11PosLoc=posInd(floorInd+1:floorInd*2);
%     posData.ssk1PosLoc=posInd(floorInd*2+1:floorInd*3);
    for i=1:nStrains
        strainName=['strain' num2str(i)];
        posData.(strainName)=posInd(floorInd*(i-1)+1:floorInd*i);
    end
else
    posData.wtPosLoc=posInd(1:nStrains(1));
    posData.ste11PosLoc=posInd(nStrains(1)+1:nStrains(1)+nStrains(2));
    posData.ssk1PosLoc=posInd(nStrains(1)+nStrains(2)+1:sum(nStrains));
    %change nStrains back so it is equal to the actual number of
    %strains
    nStrains=length(nStrains);
end

posDataFieldNames=fieldnames(posData);

cExperiment_ = cExperiment;

for strainInd=1:nStrains
    cExperiment = [];
    mPos=posData.(posDataFieldNames{strainInd});
    infSize=length(cExperiment_.cellInf(1).posNum);
    mSize=length(mPos);
    loc=repmat(cExperiment_.cellInf(1).posNum',1,mSize) == repmat(mPos,infSize,1);
    loc=max(loc,[],2);
    
    if(~isempty(globalFilter))
        
        loc  = loc & globalFilter;
    end
    
    for channelInd=1:length(cExperiment_.cellInf)
        cellInfFields=fieldnames(cExperiment_.cellInf(channelInd));
        
        for fieldInd=1:length(cellInfFields)
            t=cExperiment_.cellInf(channelInd).(cellInfFields{fieldInd});
            try
                if min(size(t))>1
                    cExperiment.cellInf(channelInd).(cellInfFields{fieldInd}) = t(loc,:);
                elseif size(t,1)==length(loc) || size(t,2)==length(loc)
                    cExperiment.cellInf(channelInd).(cellInfFields{fieldInd}) =  t(loc);
                else
                    cExperiment.cellInf(channelInd).(cellInfFields{fieldInd}) =  t;
                end
            catch
                cExperiment.cellInf(channelInd).(cellInfFields{fieldInd}) =  [];
            end
        end
    end
    
    folderName = [savePath,filesep,tags{strainInd}];
    
    if(exist(folderName,'dir'))
        save(strcat(folderName,filesep,'cExperiment.mat'),'cExperiment')
    else
        
        mkdir(folderName);
        save(strcat(folderName,filesep,'cExperiment.mat'),'cExperiment')
        
        
    end
    
end





end

