function AddAllPositions(StackComp, varargin)
%AddAllPositions(StackComp, varargin{ParentDirectory,Identifier}) method to
%take a directory and add all the folders of the form pos# with the same
%identifier.

if nargin>1
    Folder = varargin{1};
else
    fprintf('please select the directory containing the position directories \n');
    Folder=uigetdir(StackComp.DefaultDirectory,'please select the directory containing images');
end

if nargin>2
    Identifier = varargin{2};
else
    Identifier = inputdlg({'identifier:'},'please select an identifier to identify images in these stacks ',1,{'_GFP_'});
    
    Identifier = Identifier{1};
end




FolderContents = dir(Folder);
FileNames = {FolderContents.name};
IsDirectory = [FolderContents.isdir];
IsPos = ~cellfun('isempty',regexp(FileNames,['.*pos+\d']));
IsPos = IsPos & IsDirectory;

PositionsToAdd = {FolderContents(IsPos).name};


for positioni = 1:length(PositionsToAdd)
    
    StackComp.AddEntry(fullfile(Folder,PositionsToAdd{positioni}),Identifier);
    

end

