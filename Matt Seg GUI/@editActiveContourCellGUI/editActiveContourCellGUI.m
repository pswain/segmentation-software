classdef editActiveContourCellGUI<handle
    properties
        figure = [];
        subImage = [];
        subAxes=[];
        slider = [];
        pause_duration=[];
        cTimelapse=[]
        channel=1;
        tracksDisplayBox=[];
        trapNum = 1;
        ttacObject = [];
        StripWidth = 7;
    end % properties
    
    % A GUI written by Elco to edit the outline of cells segmented by the
    % radial active contour methods.
    % Currently written to show the contour on all the available channels
    % and the transformed image.
    
      methods
        function CellACDisplay=editActiveContourCellGUI(ttacObject,TrapNum,CellNum,Timepoint,StripWidth,channel)
            % CellACDisplay=editActiveContourCellGUI(ttacObject,TrapNum,CellNum,Timepoint(optional),StripWidth(optional))
            
            if nargin<4 || isempty(Timepoint)
                Timepoint = 1;
            end
            
            if nargin<5 || isempty(StripWidth)
                CellACDisplay.StripWidth = 7;
            else 
                CellACDisplay.StripWidth = StripWidth;
            end
            
            MiddleOfStripWidth = ceil(StripWidth/2);
            
            if nargin<6 || isempty(channel)
                CellACDisplay.channel = 1;
            else
                CellACDisplay.channel=channel;   
            end
            
            maxTimepoint = ttacObject.LengthOfTimelapse;
            
            if Timepoint<MiddleOfStripWidth
                Timepoint = MiddleOfStripWidth;
            elseif Timepoint>maxTimepoint
                Timepoint = maxTimepoint;
            end
            
            TimepointsInStrip = (1:CellACDisplay.StripWidth) + Timepoint - MiddleOfStripWidth;
            
            if any(TimepointsInStrip<1)
                TimepointsInStrip = TimepointsInStrip + 1 - min(TimepointsInStrip,[],2);
            end
            
            
            CellACDisplay.ttacObject = ttacObject;
            cTimelapse = ttacObject.TimelapseTraps;

            timepoints=1:ttacObject.LengthOfTimelapse;
            
            CellACDisplay.figure=figure('MenuBar','none');
            
           
            dis_h=(length(cTimelapse.cTimepoint(1).filename) + 1);
            
            
            %%%NEED to EDIT THIS TO GIVE SAME IMAGES AS SEGMENTATION SCRIPT
            image = [];
            for timepointi = TimepointsInStrip
                image=cat(3,image,ImageStack = ACBackGroundFunctions.get_cell_image(Image,SubImageSize,CellCentres);

            end
            
            t_width=.9/dis_w;
            t_height=.9/dis_h;
            bb=.1/max([dis_w dis_h+1]);
            index=1;
            for i=1:dis_w
                for j=1:dis_h
                    if index>length(traps)
                        break;
                    end
                    CellACDisplay.subAxes(index)=subplot('Position',[(t_width+bb)*(i-1)+bb/2 (t_height+bb)*(j-1)+bb*3 t_width t_height]);
                    CellACDisplay.trapNum(index)=traps(index);
                    CellACDisplay.subImage(index)=subimage(image(:,:,i));
                    set(CellACDisplay.subAxes(index),'xtick',[],'ytick',[])
                    
                    % THIS FUNCTION CALLBACK SHOULD LOOK SOMETHING LIKE EditContour(CellACDisplay,Timepoint,trapNum,CellNum,pt,CellCenter)
                    set(CellACDisplay.subImage(index),'ButtonDownFcn',@(src,event)EditContour(CellACDisplay,CellACDisplay.subAxes(index),CellACDisplay.trapNum)); % Set the motion detector.
                    set(CellACDisplay.subImage(index),'HitTest','on'); %now image button function will work

                    index=index+1;
                end
            end
            
            CellACDisplay.slider=uicontrol('Style','slider',...
                'Parent',gcf,...
                'Min',MiddleOfStripWidth,...
                'Max',maxTimepoint,...
                'Units','normalized',...
                'Value',Timepoint,...
                'Position',[bb*2/3 bb 1-bb/2 bb*1.5],...
                'SliderStep',[1/(maxTimepoint - MiddleOfStripWidth) 10/(maxTimepoint - MiddleOfStripWidth)],...
                'Callback',@(src,event)slider_cb(CellACDisplay));
            
            %This hlistener line means that everytime the property 'Value'
            %of CellACDisplay.slider changes the callback slider_cb is run.
            hListener = addlistener(CellACDisplay.slider,'Value','PostSet',@(src,event)slider_cb(CellACDisplay));
        
            CellACDisplay.slider_cb();
        end

    end
end