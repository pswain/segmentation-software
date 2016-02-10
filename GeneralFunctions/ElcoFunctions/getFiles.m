function [ filenames_cell ] = getFiles( directory,search_string,remove_dir,remove_clutter )
%[ filenames_cell ] = getFiles( directory,search_string,remove_dir,remove_clutter )
% uses regexp to find compare the names of the files with search_string. If
% you want only exact matches use ^string$

if nargin<2 || isempty(search_string) || ~ischar(search_string)
    
    search_string = '.*';
    
end

if nargin<3 || isempty(remove_dir) 
    
    remove_dir = true;
    
end


clutter = {'.' '..' '.DS_Store'};

if nargin<4 || isempty(remove_clutter) 
    
    remove_clutter = true;
    
end


directory_info = dir(directory);
names = {directory_info.name};
to_keep = ~cellfun('isempty',regexp(names,search_string));

if remove_dir
    
    to_keep = to_keep & ~[directory_info.isdir];
    
end

if remove_clutter
    
    to_keep = to_keep & cellfun(@(s) ~any(strcmp(s,clutter)),names);
    
end


filenames_cell = names(to_keep);

end

