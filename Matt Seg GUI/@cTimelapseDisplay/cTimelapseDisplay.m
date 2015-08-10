classdef cTimelapseDisplay<handle
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
        trackOverlay=[];
        tracksDisplayBox=[];
        trapNum;
    end % properties
    %% Displays timelapse for a single trap
    %This can either dispaly the primary channel (DIC) or a secondary channel
    %that has been loaded. It uses the trap positions identified in the DIC
    %image to display either the primary or secondary information.
    methods
        function cDisplay=cTimelapseDisplay(cTimelapse,channel)
                        
            if nargin<2
                cDisplay.channel=1;
            else
                cDisplay.channel=channel;
            end
          
            timepoints=1:length(cTimelapse.cTimepoint);
            
            
%             cDisplay.channel=channel;
            cDisplay.cTimelapse=cTimelapse;
            cDisplay.figure=figure('MenuBar','none');
            
            
            image=cTimelapse.returnSingleTimepoint(1,cDisplay.channel);
            image=repmat(image,[1 1 3]);
            index=1;
                    cDisplay.subAxes(index)=subplot('Position',[.05 .07 .9 .9]);
                    cDisplay.subImage(index)=subimage(image);
                    set(cDisplay.subAxes(index),'xtick',[],'ytick',[])
            
                    if length(cTimelapse.cTimepoint)>1
                        SliderStep = [1/(length(cTimelapse.cTimepoint)-1) 1/(length(cTimelapse.cTimepoint)-1)];
                    else
                        SliderStep = [0 0];
                    end
                    
            cDisplay.slider=uicontrol('Style','slider',...
                'Parent',gcf,...
                'Min',1,...
                'Max',length(cTimelapse.cTimepoint),...
                'Units','normalized',...
                'Value',1,...
                'Position',[.05 .01 .9 .05],...
                'SliderStep',SliderStep,...
                'Callback',@(src,event)slider_cb(cDisplay));
            hListener = addlistener(cDisplay.slider,'Value','PostSet',@(src,event)slider_cb(cDisplay));
            
%             cDisplay.tracksDisplayBox=uicontrol('Style','radiobutton','Parent',gcf,'Units','normalized',...
%                 'String','Overlay Tracks','Position',[.8 bb*.5 .19 bb],'Callback',@(src,event)tracksDisplay(cDisplay));
            
            cDisplay.slider_cb();
            set(cDisplay.figure,'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(cDisplay,src,event));

        end

        % Other functions 
        slider_cb(cDisplay)
    end
end