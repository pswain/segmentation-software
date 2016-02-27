function loadChannelIntoMemory(cTimelapse,channel)

if ~isfield(cTimelapse.temporaryImageStorage,'channel')
    loadIn=true;
elseif channel ~= cTimelapse.temporaryImageStorage.channel
    loadIn=true;
else
    loadIn=false;
end

if loadIn
    h = waitbar(0,'Please wait as the channel is loaded ...');

    cTimelapse.temporaryImageStorage.images=uint8(cTimelapse.returnSingleTimepoint(1,channel));
    maxTP=length(cTimelapse.timepointsProcessed);
    if maxTP>1
        cTimelapse.temporaryImageStorage.images(:,:,2:maxTP) = 0;
    end
    
    for timepoint=2:maxTP;
        waitbar(timepoint/maxTP);
        cTimelapse.temporaryImageStorage.images(:,:,timepoint)=uint8(cTimelapse.returnSingleTimepoint(timepoint,channel));
    end
    
    cTimelapse.temporaryImageStorage.channel=channel;

    close(h);
end



