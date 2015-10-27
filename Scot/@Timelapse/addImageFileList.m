function [Timelapse index]= addImageFileList(Timelapse,label,directory,identifier, sections)
% addImageFileList    ---   adds entries to the ImageFileList property - a
%                           structure which is used to retrieve image files
%                           at various points in the program.
%
% Synopsis:                 Timelapse=addImageFileList(Timelapse,label,directory,identifier)
%
% Input:                    timelapse = an object of a timelapse class
%                           label = a string which is a unique label for that channel.
%                           directory = the directory in which the images for that channel are stored.
%                           identifier = string which occurs in the files of that channel and NOT in any other filenames in that directory.
%                           
%           
%
% Output:                   Timelapse = an object of a timelapse class

%Notes: Timelapse.ImageFileList is a structure array with an entry for each
%channel of interest. the fields of the structure are:
% label         -- a unique string which identifies the channel
% file_details  -- a structure array containing an entry for each file
%                  associated to the channel. This is the output os the dir
%                  file and has the fields:
%         name    -- Filename
%         date    -- Modification date
%         bytes   -- Number of bytes allocated to the file
%         isdir   -- 1 if name is a directory and 0 if not
%         datenum -- Modification date as a MATLAB serial date number.
%                    This value is locale-dependent.
% identifier    -- a string which is used to find files associated with the
%                  channel. It should be a string that occurs in files
%                  associated with the channel and does not occur in any
%                  files not associated with the channel in the directory
%                  'directory'
% directory     -- a string giving the directory in which the files
%                  associated with the channel are found.

%Clear any existing entries for this identifier
for n=1:length(Timelapse.ImageFileList)
   if strcmp(Timelapse.ImageFileList(n).identifier,identifier)
       Timelapse.ImageFileList(n)=[];
       break;
   end    
end
allfile_details=dir(fullfile(directory,['*' identifier '*']));
timepoints=size(allfile_details,1)/sections;
%Check timepoints is an integer here and if not, return with error
if rem(timepoints,1) ~=0%timepoints is not an integer
    error('Number of files is not a multiple of input number of sections. Please check the identifier string');
end

for t=1:timepoints
    file_details(t).timepoints=allfile_details((t*sections)+1-sections:t*sections);
end



temp = struct('label',label,'file_details',file_details,...
                                'directory',directory,'identifier',identifier);

if isstruct(Timelapse.ImageFileList)
    
    if any(strcmp(label,{Timelapse.ImageFileList(:).label}))
        %The label is already present - return the index to the label
        index=find(strcmp(label,{Timelapse.ImageFileList(:).label}));
    else
        
        Timelapse.ImageFileList = [Timelapse.ImageFileList temp];
        index=size(Timelapse.ImageFileList,2);
        
    end
    
    
    
else
    Timelapse.ImageFileList = temp;
    index=1;
end

if strcmp('main', label)%These are the images to be used for segmentation - record the index to these entries in the timelapse
    Timelapse.Main=index;
end


end