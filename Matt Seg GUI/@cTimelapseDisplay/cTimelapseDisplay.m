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
        gui_help = help('cTimelapseDisplay');
    end % properties
    
    methods
        function cDisplay=cTimelapseDisplay(cTimelapse,channel,timepoint_range)
              %cDisplay=cTimelapseDisplay(cTimelapse,channel,timepoint_range)
              %
              % creates a display GUI with a slide bar to show each image
              % in channel at each timepoint. channel defaults to 1 and can
              % be changed after construction by changing the property
              % channel.
              %
              % timpoint_range - [min max] timepoints to show. Defaults to
              %                   all timepoints.
            if nargin<2
                cDisplay.channel=1;
            else
                cDisplay.channel=channel;
            end
            
            if nargin<3 || isempty(timepoint_range)
                timepoint_range = [1, length(cTimelapse.cTimepoint)];
            end
            if timepoint_range(1)<1
                timepoint_range(1) = 1;
            end
            
            if timepoint_range(2)>length(cTimelapse.cTimepoint)
                timepoint_range(2) = length(cTimelapse.cTimepoint);
            end
            
            
            cDisplay.figure=figure('MenuBar','none');

                        
            cDisplay.cTimelapse=cTimelapse;
            
            image=cTimelapse.returnSingleTimepoint(timepoint_range(1),cDisplay.channel);
            image = SwainImageTransforms.min_max_normalise(image);
            image=repmat(image,[1 1 3]);
            index=1;
                    cDisplay.subAxes(index)=subplot('Position',[.05 .07 .9 .9],'Parent',cDisplay.figure);
                    cDisplay.subImage(index)=subimage(image);
                    set(cDisplay.subAxes(index),'xtick',[],'ytick',[])
                    
                    t_length = timepoint_range(2) - timepoint_range(1);
                    if t_length>0
                        SliderStep = [1/(t_length) 1/t_length];
                    else
                        SliderStep = [0 0];
                    end
                    
            cDisplay.slider=uicontrol('Style','slider',...
                'Parent',cDisplay.figure,...
                'Min',timepoint_range(1),...
                'Max',timepoint_range(2),...
                'Units','normalized',...
                'Value',timepoint_range(1),...
                'Position',[.05 .01 .9 .05],...
                'SliderStep',SliderStep,...
                'Callback',@(src,event)slider_cb(cDisplay));
            
            % add a listener to changes in the slider value to update the
            % slider value if it is moved.
            addlistener(cDisplay.slider,'Value','PostSet',@(src,event)slider_cb(cDisplay));

            cDisplay.slider_cb();
            
            % make the mouse scroll wheel apply to the 
            set(cDisplay.figure,'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(cDisplay,src,event));
            
            %keydown function - move channel up and down and get help on h
            set(cDisplay.figure,'WindowKeyPressFcn',@(src,event)keyPress_cb(cDisplay,src,event));
            
        end

        slider_cb(cDisplay)
    end
end