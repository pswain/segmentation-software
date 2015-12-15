classdef cTrapDisplayPlot<handle
    %  cTrapDisplayPlot
    %
    % similar to the other cell selection GUI's shows each trap with a
    % slider to move up and down through the timepoints. In this GUI,
    % cells are added or removed from the timelapseTraps.cellsToPlot field
    % by left and right clicking respectively. This is the collection of
    % all cells for which data will be extracted when 'extractData' is run.
    properties
        figure = [];
        subImage = [];
        subAxes=[];
        slider = [];
        cTimelapse=[]
        traps=[];
        channel=[]
        cCellVision=[];
        trapNum;
        
        CurateTracksKey = 't'; %key to hold down when clicking to curate the tracks for that cell
        KeyPressed = []; %stores value of key being held down while it is pressed
        
    end % properties
    
    methods
        function cDisplay=cTrapDisplayPlot(cTimelapse,cCellVision,traps,channel)
            %cDisplay=cTrapDisplayPlot(cTimelapse,cCellVision,traps,channel)
            %
            % 
            % displaying traps for addition or removal of cells from
            % cTimelapse.cellsToPlot. 
            %
            % cTimelapse        :   object of the timelapseTraps class
            % cCellVision       :   object of the cellVision class
            % channel           :   channel to show in the GUI. default 1.
            % traps             :   array of trap indices for the traps to
            %
            % cDisplay          :   the GUI object
            if nargin<3 || isempty(traps)
                traps=1:length(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo);
            end
            
            if nargin<4
                channel=1;
            end
            
                        
            if isempty(cTimelapse.timepointsProcessed)
                tempSize=[cTimelapse.cTimepoint.trapInfo];
                cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo));
            end
            
            cDisplay.channel=channel;
            cDisplay.cTimelapse=cTimelapse;
            cDisplay.traps=traps;
            cDisplay.cCellVision=cCellVision;
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
                    cDisplay.trapNum(index)=traps(index);
                    
                    cDisplay.subImage(index)=subimage(image(:,:,i));
                    
                    set(cDisplay.subAxes(index),'xtick',[],'ytick',[])
                    
                    set(cDisplay.subImage(index),'ButtonDownFcn',@(src,event)addRemoveCells(cDisplay,cDisplay.subAxes(index),cDisplay.trapNum(index))); % Set the motion detector.
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
                'Max',sum(cTimelapse.timepointsProcessed),...
                'Units','normalized',...
                'Value',cTimelapse.timepointsToProcess(1),...
                'Position',[bb bb+bb*.3 1-bb bb],...
                'SliderStep',SliderStep,...
                'Callback',@(src,event)slider_cb(cDisplay));

            
            
            hListener = addlistener(cDisplay.slider,'Value','PostSet',@(src,event)slider_cb(cDisplay));


            %generic scroll wheel function that changes slider value
            set(cDisplay.figure,'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(cDisplay,src,event));
            %key press function
            set(cDisplay.figure,'WindowKeyPressFcn',@(src,event)KeepKey_Press_cb(cDisplay,'KeyPressed',src,event));
            %key release function
            set(cDisplay.figure,'WindowKeyReleaseFcn',@(src,event)KeepKey_Release_cb(cDisplay,'KeyPressed',src,event));

            
            cDisplay.slider_cb();
            

        end
        
        
        addRemoveCells(cDisplay,subAx,trap)
        slider_cb(cDisplay)
        
    end
end