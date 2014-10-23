function new=addTimepoints(cTimelapse)

%% Read images into timelapse class
% Timelapse is a seletion of images from a file. These images must be
% loaded in the correct order from low to high numbers to ensure that the
% cell tracking performs correctly, and they must be rotated to ensure the
% trap correctly aligns with the images

tooSoon=true;
while tooSoon
    folder=cTimelapse.timelapseDir;
    tempdir=dir(folder);
    names=cell(1);
    timeDif=[];
    for i=1:length(tempdir)
        names{i}=tempdir(i).name;
        timeDif(i)=now-tempdir(i).datenum;
    end
    if min(timeDif)>.0005
        tooSoon=false;
    else
        tooSoon=true;
    end
    pause(5);
end

files=sort(names);

timepoint_index=0;
folder=[folder '/'];
% cTimelapse=cell(1)
for i=1:length(cTimelapse.cTimepoint)
    pattern='\d{5,9}';%CHANGE BACK TO {5,6}!!!!!!!!!
    fileNum=regexp(cTimelapse.cTimepoint(i).filename{1},pattern,'match');
    
    for j=1:length(cTimelapse.channelNames)
        match1=regexp(files(:),fileNum{end},'match');
        match2=regexp(files(:),cTimelapse.channelNames{j},'match');
        loc1= ~cellfun('isempty',match1);
        loc2= ~cellfun('isempty',match2);
        loc=loc1&loc2;
        files(loc)=[];
    end

    
%     
%     for j=1:length(cTimelapse.channelNames)
%         p1=[fileNum{1} '_' cTimelapse.channelNames{j}];
%         match=regexp(files(:),p1,'match');
%         loc= ~cellfun('isempty',match);
%         files(loc)=[];
%     end
end

new=false;
if ~isempty(files)
    pattern='\d{5,9}';%CHANGE BACK TO {5,6}!!!!!!!!!
    fileNum=regexp(files,pattern,'match');
    loc= ~cellfun('isempty',fileNum);
    for i=1:length(loc)
        if loc(i)
            if length(fileNum{i}{1})>8
                timepointNum=str2num(fileNum{i}{1})+1;
            else
                timepointNum=str2num(fileNum{i}{1});
            end
            match=regexp(files{i},cTimelapse.channelNames,'match');
            channelLoc=~cellfun('isempty',match);
            
            if any(channelLoc)
                fluor=find(channelLoc);
                cTimelapse.cTimepoint(timepointNum).filename{fluor}=files{i};
                new=true;
            end
        end
    end
end


