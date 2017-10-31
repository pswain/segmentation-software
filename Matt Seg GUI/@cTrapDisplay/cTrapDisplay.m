classdef cTrapDisplay<handle
    % cTrapDisplay
    %
    % A GUI that allows the editing of the segmentation by addition and
    % removal of cells. The traps are shown as a grid an cells can be added
    % and removed at individual time points by left clicking (add) and
    % right clicking(remove).
    % 
    % One can also open a tracking curation sub GUI that allows more
    % detailed editing (adding and removing cells, changing their outline
    % and the tracking across timepoints). This is done by holding down the
    % CurateTracksKey (default 't') and clicking on a cell.
    properties
        figure = []; % the figure handle for the whole GUI
        subImage = []; % array of subimages in which each image is shown
        subAxes=[]; % array of subaxes on which each image is shown
        slider = []; % slider object used to move through time points
        cTimelapse=[] % timelapseTraps object displayed and edited
        traps=[]; % indices of traps to show
        channel=[] % channel shown
        trackOverlay=[]; %boolean. stores overlay input and determines whether to color cells by label.
        CurateTracksKey = 't'; %key to hold down when clicking to curate the tracks for that cell
        KeyPressed = [];%stores value of key being held down while it is pressed
        gui_help = help('cTrapDisplay');
        
    end % properties

    methods
        function cDisplay=cTrapDisplay(cTimelapse,overlay,channel,traps, trackThroughTime)
            % cDisplay=cTrapDisplay(cTimelapse,cCellVision,cCellMorph,overlay,channel,traps,trackThroughTime)
            %
            % cTimelapse        :   object of the timelapseTraps class
            % overlay           :   boolean, default false. Whether to
            %                       colour cells by their tracking label.
            % channel           :   channel to show in the GUI. default 1.
            % traps             :   array of trap indices for the traps to
            %                       display in the GUI.
            % trackThroughTime  :   boolean, default false. If true, tracks
            %                       traps.
            %
            % timelapseTraps should have had timepoints selected already.
            timepoints=cTimelapse.timepointsToProcess;
            
            if nargin<2 || isempty(overlay)
                cDisplay.trackOverlay=false;
            else
                cDisplay.trackOverlay=overlay;
            end
            
            if nargin<3 || isempty(channel)
                cDisplay.channel=1;
            else
                cDisplay.channel=channel;
            end
            if nargin<4 || isempty(traps)  
                if cTimelapse.trapsPresent 
                    traps=1:length(cTimelapse.cTimepoint(timepoints(1)).trapLocations);
                elseif ~cTimelapse.trapsPresent
                    traps=1;
                end
            end
            
            if nargin<5 || isempty(trackThroughTime)
                trackThroughTime=false;
            end
            
            
            if isempty(cTimelapse.cTimepoint(timepoints(1)).trapLocations);
                
                error('error: select traps before using the cTrapDisplay GUI');
            end
                
            if isempty(cTimelapse.cTimepoint(timepoints(1)).trapInfo)
                error('please select traps at the first timepoint before using this GUI')
            end
            
            if isempty(cTimelapse.timepointsProcessed)
                cTimelapse.timepointsProcessed = false(1,max(cTimelapse.timepointsToProcess));
            end
            
            
            if trackThroughTime
                cTimelapse.trackTrapsThroughTime(cCellVision,timepoints,false);
            end

            cDisplay.cTimelapse=cTimelapse;
            cDisplay.traps=traps;
            cDisplay.figure=figure('MenuBar','none');
            
            % width of grid of images - a little off square
            dis_w=ceil(sqrt(length(traps)));
            if dis_w>1
                dis_w=dis_w+1;
            end
            %height of image grid
            dis_h=max(ceil(length(traps)/dis_w),1);
            image=cTimelapse.returnTrapsTimepoint(traps,timepoints(1),cDisplay.channel);
            
            % spacing parameters to space images with a gap between them.
            t_width=.9/dis_w;
            t_height=.9/dis_h;
            bb=.1/max([dis_w dis_h+1]);
            index=1;
            for i=1:dis_w
                for j=1:dis_h
                    if index>length(traps)
                        break;
                    end
                    cDisplay.subAxes(index)=subplot('Position',[(t_width+bb)*(i-1)+bb/2 (t_height+bb)*(j-1)+bb*3 t_width t_height]);
                    cDisplay.subImage(index)=subimage(image(:,:,i));
                    set(cDisplay.subAxes(index),'xtick',[],'ytick',[])
                    set(cDisplay.subImage(index),'ButtonDownFcn',@(src,event)addRemoveCells(cDisplay,cDisplay.subAxes(index),cDisplay.traps(index))); % Set the motion detector.
                    set(cDisplay.subImage(index),'HitTest','on'); %now image button function will work
                    
                    index=index+1;
                end
            end
            
            if length(cTimelapse.cTimepoint)>1
            SliderStep = [1/(length(cTimelapse.cTimepoint)-1) 1/(length(cTimelapse.cTimepoint)-1)];
            else
                SliderStep = [0 0];
            end
                        
            cDisplay.slider=uicontrol('Style','slider',...
                'Parent',gcf,...
                'Min',min(timepoints),...
                'Max',max(timepoints),...
                'Units','normalized',...
                'Value',min(timepoints),...
                'Position',[bb*2/3 bb 1-bb/2 bb*1.5],...
                'SliderStep',SliderStep,...
                'Callback',@(src,event)slider_cb(cDisplay));
            hListener = addlistener(cDisplay.slider,'Value','PostSet',@(src,event)slider_cb(cDisplay));

            cDisplay.slider_cb();
            
            %scroll wheel function
            set(cDisplay.figure,'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(cDisplay,src,event));
            
            %this pair of functions store key values of the key pressed so
            %they can influence the behaviour of the GUI.
            
            %keydown function  cDisplay.keyRelease_cb(src,event))
            set(cDisplay.figure,'WindowKeyPressFcn',@(src,event)cDisplay.keyPress_cb(src,event));
            %key release function. This is different from the generic one
            %to allow the help string to be shown and channels to be moved
            %with button presses.
            set(cDisplay.figure,'WindowKeyReleaseFcn',@(src,event)KeepKey_Release_cb(cDisplay,'KeyPressed',src,event));

            
        end
    end
end