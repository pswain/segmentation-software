classdef cTimelapseDisplay<handle
% cTimelapseDisplay
%
% Displays the images for the cTimelapse object as a GUI with a slide bar,
% allowing the user to look at all the full timelapse for that position.
% Takes one additional input, channel, a number defining which channel of
% the cTimelapse should be shown. 
% WARNING: each timepoint is normalised individually, so brightness between
% timepoints is not comparable.

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
    
    methods
        function cDisplay=cTimelapseDisplay(cTimelapse,channel)
                        %help here
            if nargin<2
                cDisplay.channel=1;
            else
                cDisplay.channel=channel;
            end
          
            timepoints=1:length(cTimelapse.cTimepoint);
                        
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

            cDisplay.slider_cb();
            set(cDisplay.figure,'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(cDisplay,src,event));

        end

        slider_cb(cDisplay)
    end
end