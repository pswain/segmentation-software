function image = getimage(Timelapse,timepoint,channel_label)
% getImage  --- retrieves an image from the appropriate  timepoint with
%               appropraite identifier
%
% Synopsis:  image = getimage(Timelapse,timepoint,identifier)
%
% Input:     Timelapse = an object of the Timelapse class
%            timepoint = an integer timepoint channel_label = the unique
%            string used to identify the channel in the
%            Timelapse.ImageFileList property. It is given when the
%            entry is added using addImageFileList method. for the main
%            DIC image stack it is 'DICmain'

% Output:    image = the desired image

% Notes:     This method retrieves an image from the hard disk which is
%            in the Timelapse.ImageFileList


if timepoint<= Timelapse.TimePoints
    
    look = strcmp(channel_label,{Timelapse.ImageFileList(:).label}); %logical giving the location in ImageFileList of the channel
    
    if any(look)
        image = imread(strcat(Timelapse.ImageFileList(look).directory,'/',Timelapse.ImageFileList(look).file_details(timepoint).name));
    else
        
        fprintf('\n \nTimelapse.ImageFileList labels are: \n')
        disp(Timelapse.ImageFileList(:).label)
        error('requested channel is not in the Timelapse.ImagefileList. Ensure that addImageFileList has been used to populate the property.')
    end
    
else
    error('timepoint is larger than the highest timepoint in the image sequence')
    
end

end

