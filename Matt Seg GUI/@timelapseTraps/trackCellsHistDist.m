function [histCellDist bins]=trackCellsHistDist(cTimelapse,cellMovementThresh)

% if nargin<2
%     prompt = {'Max change in position and radius before a cell is classified as a new cell'};
%     dlg_title = 'Tracking Threshold';
%     num_lines = 1;
%     def = {'8'};
%     answer = inputdlg(prompt,dlg_title,num_lines,def);
%     cellMovementThresh=str2double(answer{1});
% end



if isempty(cTimelapse.timepointsProcessed)
    tempSize=[cTimelapse.cTimepoint.trapInfo];
    cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(1).trapInfo));
end

% d=zeros(1,1e9)-1;
d=[];
for timepoint=1:length(cTimelapse.timepointsProcessed)
    if cTimelapse.timepointsProcessed(timepoint)
        disp(['Timepoint ' int2str(timepoint)]);
        trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
        if timepoint>1
            trapInfom1=cTimelapse.cTimepoint(timepoint-1).trapInfo;
        end
        for trap=1:length(cTimelapse.cTimepoint(1).trapInfo)
            if timepoint==1
                trapInfo(trap).cellLabel=1:length(trapInfo(trap).cell);
                histCellDist=zeros(1,98);
                bins=1:.5:49.50;
            else
                
                trapInfo(trap).cellLabel=zeros(1,length(trapInfo(trap).cell));
                circen=[trapInfo(trap).cell(:).cellCenter];
                circen=reshape(circen,2,length(circen)/2)';
                cirrad=[trapInfo(trap).cell(:).cellRadius]';
                pt2=[circen cirrad ];
                
                circen=[trapInfom1(trap).cell(:).cellCenter];
                circen=reshape(circen,2,length(circen)/2)';
                cirrad=[trapInfom1(trap).cell(:).cellRadius]';
                pt1=[circen cirrad];

                pt1=double(pt1);pt2=double(pt2);
                dist=cTimelapse.alternativeDist(pt1,pt2);
                distance=min(dist);
                if ~isempty(distance)
                    tempHist=hist(distance,bins);
                else
                    tempHist=zeros(size(histCellDist));
                end
                histCellDist=tempHist+histCellDist;
                d(end+1:end+length(distance))=distance;
            end
        end
        cTimelapse.cTimepoint(timepoint).trapInfo=trapInfo;
    end
end
% bins=d;
end

