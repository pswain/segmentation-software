
function parseLogFile(cExperiment,logFile)
%% parse file
%fid = fopen('/Users/alejandrog/Documents/AquisitionDAta/HOG/ramp_WTPbs2_25Jun_00/ramp_WTPbs2_25Junlog.txt');
fid = fopen(logFile,'r'); 
formatIn = 'dd-mmm-yyyy HH:MM:SS';
tline = fgets(fid);
times = [];
positionStrs = {};
while ischar(tline)
    
    %get the timepoint
    [indS,endS] = regexp(tline,'_[0-9]+-');
    
    if ( ~isempty(indS) )
        timepoint  = str2double(tline((indS+1):(endS-1)));
        disp(['Timepoint ' int2str(timepoint)])
    end
    
    %get the position
    [indS,endS] = regexp(tline, 'Position:[0-9]+,');
    if ( ~isempty(indS) )
        
        position = str2double(tline((indS+9):(endS-1)));
        positionStrs{position} = strtrim(tline((endS+1):(end)));
        
        %disp([num2str(timepoint) ' ' num2str(position) ' ' positionStr])
    end
    
    %get the time
    [indS,endS] = regexp(tline, 'Channel:DIC set at:');
    if ( ~isempty(indS) )
        
        DateString = tline(endS+1:end);
        
        
        times(timepoint, position) = datenum(DateString,formatIn);
        
    end
    
    
    
    tline = fgets(fid);
    
end

fclose(fid);

%% convert to minutes

times = times(1:end-1,:) - times(1,1);
for i = 1:1:size(times,1)
    for j = 1:1:size(times,2)
        
        timesInMinutes(i,j) = sum(datevec(times(i,j)) .* [0 0 0 60 1 1/60]);
    end
end

%% update cExperiment
positionMap = cExperiment.dirs;

%load('../June25-step_wt_pbs2/cExperiments.mat')
positionOfCells = cExperiment.cellInf(1).posNum;

tt = [];
for i = 1:1:length(positionOfCells)
    cellPos = cExperiment.dirs{positionOfCells(i)};
    pos = strcmpi(cellPos,positionStrs);
    tt(i,:) = timesInMinutes(:,pos)';
    
end

cExperiment.cellInf(1).times = tt;


%%



