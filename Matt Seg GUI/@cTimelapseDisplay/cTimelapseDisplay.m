classdef cTimelapseDisplay<handle
% cTimelapseDisplay
%
% Displays the images for the cTimelapse object as a GUI with a slide bar,
% allowing the user to look at all the full timelapse for that position.
% Takes one additional input, channel, a number defining which channel of
% the cTimelapse should be shown. 
%
% By pressing up and down arrows onthe keyboard, one can change the channel
% displayed.
%
% By scrolling with the mouse scroll wheel, one can scroll through the
% timepoints of the timelapse.
%
% By pressing h, one can see the documentation for the GUI.
% 
% WARNING: each timepoint is normalised individually, so brightness between
% timepoints is not comparable.
%
% For details on the effects of buttons pressed
% See also CTIMELAPSEDISPLAY.KEYPRESS_CB

    properties
        figure = [];
        subImage = [];
        subAxes=[];
        slider = [];
        cTimelapse=[]
        channel=[]
        trapNum;
    end % properties
    
    methods
        function cDisplay=cTimelapseDisplay(cTimelapse,channel)
              %cDisplay=cTimelapseDisplay(cTimelapse,channel)
              %
              % creates a display GUI with a slide bar to show each image
              % in channel at each timepoint. channel defaults to 1 and can
              % be changed after construction by changing the property
              % channel.
            if nargin<2
                cDisplay.channel=1;
            else
                cDisplay.channel=channel;
            end
          
                        
            cDisplay.cTimelapse=cTimelapse;
            cDisplay.figure=figure('MenuBar','none');
            
            
            image=cTimelapse.returnSingleTimepoint(1,cDisplay.channel);
            image = SwainImageTransforms.min_max_normalise(image);
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
            
            % add a listener to changes in the slider value to update the
            % slider value if it is moved.
            addlistener(cDisplay.slider,'Value','PostSet',@(src,event)slider_cb(cDisplay));

            cDisplay.slider_cb();
            
            % make the mouse scroll wheel apply to the 
            set(cDisplay.figure,'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(cDisplay,src,event));
            
            %keydown function - move channel up and down.
            set(cDisplay.figure,'WindowKeyPressFcn',@(src,event)keyPress_cb(cDisplay,src,event));
            
        end

        slider_cb(cDisplay)
    end
end