function motherIndex=findMotherIndex(cTimelapse)
%Identify the mother index ... cells that are closest to the center of the
%trap, but based on their location on trapInfo.cell
%1) use the distance to the "center"
%2) if closest cell is <1/4 of trap dimensions away from it, it is the
%mother


%identify the center of the trap by finding the mode of the x and y
%locations
xloc=zeros(1,1e5);
yloc=zeros(1,1e5);
ind=1;

for timepoint=cTimelapse.timepointsToProcess
    if cTimelapse.timepointsProcessed(timepoint)
        trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
        for trap=1:length(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo)
            if trapInfo(trap).cellsPresent
                circen=[trapInfo(trap).cell(:).cellCenter];
                circen=reshape(circen,2,length(circen)/2)';
                xloc(ind:ind+size(circen,1)-1)=circen(:,1);
                yloc(ind:ind+size(circen,1)-1)=circen(:,2);
                ind=ind+size(circen,1);
            end
        end
    end
end
cellPres=xloc>0;
trapCenterX=median(xloc(cellPres));
trapCenterY=median(yloc(cellPres));

%debug for old cTimelapses without the cTrapSize parameter
if isempty(cTimelapse.cTrapSize)
    cTimelapse.cTrapSize.bb_height=40;
    cTimelapse.cTrapSize.bb_width=40;
end
    % if the closest cell is within a 1/6 of the frame from the center of the
% trap, that is the mother

cutoff=ceil(cTimelapse.cTrapSize.bb_height/6);
motherIndex=[];
pt1=[trapCenterX trapCenterY];
pt1=double(pt1);
for timepoint=1:length(cTimelapse.timepointsProcessed)
    if cTimelapse.timepointsProcessed(timepoint)
        disp(['Timepoint ' int2str(timepoint)]);
        
        trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
        
        for trap=1:length(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo)
            if trapInfo(trap).cellsPresent
                circen=[trapInfo(trap).cell(:).cellCenter];
                circen=reshape(circen,2,length(circen)/2)';
                pt2=[circen];
                pt2=double(pt2);
                
                dist=pdist2(pt1,pt2);
                [val, ind]=min(dist);
                if val<cutoff
                    motherIndex(trap,timepoint)=ind;
                else
                    motherIndex(trap,timepoint)=0;
                end
            else
                motherIndex(trap,timepoint)=0;
            end
        end
    end
end


cTimelapse.lineageInfo.motherIndex=motherIndex;
%%
% During the tracking step, deal with mothers differently


% Once cells have been labelled, go back throug hand create a list of
% mothers