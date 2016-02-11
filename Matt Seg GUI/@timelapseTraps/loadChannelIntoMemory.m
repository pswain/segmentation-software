function loadChannelIntoMemory(cTimelapse,channel)

if channel ~= cTimelapse.temporaryImageStorage.channel
    h = waitbar(0,'Please wait as the channel is loaded ...');

    cTimelapse.temporaryImageStorage.channel=channel;
    cTimelapse.temporaryImageStorage.images=cTimelapse.returnSingleTimepoint(1,channel);
    maxTP=length(cTimelapse.timepointsProcessed);
    for timepoint=2:maxTP;
        waitbar(timepoint/maxTP);
        if timepoint>1
            cTimelapse.temporaryImageStorage.images(:,:,2:maxTP) = 0;
        end
        cTimelapse.temporaryImageStorage.images=cTimelapse.returnSingleTimepoint(timepoint,channel);
    end
    
    close(h);
end



