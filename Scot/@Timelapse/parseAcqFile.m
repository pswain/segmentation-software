function metaData=parseAcqFile(moviedir)
    % parseAcqFile --- returns information on a timelapse acquisition derived from an acq text file
    %
    % Synopsis:  metaData = parseAcqFile (moviedir)
    %                        
    % Input:     moviedir = string, full path of a folder containing a timelapse acquisition saved by the Swain lab microscope software
    % 
    % Output:   metaData = structure, carries the experiment information

    % Notes:  This is a static method - doesn't need a timelapse
    %         object. To run this refer to a Timelapse class
    %         - eg metaData=Timelapse1.parseAcqFile (moviedir)
    
    acqFile=dir(fullfile(moviedir,'*Acq*'));

    if length(acqFile)>1
    %determine which one is the text file and use that

    else
        acqFilename=[moviedir filesep acqFile.name];
    end
    
    
    acqFile=fopen(acqFilename);
    rawdataAcq=textscan(acqFile,'%s');
    rawdataAcq=rawdataAcq{:};
    %Now have access to the information in the Acq file
    
    %Find the positions of the category headings   
    a=strfind(rawdataAcq,'Channels:');
    chanHeading=find(not(cellfun('isempty', a)));%Index just before the channel list
    a=strfind(rawdataAcq,'Z_sectioning:');
    zHeading=find(not(cellfun('isempty', a)));%Index just beyond the channel list
    a=strfind(rawdataAcq,'Time_settings:');
    tHeading=find(not(cellfun('isempty', a)));%Index just beyond the channel list
    a=strfind(rawdataAcq,'Points:');
    pointHeading=find(not(cellfun('isempty', a)));%Index just beyond the channel list
    a=strfind(rawdataAcq,'Flow_control:');
    flowHeading=find(not(cellfun('isempty', a)));%Index just beyond the channel list

    
    %Loop through the channels getting their details.
    for ch=1:zHeading-chanHeading-1
        chPosition=chanHeading+ch;
        k=strfind(rawdataAcq(chPosition),',');
        k=k{:};
        thisChan=rawdataAcq(chPosition);
        thisChan=thisChan{:};
        metaData.channels(ch).name=thisChan(1:k(1)-1);
        metaData.channels(ch).exposure=str2double(thisChan(k(1)+1:k(2)-1));%Time in ms
        metaData.channels(ch).skip=str2double(thisChan(k(2)+1:k(3)-1));%Channel takes an image every nth timepoint
        metaData.channels(ch).zSectioning=logical(str2double(thisChan(k(3)+1:k(4)-1)));%true if this channel does z sectioning
        metaData.channels(ch).startingtimepoint=str2double(thisChan(k(4)+1:k(5)-1));%No images will be taken before this timepoint in this channel
        metaData.channels(ch).cameramode=str2double(thisChan(k(5)+1:k(6)-1));%1 if EM port with gain and exposure correction, 2 if CCD mode, 3 if EM with static gain and exposure 
        metaData.channels(ch).startgain=str2double(thisChan(k(6)+1:k(7)-1));%EM gain at the start of the experiment    
    end
    
    %Record the Z sectioning information
    z=rawdataAcq{zHeading+1};
    k=strfind(z,',');
    metaData.z.numSections=str2double((z(1:k-1)));
    metaData.z.sectionSpacing=str2double((z(k+1:end)));

    %Record the time information
    time=rawdataAcq{tHeading+1};
    k=strfind(time,',');
    metaData.time.istimelapse=logical(str2double((time(1:k(1)-1))));
    metaData.time.interval=str2double((time(k(1)+1:k(2)-1)));
    metaData.time.numTimepoints=str2double((time(k(2)+1:k(3)-1)));
    metaData.time.totalTime=str2double((time(k(3)+1:end)));
    
    %Record the position information
    for pos=1:flowHeading-pointHeading-1
       pointPosition=pointHeading+pos;
       k=strfind(rawdataAcq(pointPosition),',');
       k=k{:};
       thisPoint=rawdataAcq(pointPosition);
       thisPoint=thisPoint{:};
       metaData.points(pos).name=thisPoint(1:k(1)-1);
       metaData.points(pos).x=str2double(thisPoint(k(1)+1:k(2)-1));%stage x position (microns)
       metaData.points(pos).y=str2double(thisPoint(k(2)+1:k(3)-1));%stage y position (microns)
       metaData.points(pos).z=logical(str2double(thisPoint(k(3)+1:k(4)-1)));%z drive position (microns)
       metaData.points(pos).pfsoffset=str2double(thisPoint(k(4)+1:k(5)-1));%pfs offset
       metaData.points(pos).group=str2double(thisPoint(k(5)+1:end));%point group number
       %ADD MORE CODE HERE TO RECORD EXPOSURE TIMES FOR EACH CHANNEL IF
       %THEY HAVE BEEN RECORDED - FIRST CHECK THAT THIS INFORMATION IS
       %RECORDED IN THE ACQ FILE BY THE MICROSCOPE SOFTWARE      
    end

    
       %Record the flow information
       
       %THIS YET TO BE IMPLEMENTED
end