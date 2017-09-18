function timepointIm=returnSingleTimepointRaw(cTimelapse,timepoint,channel)
% timepointIm = returnSingleTimepointRaw(cTimelapse,timepoint,channel)
%
% returns the raw image stack before corrections (rescaling, shifting,
% background correction,projection) are made. Intended as a background
% function, generally better to use TIMELAPSETRAPS.RETURNSINGLETIMEPOINT
%
% Important to note that in the case of numerous 'stack' channels this will
% return a stack, as oppose to TIMELAPSETRAPS.RETURNSINGLETIMEPOINT which
% generally returns a projected image.
%
% This is the omero version, so the image is downloaded from the omero
% database using Ivan's Omero code.
%
% See also TIMELAPSETRAPS.RETURNSINGLETIMEPOINT,


if iscell(cTimelapse.channelNames)
    channelName=cTimelapse.channelNames{channel};
else
    channelName=cTimelapse.channelNames;
end

if isempty (cTimelapse.OmeroDatabase.Session)
    cTimelapse.OmeroDatabase.login;
end
done=false;
while done==false
    try
        [store, pixels] = getRawPixelsStore(cTimelapse.OmeroDatabase.Session, cTimelapse.omeroImage);
        done=true;
    catch err
        cTimelapse=cTimelapse.OmeroDatabase.login;
        %server may be busy
        disp(err.message);
        done=false;
    end
end
sizeZ = pixels.getSizeZ().getValue(); % The number of z-sections available for this channel
sizeX = pixels.getSizeX().getValue(); % The number of pixels along the X-axis.
sizeY = pixels.getSizeY().getValue(); % The number of pixels along the Y-axis.
sizeC = pixels.getSizeC().getValue(); % The number of channels


if any(strcmp(channelName,cTimelapse.microscopeChannels))
    zsections = 1:sizeZ;
else
    zstring = regexp(channelName,'_(.*)$','tokens');
    channelName = regexprep(channelName,'_.*$','');
    if ~isempty(zstring)
        zsections = str2double(zstring{1});
    else
        zsections =1;
    end
end

posinfo = cTimelapse.metadata.acq.positions;
posInd = find(strcmp(posinfo.name,cTimelapse.metadata.posname),1);
exposureTimes = table2struct(posinfo(posInd,7:end));
chNames = fieldnames(exposureTimes);
chNames = chNames(structfun(@(x) x>0, exposureTimes));
chNum = find(strcmp(channelName,chNames));

for zi=1:length(zsections)
    z = zsections(zi);
    folderName=[cTimelapse.OmeroDatabase.DownloadPath filesep char(cTimelapse.omeroImage.getName.getValue)];
    if exist(folderName)==0
        mkdir(folderName);
    end
    %Generate a filename based on the channel, timepoint and z section.
    fileName=[folderName filesep 'omeroDownload_' sprintf('%06d',timepoint) '_Channel',num2str(chNum) '_' sprintf('%03d',z),'.png'];
    
    
    %Get the image from the Omero Database - if it exists for this
    %channel and timepoint
    try
        if ~isempty(chNum) && chNum<=sizeC && z<=sizeZ
            plane=store.getPlane(z-1, chNum-1, timepoint-1);
            tempIm = toMatrix(plane, pixels)';
        else %This position does not have this channel - return a black image
            tempIm=uint16(zeros(sizeY,sizeX));
        end            
        %cache the plane to make retrieval faster next time - this
        %doesn't work very well hence commented - need a better way
        %to speed up image browsing
        %imwrite(toMatrix(plane, pixels)', fileName);           
    catch
        %Fix upload script to prevent the need for this debug
        disp('No plane for this section channel and timepoint, return equivalent image from the previous timepoint - prevents bugs in segmentation');
        plane=store.getPlane(z-1, chNum-1, timepoint-2);
        tempIm = toMatrix(plane, pixels)';       
        timepoint=timepoint-1;
    end
    
    %Images are flipped in both directions on Omero upload - so if the
    %data was segmented from a folder before being uploaded/converted
    %then it should be flipped to ensure data is consistent with any
    %segmentation results
    if strcmp(cTimelapse.segmentationSource,'Folder')
        tempIm=rot90(tempIm);
        tempIm=flipud(tempIm);
    end
    if zi ==1
        timepointIm=zeros([sizeY, sizeX, length(zsections)],'like',tempIm);
    end    
    timepointIm(:,:,zi) = tempIm;
    
end
store.close();
if isempty(cTimelapse.rawImSize)
    cTimelapse.rawImSize = [size(timepointIm,1),size(timepointIm,2)];
end

end
