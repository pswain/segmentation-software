function syncCellTimes(cExperiment,logFile)
parseLogFile(cExperiment,logFile)

variableCells = cExperiment.cellInf(1).radius;

refCell = ceil(size(variableCells,1)/2); %aprox half of the total N of cells
% refCell=size(variableCells,1);
%interpolation time
cellTimes = cExperiment.cellInf(1).times;

cellNumber = size(variableCells,1);
timePoints = cellTimes(refCell,:); %synchronise using the first cell as ref point.

pbs2Sync = [];
%for each cell
for channelInd=1:length(cExperiment.cellInf)
    cellInfFields=fieldnames(cExperiment.cellInf(channelInd));
    
    for fieldInd=1:length(cellInfFields)
        tempVar=cExperiment.cellInf(channelInd).(cellInfFields{fieldInd});
        varSync=[];
        if all(size(tempVar)==size(variableCells))
            varFull = full(tempVar(:,1:size(variableCells,2)-1)); %end of time series -1
            for  ci  =1:1:cellNumber
                try
                    varSync(ci,:) = interp1(cellTimes(ci,:),varFull(ci,:),timePoints,'linear', 'extrap');
                catch
                    varSync(ci,:)=varFull(ci,:);
                end
            end
        
            cExperiment.cellInf(channelInd).(cellInfFields{fieldInd}) = varSync;
        end
        
    end
    cExperiment.cellInf(channelInd).syncTimes=timePoints;
end