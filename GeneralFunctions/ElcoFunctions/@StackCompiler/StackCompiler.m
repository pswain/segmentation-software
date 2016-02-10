classdef StackCompiler < handle
    %A parent class of all things that involve manipulating
    %numerous sets of stack of images.
     
    properties
        
        Directories % the directory of each successive image stack
        Identifiers  % the identifier used in the regular expressions to identify the images that are part of the image stack
        DefaultDirectory % the default directory in which the program points you to pick new entries.
        Comment %any comment on the nature of the stacks being stored
        
        
    end
    
    methods
        
        function Self = StackCompiler()
            Self.Directories = {};
            Self.Identifiers = {};
            fprintf('please select a default directory to which you will be directed whenever selecting a new entry \n');
            Self.DefaultDirectory = uigetdir(pwd,'please select a default directory to which you will be directed whenever selecting a new entry');
        end
        
        function StackComp = AddEntry(StackComp,varargin)
            % StackCompiler = AddEntry(StackCompiler,varargin) adds a new
            % entry to the StackCompiler. optional inputs are 
            % varargin{1}   -   Folder: the directory to add (i.e. where images in the stack are stored).
            % varargin{2}   -   Identifier: the Identifier used to identify images in the stack. Done via regexp
            

            
            if nargin>1
                Folder = varargin{1};
            else
                fprintf('please select the directory containing images \n');
                Folder=uigetdir(StackComp.DefaultDirectory,'please select the directory containing images');
            end
            
            DirectoryInfo = dir(Folder);
            
            if nargin>2
                Identifier = varargin{2};
            else
                Identifier = inputdlg({'identifier:'},'please select an identifier to identify images in this stack ',1,{DirectoryInfo(5).name});
            
                Identifier = Identifier{1};
            end
            StackComp.Directories{end+1} = Folder;
            StackComp.Identifiers{end +1} = Identifier;

        end
        
        function StackCompiler = RemoveEntries(StackCompiler,EntriesToRemove)
            %StackCompiler = RemoveEntries(StackCompiler,EntriesToRemove)
            %remove entries from the stack.
            StackCompiler.Directories(EntriesToRemove) = [];
            StackCompiler.Identifiers(EntriesToRemove) = [];
        end

       
    end
    
end

