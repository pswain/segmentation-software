function loadChannelIntoMemory(cTimelapse,channel)
% loadChannelIntoMemory(cTimelapse, channel)
%
% this loads the entire channel for a single position into memory. This is
% especially helpful when manually annotating birth events in the
% cellResultsViewingGUI as it makes scrolling smoother. It could also be
% used for tracking and editting the segmentation. returnTimepoint now
% checks to see if that channel is loaded into memory before reading it in
% from the hard drive.
%
%. Accepts the option
% channel                   : integer with the channel to be loaded into memory
%
% Modifies cTimelapse.temporaryImageStorage
% with fields:
% channels                  : channel currently loaded into memory
%
% images                     : 3D matrix with all timepoints of the current
%                             channel loaded into memory. XYZ where z is the tp



if ~isfield(cTimelapse.temporaryImageStorage,'channel')
    loadIn=true;
elseif channel ~= cTimelapse.temporaryImageStorage.channel
    loadIn=true;
else
    loadIn=false;
end

if loadIn
    h1 = warndlg('Going to load next dataset ... may take a minute');  
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

    try
        close(h);
    end
    try
    close(h1);
    end

end



