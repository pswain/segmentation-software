function Timelapse = rmImageFileList(Timelapse,label)
% rmImageFileList     ---   removes entries from the ImageFileList property - a
%                           structure which is used to retrieve image files
%                           at various points in the program.
%
% Synopsis:                 Timelapse=rmImageFileList(Timelapse,label)
%
% Input:                    Timelapse = an object of a timelapse class
%                           label = the unique string which labels the
%                           channel to be removed.
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
%The 'moviedir' directory with indicator 'DIC' is labelled 'DICmain' and
%made the first entry of ImageFileList in the Timelapse3 constructor.


if isstruct(Timelapse.ImageFileList)&&isfield(Timelapse.ImageFileList,'label')&&any(strcmp(label,{Timelapse.ImageFileList(:).label}))
    
    
    Timelapse.ImageFileList(strcmp(label,{Timelapse.ImageFileList(:).label})) = [];
    
end

end