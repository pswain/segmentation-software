function new=addTimepoints(cTimelapse,image_acquire_time_wait)
% new=addTimepoints(cTimelapse,image_acquire_time_wait)
%
% method to search cTimelapse.timelapseDir for new images currently not
% included in the cTimelapse and add them to the filename field. This will
% add new timpoints to the cTimelapse.cTimepoints array in accordance with
% the usual file format.
% 
% only updates filenames, not timepointsToProcess or timepointsProcessed.
% 
% has one optional input - image_acquire_time_wait. Time in seconds it
%                          should enforce between an image being saved and
%                          it being added to the cTimelapse. This is to try
%                          and ensure images are not added in the middle of
%                          a z stack, and should be longer than the
%                          interslice perioud but much shorter than the
%                          inter timepoint period. Given in seconds.
%                          Default is 10.
%
% returns:
% new       -   boolean. true if any new images were added.

% time to wait after image acquisition before program is allowed to update
% the cTimelapse object.
% should be significantly larger than the time between slices but not as
% large as the time between points. Given in seconds
if nargin<2 || isempty(image_acquire_time_wait)
    image_acquire_time_wait = 10;
end

tooSoon=true;
while tooSoon
    folder=cTimelapse.timelapseDir;
    tempdir=dir(folder);
    
    names = {tempdir(:).name};
    timeDif = now - [tempdir(:).datenum];
    
    % in timeDif, 1 seconds is approximately 1.1608e-05
    if (min(timeDif)/1.1608e-05)>image_acquire_time_wait
        tooSoon=false;
    else
        tooSoon=true;
    end
    pause(5);
end

files=sort(names);

files_already_added = [cTimelapse.cTimepoint(:).filename];
files = setdiff(files,files_already_added);

new=false;
if ~isempty(files)
    pattern='\d{5,9}';
    fileNum=regexp(files,pattern,'match');
    loc= ~cellfun('isempty',fileNum);
    for i=1:length(loc)
        if loc(i)
            
            %have left this here since it seems important but I'm not sure
            %why it is necessary, so have commented it.
            
%             if length(fileNum{i}{1})>8
%                 timepointNum=str2num(fileNum{i}{1})+1;
%             else
%                 timepointNum=str2num(fileNum{i}{1});
%             end
            timepointNum=str2num(fileNum{i}{1});
            match=regexp(files{i},cTimelapse.channelNames,'match');
            channelLoc=~cellfun('isempty',match);
            
            if timepointNum>length(cTimelapse.cTimepoint)
                cTimelapse.cTimepoint(timepointNum) = cTimelapse.cTimepointTemplate;
            end
            
            if any(channelLoc)
                cTimelapse.cTimepoint(timepointNum).filename{end+1}=files{i};
                new=true;
            end
        end
    end
end


