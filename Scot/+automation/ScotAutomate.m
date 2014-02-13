classdef ScotAutomate
    properties
        TargetPaths%Cell array (vector) of strings, paths to the data to process
        OutputPaths%Cell array (vector) of strings, full paths to the filenames to which data is to be saved
        MethodStruct=struct('methodObj',{},'packagename',{},'methodname',{},'parameters',{})%Structure array, with details of the methods to be applied to the data. Fields: methodObj, parameters
        AddPathButton
        DeletePathButton
        ReturnButton
        CancelButton
        Dialog
        PathList
        TargetType%string, denotes type of input to TargetPaths: 'file.ext' (where ext is a file extension), 'file' for any file, or 'folder' for a directory 
    end
    
    properties (Access=private)
        AddCallback;
        DeleteCallback;
        ReturnCallback;
        CancelCallback;
    end
    
    methods
        function obj=getTargetPaths(obj)
            % getTargetPaths --- Populates the TargetPaths field of a ScotAutomate object
            %
            % Synopsis:  obj = getTargetPaths (obj)
            %
            % Input:     obj = an object of a ScotAutomate subclass
            %
            % Output:     obj = an object of a ScotAutomate subclass

            % Notes:    Used by automation objects to get a list of paths
            %           to targets for automated tasks. This is done by
            %           user input but could be extended to allow other
            %           methods - eg - select all images in an Omero
            %           dataset.
            obj.Dialog=figure('Units','Normalized','Position',[.3327 .4932 .2 .3],'MenuBar','None', 'NumberTitle', 'Off', 'Name', 'Scot Automation - select target paths');
            %obj.Dialog=figure('Units','Normalized','Position',[.3327 .4932 .2 .3],'MenuBar','None', 'NumberTitle', 'Off', 'Name', 'Scot Automation - select target paths','WindowStyle','Modal');
            obj.PathList=uicontrol('Parent',obj.Dialog,'Style','listbox','Units', 'normalized','Position',[0 0 1 .8],'String',obj.TargetPaths,'HorizontalAlignment', 'Left');
            obj.AddPathButton=uicontrol('Parent',obj.Dialog,'Style','pushbutton','Units', 'normalized','Position',[0 .8 .22 .1],'String','Add','HorizontalAlignment', 'Left', 'TooltipString','Click to add a path to be processed','Callback', {@(src, event)addPath(obj, src, event)});
            obj.DeletePathButton=uicontrol('Parent',obj.Dialog,'Style','pushbutton','Units', 'normalized','Position',[.22 .8 .22 .1],'String','Delete','HorizontalAlignment', 'Left', 'TooltipString','Click to delete the selected path','Callback',{@(src, event)deletePath(obj, src, event)});
            obj.ReturnButton=uicontrol('Parent',obj.Dialog,'Style','pushbutton','Units', 'normalized','Position',[.44 .8 .22 .1],'String','Done','HorizontalAlignment', 'Left', 'TooltipString','Click to finish creating path list','Callback',{@(src, event)returnDialogue(obj,src, event)});
            obj.CancelButton=uicontrol('Parent',obj.Dialog,'Style','pushbutton','Units', 'normalized','Position',[.66 .8 .22 .1],'String','Cancel','HorizontalAlignment', 'Left', 'TooltipString','Click to finish and ignore all changes to path list','Callback',{@(src, event)cancelDialogue(obj, src, event)});
            h.originalPaths=obj.TargetPaths;
            h.currentPaths=obj.TargetPaths;
            h.obj=obj;
            guidata(obj.Dialog,h);
            uiwait(obj.Dialog);
            h=guidata(obj.Dialog);
            obj.TargetPaths=h.obj.TargetPaths;
            close(obj.Dialog);


        end
        function obj=addPath(obj,src,event)
            % addPath --- Adds a new path to the TargetPaths list
            %
            % Synopsis:  obj = addPath (hObject, eventdata)
            %
            % Input:     
            %
            % Output:     obj = an object of a ScotAutomate subclass

            % Notes:    Used by the gui created in the getTargetPaths
            %           method to add a new path to the TargetPaths list.
            h=guidata(src);
            obj.TargetPaths=h.currentPaths;
            if strncmp(obj.TargetType,'file',4)
                if length(obj.TargetType)>4
                    s=['*' obj.TargetType(5:end)];
                else
                    s='';
                end
                if ~isempty(obj.TargetPaths)
                    [fileName path]=uigetfile(s,'Batch input file selection',obj.TargetPaths{1});
                else
                    [fileName path]=uigetfile(s,'Batch input file selection');
                end
                    fullPath=[path fileName];
            else
                if ~isempty(obj.TargetPaths)
                    fullPath=uigetdir('Batch input file selection',obj.TargetPaths{1});
                else
                    [fileName path]=uigetfile('Batch input file selection');
                end
                    fullPath=[path fileName];
            end
            if ischar(fullPath)%ie the obj.Dialogue has not been cancelled
                obj.TargetPaths{end+1}=fullPath;
                h.currentPaths=obj.TargetPaths;
                h.obj=obj;
                set(obj.PathList,'String',obj.TargetPaths);            
            end            
            guidata(src,h);
        end
        function deletePath(obj,src,event)
            % deletePath --- Removes a path from the TargetPaths list
            %
            % Synopsis:  obj = removePath (obj, hObject, eventdata)
            %
            % Input:     
            %
            % Output:     obj = an object of a ScotAutomate subclass

            % Notes:    Used by the gui created in the getTargetPaths
            %           method to delete a path from the TargetPaths list.
            h=guidata(src);
            obj.TargetPaths=h.currentPaths;
            paths=get(obj.PathList,'String');
            value=get(obj.PathList,'Value');
            path=paths{value};
            ind=strcmp(obj.TargetPaths,path);
            obj.TargetPaths(ind)=[];
            h.currentPaths=obj.TargetPaths;
            set(obj.PathList,'String',obj.TargetPaths);        
            guidata(src,h);

        end
        
        
        function obj=returnDialogue(obj,src,event)
            h=guidata(src);
            uiresume;
        
        
        end
    end
    
end