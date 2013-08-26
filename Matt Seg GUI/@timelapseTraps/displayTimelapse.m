function displayTimelapse(cTimelapse, channel, pause_duration)


%% This displays a timelapse video through time
if nargin <2
    channel=1;
end

if nargin <3
    pause_duration=.05;
end

figure(1);
image=cTimelapse.returnSingleTimepoint(1,channel);
h=imshow(image,[]);title(['Timepoint ' int2str(1)]);

for i=1:length(cTimelapse.cTimepoint)
    image=cTimelapse.returnSingleTimepoint(i,channel);
    set(h,'Cdata',image)
    pause(pause_duration);
end
