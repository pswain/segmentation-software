classdef cTrapDisplayPlot<handle
    %  cTrapDisplayPlot
    %
    % This GUI allows the selection of cells for which data will be
    % extracted. Cells shown in green are those for which data will be
    % extracted, while those shown in red will be ignored. This allows
    % erroneously cells to be removed from the dataset before any analysis
    % is completed. 
    % By left clicking on a red cell, you can add it to the 'to analyse'
    % set, while right clicking on a green cell will remove it from the 'to
    % analyse' set. The scroll wheel will move you forwards and backwards
    % in time, and the up and down arrows will change the channel
    % displayed.
    % 
    % By holding down the cell curation key ('t') and clicking on a cell
    % you can open the curateCellTrackingGUI. This allows the tracking and
    % outline of a cell to be modified for more detailed curation. 
    properties
        figure = [];% the figure in which the GUI is shown.
        subImage = []; % the subimages in which each trap is displayed
        subAxes=[]; % the subaxes in which each subimage is shown
        slider = [];% slider object for moving through time
        cTimelapse=[]; % cTImelapse object that will be modified.
        traps=[]; % indices of traps displayed
        channel=[]; % image channel that is displayed
        gui_help = help('cTrapDisplayPlot');% help string for GUI (shown when h is pressed).
        CurateTracksKey = 't'; %key to hold down when clicking to curate the tracks for that cell
        cCellVision = [];%cellVision model - used if opening a curateCellTrackingGUI
        KeyPressed = []; %stores value of key being held down while it is pressed
        
    end % properties
    
    methods
        function cDisplay=cTrapDisplayPlot(cTimelapse,traps,channel)
            %cDisplay=cTrapDisplayPlot(cTimelapse,traps,channel)
            %
            % 
            % displaying traps for addition or removal of cells from
            % cTimelapse.cellsToPlot. 
            %
            % cTimelapse        :   object of the timelapseTraps class
            % channel           :   channel to show in the GUI. default 1.
            % traps             :   array of trap indices for the traps to
            %
            % cDisplay          :   the GUI object
            if nargin<2 || isempty(traps)
                traps = cTimelapse.defaultTrapIndices;
            end
            
            if nargin<3
                channel=1;
            end
            
                        
            if isempty(cTimelapse.timepointsProcessed)
                tempSize=[cTimelapse.cTimepoint.trapInfo];
                cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo));
            end
            
            cDisplay.channel=channel;
            cDisplay.cTimelapse=cTimelapse;
            cDisplay.traps=traps;
            cDisplay.figure=figure('MenuBar','none');
            
            dis_w=ceil(sqrt(length(traps)));
            if dis_w>1
                dis_w=dis_w+1;
            end
            dis_h=max(ceil(length(traps)/dis_w),1);
            image=cTimelapse.returnTrapsTimepoint(traps,cTimelapse.timepointsToProcess(1),channel);
            
            t_width=.9/dis_w;
            t_height=.9/dis_h;
            bb=.1/max([dis_w dis_h+1]);
            index=1;
            for i=1:dis_w
                for j=1:dis_h
                    if index>length(traps)
                        break; 
                    end
                    
                    cDisplay.subAxes(index)=subplot('Position',[(t_width+bb)*(i-1)+bb/2 (t_height+bb)*(j-1)+bb*2 t_width t_height]);
                    
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
                'Min',cTimelapse.timepointsToProcess(1),...
                'Max',cTimelapse.timepointsToProcess(end),...
                'Units','normalized',...
                'Value',cTimelapse.timepointsToProcess(1),...
                'Position',[bb bb+bb*.3 1-bb bb],...
                'SliderStep',SliderStep,...
                'Callback',@(src,event)slider_cb(cDisplay));

            
            
            hListener = addlistener(cDisplay.slider,'Value','PostSet',@(src,event)slider_cb(cDisplay));


            %generic scroll wheel function that changes slider value
            set(cDisplay.figure,'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(cDisplay,src,event));
            %key press function
            set(cDisplay.figure,'WindowKeyPressFcn',@(src,event)cDisplay.keyPress_cb(src,event));
            %key release function
            set(cDisplay.figure,'WindowKeyReleaseFcn',@(src,event)KeepKey_Release_cb(cDisplay,'KeyPressed',src,event));

            
            cDisplay.slider_cb();
            

        end
    end
end