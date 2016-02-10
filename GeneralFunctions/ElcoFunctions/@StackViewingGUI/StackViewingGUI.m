classdef StackViewingGUI < handle
    %General Stack viewing class that will act as a parent to other GUI's
    %in which you want to view a stack and do something on a click
    %   Detailed explanation goes here
    
    properties
        FigureHandle
        MainImageHandle
        MainAxisHandle
        StackDepth
        slider
        MaxStackDepth %size of the stack in the z direction.
        ImagePanel
        ButtonPanel
        Buttons = {};
       
        
        
    end
    
    methods
        
        function Self = StackViewingGUI()
        end
        
        function Self = LaunchGUI(Self)
            %LaunchGUI(Self) the function used to actually make the GUI
            %once all the necessary details have been filled in by the
            %subclass constructor.
        %% GUI stuff
        
        scrsz = get(0,'ScreenSize');
            
            
        
         Self.FigureHandle = figure('Position',[scrsz(3)/3 scrsz(4)/3 scrsz(3)/2 scrsz(4)/2]);
         Self.ImagePanel = uipanel('Parent',Self.FigureHandle,...
                'Position',[.015 .02 .67 .95 ]);
            Self.ButtonPanel = uipanel('Parent',Self.FigureHandle,...
                'Position',[.73 .02 .24 .95 ]);
            
        %% images
        Self.MainAxisHandle = subplot(1,1,1,'Parent',Self.ImagePanel);
        Self.MainImageHandle = subimage(zeros(512,512));
        
        set(Self.MainImageHandle,'HitTest','on')
        set(Self.MainImageHandle,'ButtonDownFcn',@(src,event)addRemoveEntry(Self)); % Set the button down function.
             
        set(Self.MainAxisHandle, 'xtick',[],'ytick',[]);
        
        %% buttons
        
        Self.Buttons{1} = uicontrol(Self.ButtonPanel,...
            'Style','pushbutton',...
            'String','button 1',...
            'Units','normalized',...
            'Parent',Self.ButtonPanel,...
            'Position',[.025 .82 .95 .15],...
            'Callback',@(src,event)fprintf('button 1 !! \n'));
            
        
          Self.slider=uicontrol('Style','slider',...
                'Parent',Self.ImagePanel,...
                'Units','normalized',...
                'Position',[.1 0.01 0.8 .05 ],...
                'Min',1,...
                'Max',Self.MaxStackDepth,...
                'Value',Self.StackDepth,...
                'SliderStep',[1 1],...
                'Callback',@(src,event)StackViewer_slider_cb(Self));
            hListener = addlistener(Self.slider,'Value','PostSet',@(src,event)StackViewer_slider_cb(Self));
            
            Self.StackViewer_slider_cb();
            
            %scroll wheel function
            set(Self.FigureHandle,'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(Self,src,event));
        

        end
        
        
    end
    
end

