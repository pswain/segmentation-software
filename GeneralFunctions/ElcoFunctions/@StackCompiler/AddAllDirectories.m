function AddAllDirectories(StackComp, Folder,Identifier,Select)
%AddAllPositions(StackComp, varargin{ParentDirectory,Identifier}) method to
%take a directory and add all the folders that are not hidden with the same
%identifier.

if nargin<2 || isempty(Folder)

    fprintf('please select the directory containing the position directories \n');
    Folder=uigetdir(StackComp.DefaultDirectory,'please select the directory containing images');
end

if nargin<3 || isempty(Identifier)

    Identifier = inputdlg({'identifier:'},'please select an identifier to identify images in these stacks ',1,{'_GFP_'});
    
    Identifier = Identifier{1};
end

if nargin<3 || isempty(Select)

   Select = false;
   
end



FolderContents = dir(Folder);
IsDirectory = [FolderContents.isdir];
FileNames = {FolderContents.name};
IsNotHidden = cellfun('isempty',regexp(FileNames,'\..*'));
DirectorysToAdd = {FolderContents(IsDirectory & IsNotHidden).name};


if Select
    
    [Selected,OKorCancel] = listdlg('PromptString','Select directories to be added:',...
                                    'SelectionMode','multiple',...
                                    'ListString',DirectorysToAdd,...
                                    'InitialValue',1:length(DirectorysToAdd),...
                                    'OKString','add',...
                                    'ListSize',[320 300]);

    if OKorCancel    

        DirectorysToAdd = DirectorysToAdd(Selected);
    else
        DirectorysToAdd = {};

    end
end



for directoryi = 1:length(DirectorysToAdd)
    
    StackComp.AddEntry(fullfile(Folder,DirectorysToAdd{directoryi}),Identifier);
    

end

