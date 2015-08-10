classdef cTrapDisplayPlot<handle
    properties
        figure = [];
        subImage = [];
        subAxes=[];
        slider = [];
        pause_duration=[];
        cTimelapse=[]
        traps=[];
        channel=[]
        cCellVision=[];
        cExperiment;
        trapNum;
        
        trackOverlay=[];
        tracksDisplayBox=[];
        CurateTracksKey = 't'; %key to hold down when clicking to curate the tracks for that cell
        KeyPressed = []; %stores value of key being held down while it is pressed
        
    end % properties
    %% Displays timelapse for a single trap
    %This can either dispaly the primary channel (DIC) or a secondary channel
    %that has been loaded. It uses the trap positions identified in the DIC
    %image to display either the primary or secondary information.
    methods
        function cDisplay=cTrapDisplayPlot(cTimelapse,cCellVision,traps,channel)
            
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
            
%             for dirfind=1:length(cExperiment.dirs)
%                 if strcmp([cExperiment.rootFolder '/' cExperiment.dirs{dirfind}],cTimelapse.timelapseDir)
%                     cExperiment.currentDir=dirfind;
%                     break
%                 end
%             end
%             cDisplay.cExperiment=cExperiment;
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
                        break; end
                    
                    %     h_axes(i)=subplot(dis_h,dis_w,i);
                    %         h_axes(index)=subplot('Position',[t_width*(i-1)+bb t_height*(j-1)+bb t_width t_height]);
                    cDisplay.subAxes(index)=subplot('Position',[(t_width+bb)*(i-1)+bb/2 (t_height+bb)*(j-1)+bb*2 t_width t_height]);
                    cDisplay.trapNum(index)=traps(index);
                    
                    cDisplay.subImage(index)=subimage(image(:,:,i));
                    %                     colormap(gray);
                    set(cDisplay.subAxes(index),'xtick',[],'ytick',[])
                    %                     set(cDisplay.subAxes(index),'CLimMode','manual')
                    set(cDisplay.subImage(index),'ButtonDownFcn',@(src,event)addRemoveCells(cDisplay,cDisplay.subAxes(index),cDisplay.trapNum(index))); % Set the motion detector.
                    set(cDisplay.subImage(index),'HitTest','on'); %now image button function will work
                    if cDisplay.trackOverlay
                        set(cDisplay.subImage(index),'HitTest','off'); %now image button function will work
                    else
                        set(cDisplay.subImage(index),'HitTest','on'); %now image button function will work
                    end

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
%             cDisplay.tracksDisplayBox=uicontrol('Style','radiobutton','Parent',gcf,'Units','normalized',...
%                 'String','Overlay Tracks','Position',[.8 bb*.5 .19 bb],'Callback',@(src,event)tracksDisplay(cDisplay));


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
        tracksDisplay(cDisplay);

    end
end