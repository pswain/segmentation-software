function automaticSelectCells(cTimelapse,params)

if isempty(cTimelapse.timepointsProcessed)
    tempSize=[cTimelapse.cTimepoint.trapInfo];
    cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo));
end

if nargin<2
    params.fraction=.8; %fraction of timelapse length that cells must be present or
    params.duration=5; %number of frames cells must be present
%     params.cellsToCheck=4;
    params.framesToCheck=length(cTimelapse.timepointsProcessed);
    params.framesToCheckEnd=1;
    
    num_lines=1;clear prompt; clear def;
    prompt(1) = {'Fraction of whole timelapse a cell must be present'};
    prompt(2) = {'OR - number of frames a cell must be present'};
    prompt(3) = {'Cell must appear in the first X frames'};
    prompt(4) = {'Cell must be present after frame X'};

    dlg_title = 'Tracklet params';    
    def(1) = {num2str(params.fraction)};
    def(2) = {num2str(params.duration)};
    def(3) = {num2str(params.framesToCheck)};
    def(4) = {num2str(params.framesToCheckEnd)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    params.fraction=str2double(answer{1});
    params.duration=str2double(answer{2});
    params.framesToCheck=str2double(answer{3});
    params.framesToCheckEnd=str2double(answer{4});

end

cTimelapse.cellsToPlot(:)=0;




cTimepoint=cTimelapse.cTimepoint;
for trap=1:length(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo)
    disp(['Trap Number ' int2str(trap)]);
    cellLabels=zeros(1,100*sum(cTimelapse.timepointsProcessed));
    cellLabelsEnd=zeros(1,100*sum(cTimelapse.timepointsProcessed));
    cellsSeen=[];
    index=0;
    for timepoint=cTimelapse.timepointsToProcess
        if cTimelapse.timepointsProcessed(timepoint)
            tempLabels=cTimepoint(timepoint).trapInfo(trap).cellLabel;
            cellLabels(1,index+1:index+length(tempLabels))=tempLabels;
            if timepoint<=params.framesToCheck
                cellsSeen=max(cellLabels);
            end
            if timepoint>=params.framesToCheckEnd
                cellLabelsEnd(1,index+1:index+length(tempLabels))=tempLabels;
            end
            index=index+length(tempLabels);
        end
    end
    tempLabels=cellLabels(1:index);
%     cellLabelsEnd=cellLabelsEnd(1:index);
    cellLabelsEnd(cellLabelsEnd==0)=[];
    cellLabels=tempLabels;
    n=hist(cellLabels,0:max(cellLabels));
    if ~isempty(n)
        n(1)=[];
        nEnd=hist(cellLabelsEnd,0:max(cellLabels));
        nEnd(1)=[];
        cellsSeenEnd=min(cellLabelsEnd);
        
        n(nEnd<1)=0;
    end
    locs=find(n>=sum(cTimelapse.timepointsProcessed)*params.fraction | n>=params.duration);
    
    if ~isempty(cellsSeen) && ~isempty(locs)
        locs=locs(locs<=cellsSeen);
        if ~isempty(locs)
            for cellsForPlot=1:length(locs)
                cTimelapse.cellsToPlot(trap,locs(cellsForPlot))=1;
            end
        end
    end
end
