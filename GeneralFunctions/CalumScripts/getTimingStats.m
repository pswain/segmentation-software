function [filter_timeLocalised, filter_timesG1]=filterRelocalisedTemplate(savefile)
up=savefile.upslopes;
down=savefile.downslopes;
firstKeypoint=savefile.keypoint;
lastKeypoint=firstKeypoint+4;%Number of timepoints to look for upslopes
filter_timesG1=[];
filter_timeLocalised=[];

for i=1:length(up(:,1))
    %Set vals to empty
    tpG1=[]; tpDelocalised=[];
    
    if any(up(i,firstKeypoint:lastKeypoint))%Upslopes in roi
        upslopePosition=firstKeypoint+find(up(i,firstKeypoint:lastKeypoint),1,'first');
        %Here we know there is an upslope in roi
        %Add filters: Here we find cells which previously exited G1
        tpG1=find(down(i,1:firstKeypoint),1,'last');
        tpDelocalised=upslopePosition+find(down(i,(upslopePosition):length(up(1,:))));
        
        if ~isempty(tpDelocalised) 
            filter_timeLocalised=[filter_timeLocalised (tpDelocalised-upslopePosition)];
        else
            filter_timeLocalised=[filter_timeLocalised 0];
        end%if
        
        if ~isempty(tpG1)
            filter_timesG1=[filter_timesG1 (upslopePosition-tpG1)];
        else
            filter_timesG1=[filter_timesG1 0];
        end%if
        
    else
        %add zeros to all fields
        filter_timeLocalised=[filter_timeLocalised 0];
        filter_timesG1=[filter_timesG1 0];

                    
    end
      
end
end