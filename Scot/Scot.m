function timelapseObj = Scot (varargin)
    % Scot --- Launch function for timelapse segmentation, editing and analysis
    %
    % Synopsis:  timelapseObj = Scot()
    %            timelapseObj = Scot(moviedir)
    %
    %            timelapseObj = Scot(timelapseObj)
    %            timelapseObj = Scot(moviedir)
    %            timelapseObj = Scot(moviedir, interval)
    %            timelapseObj = Scot(moviedir, interval, identifier)    %           
    %                        
    % Input:     moviedir = string, path to a folder containing timelapse images to be segmented
    %            timelapseObj = an object of a timelapse class, already segmented
    %            moviedir = string, full path to a directory in which timelapse images are stored
    %            identifier = string present in the filenames of one image per timelapse frame

    %
    % Output:    timelapseObj = an object of class Timelapse1 or Timelapse3, segmented and tracked timelapse data set

    % Notes: Scot = Single Cells Over Time. Launches timelapse segmentation
    %               or editing. If no timelapse object is input, sets up
    %               GUI for initial timelapse segmentation. If a timelapse
    %               object is entered, sets up GUI for timelapse editing
    %               and data extraction
    
    disp('Single Cells Over Time - Timelapse segmentation, tracking and data extraction software.');
    
    if nargin==3
    	newSegmentation(varargin{1}, varargin{2}, varargin{3});
    else
        
    disp('Preparing path...');
    %Add the GUI and Fiji folders to the Matlab path
    thispath=mfilename('fullpath');
    k=strfind(thispath, filesep);
    addpath(genpath(thispath(1:k(end))));
    %GUIpath=[thispath(1:k(end)) 'GUI'];
    %addpath(GUIpath);
    %fijiPath=[thispath(1:k(end)) 'Fiji.app' filesep 'scripts'];
    %addpath(fijiPath);
    %Start Fiji
    disp('Starting Fiji...');
    Miji;
    
    %Check input variables
    if nargin>0 && isa (varargin{1},'Timelapse')
        %A timelapse has been entered - set up GUI for timelapse editing
        editSegmentation(varargin{1});
        return
    else
        %Set default values
        h.moviedir='';
        h.interval=5;
        h.identifier='DIC';
       
    end
    %replace with inputs
    if nargin>0
        h.moviedir=varargin{1};
        if nargin>1
            h.interval=varargin{2};
            if nargin>2
                h.identifier=varargin{3};
            end
        end
    end         
 
    %Display dialogue that will allow loading of saved datasets or
    %defining a file or folder containing images to segment.
    introDialog=figure('Units','Normalized','Position',[.3327 .4932 .2 .3],'MenuBar','None', 'NumberTitle', 'Off', 'Name', 'Single Cells Over Time - Set up','WindowStyle','Modal');
    load=uicontrol('Parent',introDialog,'Style','pushbutton','Units', 'normalized','Position',[.02 .53 .3 .2],'String','Load timelapse','HorizontalAlignment', 'Left', 'TooltipString','Click here to load a saved timelapse dataset','Callback',{@loadinitial});
    getFolder=uicontrol('Parent',introDialog,'Style','pushbutton','Units', 'normalized','Position',[.35 .53 .3 .2],'String','Enter folder','HorizontalAlignment', 'Left', 'TooltipString','Choose a folder containing the image files of your timelapse experiment','Callback',{@getfolder});
    getInterval=uicontrol('Parent',introDialog,'Style','edit','Units', 'normalized','Position',[.02 .22 .2 .15],'String',num2str(h.interval),'HorizontalAlignment', 'Left', 'TooltipString','Enter the time interval in minutes between frames of your experiment','Callback',{@getinterval});
    getIdentifier=uicontrol('Parent',introDialog,'Style','edit','Units', 'normalized','Position',[.35 .22 .3 .15],'String',h.identifier,'HorizontalAlignment', 'Left', 'TooltipString','Enter a string that is present in the target images that will be used for segmentation. This should occur in the filename of only one image per frame of your timelapse','Callback',{@getidentifier});
    rungui=uicontrol('Parent',introDialog,'Style','pushbutton','Units', 'normalized','Position',[.68 .53 .3 .2],'String','Segment','HorizontalAlignment', 'Left', 'TooltipString','Click here to set up timelapse segmentation','Callback',{@runmaingui});
    uicontrol('Parent',introDialog,'Style','text','Units','Normalized', 'Position',[.02 .45 .28 .05],'String','Frame interval (min)','BackgroundColor',get(introDialog,'Color'));
    uicontrol('Parent',introDialog,'Style','text','Units','Normalized', 'Position',[.35 .39 .3 .13],'String','Filenames of target images contain...','BackgroundColor',get(introDialog,'Color'));
    h.dirname=uicontrol('Parent',introDialog,'Style','text','String',h.moviedir,'Units','Normalized','Position',[.03 .75 .97 .25],'HorizontalAlignment','Left','BackgroundColor',get(introDialog,'Color'));
    h.infobox=uicontrol('Parent',introDialog,'Style','text','String','Load segmented timelapse, or define folder, time interval and main images for new timelapse segmentation','Units','Normalized','Position',[.05 .03 .9 .15]);
    guidata(gcf, h)
    end
    
end
        
    
    
    
    
    function timelapseObj = loadinitial(source, eventdata)
        [FileName,PathName,FilterIndex] = uigetfile('*.sct','Load timelapse dataset');
        if FileName~=0           
            showMessage('Loading timelapse data set...');
            timelapseObj=Timelapse1.loadTimelapse([PathName FileName]);
            close (get(source,'Parent'));
            editSegmentation(timelapseObj);
        else
            showMessage('No file loaded');
            return;
        end
    end


    function moviedir = getfolder(source, eventdata)
        h=guidata(get(source,'Parent'));
        moviedir = uigetdir('Select folder', 'Choose folder containing timelapse image data');
        if moviedir~=0           
            h=guidata(get(source,'Parent'));
            h.moviedir=moviedir;
            set(h.dirname,'String',h.moviedir);
            guidata(get(source,'Parent'),h);
        else
            showMessage(h,'No folder selected');
            return;
        end
        
    end
    
    
    function h = getidentifier (source, eventdata)
        h=guidata(get(source,'Parent'));
        input=get(source,'String');
        %CALL A FUNCTION (NOT YET WRITTEN) TO CHECK IF THERE ARE ANY FILES WITH THE IDENTIFIER IN
        %THEIR FILENAMES - THIS COULD ALSO BE A CHANNEL NAME IF IMPORTING
        %IMAGE FILES WITH BIOFORMATS/OMERO
        %checkIdentifier(input, h.moviedir);
        if ~isempty(input)
            h.identifier=input;
            guidata(get(source,'Parent'),h);
            showMessage(h,'Changed file identifier');
            return
        else
            showMessage('No string entered');
        end  
    end

    function h = getinterval(source, eventdata)
        h=guidata(get(source,'Parent'));
        input=str2double(get(source,'String'));
        if ~isnan(input)            
            h.interval=input;
            guidata(get(source,'Parent'),h);
            showMessage(h,'Changed frame interval');
            return
        else
            showMessage(h,'Frame interval must be a number (in min)','r');
        end  
    end

    
    function runmaingui (source, eventdata)
        h=guidata(get(source,'Parent'));
        if ~isempty(h.moviedir)
            close (get(source,'Parent'));
            newSegmentation(h.moviedir, h.interval, h.identifier);
        else
            showMessage(h,'Please select directory before proceding to segmentation','g');

        end
        
    end
   
    