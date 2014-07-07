function timepointIm=returnSingleTimepoint(cTimelapse,timepoint,channel,type)

%Channel refers to the channel name. It access the channelNames property of
%timelapse and uses that to find the appropriate files. If there is more
%than DIC/GFP etc frame at the timepoint, it assuems it is a z-stack and
%returns the maximum projection of the stack.

%To maintain backwards compatability there is a section of the code that
%checks if a file name has file seperators in it and then changes the
%filename to not have separators in. Then makes the file from the
%timelapsedir and the filename. Sometimes this is not desirable, as such if
%timelapseDir is set to 'ignore' then this is not performed and simply the
%filename is used.

if nargin<3
    channel=1;
end

if nargin<4
    type='max';
end

tp=timepoint;
fileNum=regexp(cTimelapse.cTimepoint(timepoint).filename,cTimelapse.channelNames{channel},'match');
loc= ~cellfun('isempty',fileNum);
if sum(loc)>0
    file=cTimelapse.cTimepoint(timepoint).filename{loc};
    
    if ~strcmp(cTimelapse.timelapseDir,'ignore')
    
    locSlash=strfind(file,'/');
    
    if isempty(locSlash) 
        locSlash=strfind(file,'\'); %in case file was made on a windows machine
    end
    
    if locSlash
        inds=find(loc);
        for i=1:sum(loc)
            file=cTimelapse.cTimepoint(timepoint).filename{inds(i)};
            %locSlash=strfind(file,'/');
            file=file(locSlash(end)+1:end);
            cTimelapse.cTimepoint(timepoint).filename{inds(i)}=file;
        end
    end
    
    end

    try
        
        ind=find(loc);
        file=cTimelapse.cTimepoint(timepoint).filename{ind(1)};
        if strcmp(cTimelapse.timelapseDir,'ignore')
            ffile=file;
        else
            ffile=fullfile(cTimelapse.timelapseDir,file);
        end
        if ~isempty(cTimelapse.imSize)
            timepointIm=zeros([cTimelapse.imSize sum(loc)]);
            if strfind(ffile,'TIF')
                timepointIm=imread(ffile,'Index',1);
                timepointIm=timepointIm(:,:,1);
            else
                timepointIm(:,:,1)=imread(ffile);
            end
        else
            timepointIm=imread(ffile);
            cTimelapse.imSize=size(timepointIm);
        end
        for i=2:sum(loc)
            file=cTimelapse.cTimepoint(timepoint).filename{ind(i)};
            ffile=fullfile(cTimelapse.timelapseDir,file);
            timepointIm(:,:,i)=imread(ffile);
        end
        
        %change if want things other than maximum projection
        switch type
            case 'max'
                timepointIm=max(timepointIm,[],3);
            case 'stack'
                timepointIm=timepointIm;
        end
        
        
    catch
        folder =[];
        h=errordlg('Directory seems to have changed');
        uiwait(h);
        attempts=0;
        while isempty(folder) && attempts<3
            fprintf(['Select the correct folder for: \n',cTimelapse.timelapseDir '\n']);
            folder=uigetdir(pwd,['Select the correct folder for: ',cTimelapse.timelapseDir]);
            cTimelapse.timelapseDir=folder;
            attempts=attempts+1;
        end
        ind=find(loc);
        file=cTimelapse.cTimepoint(timepoint).filename{ind(1)};
        ffile=fullfile(cTimelapse.timelapseDir,file);
        if ~isempty(cTimelapse.imSize)
            timepointIm=zeros([cTimelapse.imSize sum(loc)]);
            timepointIm(:,:,1)=imread(ffile);
        else
            timepointIm=imread(ffile);
        end
        for i=2:sum(loc)
            file=cTimelapse.cTimepoint(timepoint).filename{ind(1)};
            ffile=fullfile(cTimelapse.timelapseDir,file);
            timepointIm(:,:,i)=imread(ffile);
        end
        timepointIm=max(timepointIm,[],3);
    end
else
    if cTimelapse.imSize
        timepointIm=zeros(cTimelapse.imSize);
    else
                file=cTimelapse.cTimepoint(timepoint).filename{1};
        ffile=fullfile(cTimelapse.timelapseDir,file);
        timepointIm=imread(ffile);
        timepointIm(:,:)=0;
        cTimelapse.imSize=size(timepointIm);
    end
    disp('There is no data in this channel at this timepoint');
end

if isempty(cTimelapse.imSize) %set the imsize property if it hasn't already been set
            cTimelapse.imSize = size(timepointIm);
end
        
% try
%     timepoint=imread(cTimelapse.cTimepoint(timepoint).filename{channel});
% catch
%     timepoint=imread(cTimelapse.cTimepoint(timepoint).filename{1});
%     timepoint(:,:)=0;
%     warning('There is no data in this channel at this timepoint');
% end
%
if ~isempty(cTimelapse.imScale)
    timepointIm=imresize(timepointIm,cTimelapse.imScale);
end

if isfield(cTimelapse.cTimepoint(tp),'image_rotation') & ~isempty(cTimelapse.cTimepoint(tp).image_rotation)
    image_rotation=cTimelapse.cTimepoint(tp).image_rotation;
else
    image_rotation=cTimelapse.image_rotation;
end

if image_rotation~=0
    timepointIm=imrotate(timepointIm,image_rotation,'bilinear','loose');
end

if size(cTimelapse.BackgroundCorrection,2)>=channel && ~isempty(cTimelapse.BackgroundCorrection{channel})
    %first part of this statement is to guard against cases where channel
    %has not been assigned
    timepointIm = timepointIm.*cTimelapse.BackgroundCorrection{channel};
end

if size(cTimelapse.offset,1)>=channel && any(cTimelapse.offset(channel,:)~=0)
    %first part of this statement is to guard against cases where channel
    %has not been assigned
    tempIm=zeros(size(timepointIm));
    for sliceNum=1:size(timepointIm,3)
        TimepointBoundaries = fliplr(cTimelapse.offset(channel,:));
        timepointIm = padarray(timepointIm,abs(TimepointBoundaries));
        LowerTimepointBoundaries = abs(TimepointBoundaries) + TimepointBoundaries +1;
        HigherTimepointBoundaries = cTimelapse.imSize + TimepointBoundaries + abs(TimepointBoundaries);
        tempIm(:,:,sliceNum) = timepointIm(LowerTimepointBoundaries(1):HigherTimepointBoundaries(1),LowerTimepointBoundaries(2):HigherTimepointBoundaries(2),sliceNum);
    end
    timepointIm=tempIm;
end
% 
% if channel==2
%     timepointIm=flipud(timepointIm);
% end
