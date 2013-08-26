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
                StripWidth = 7;
            else 
                CellACDisplay.StripWidth = StripWidth;
            end
            
            if nargin<6 || isempty(channel)
                channel = 1;
            else
                CellACDisplay.channel=channel;   
            end
            
            
            CellACDisplay.ttacObject = ttacObject;
            cTimelapse = ttacObject.TimelapseTraps;

            timepoints=1:length(cTimelapse.cTimepoint);
            
            try
                isempty(cTimelapse.cTimepoint(1).trapInfo);
                b=0;
            catch
                b=1;
            end

%             CellACDisplay.channel=channel;
            CellACDisplay.cTimelapse=cTimelapse;
            CellACDisplay.figure=figure('MenuBar','none');
            
           
            dis_h=(length(cTimelapse.cTimepoint(1).filename) + 1);
            image=cTimelapse.returnTrapsTimepoint(traps,1,CellACDisplay.channel);
            
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
                    set(CellACDisplay.subImage(index),'ButtonDownFcn',@(src,event)chooseCellToEdit(CellACDisplay,CellACDisplay.subAxes(index),CellACDisplay.trapNum(index))); % Set the motion detector.
                    if CellACDisplay.trackOverlay
                        set(CellACDisplay.subImage(index),'HitTest','off'); %now image button function will work
                    else
                        set(CellACDisplay.subImage(index),'HitTest','on'); %now image button function will work
                    end
                    index=index+1;
                end
            end
            
            CellACDisplay.slider=uicontrol('Style','slider',...
                'Parent',gcf,...
                'Min',1,...
                'Max',length(cTimelapse.cTimepoint),...
                'Units','normalized',...
                'Value',1,...
                'Position',[bb*2/3 bb 1-bb/2 bb*1.5],...
                'SliderStep',[1/(length(cTimelapse.cTimepoint)-1) 1/(length(cTimelapse.cTimepoint)-1)],...
                'Callback',@(src,event)slider_cb(CellACDisplay));
            hListener = addlistener(CellACDisplay.slider,'Value','PostSet',@(src,event)slider_cb(CellACDisplay));
            
%             CellACDisplay.tracksDisplayBox=uicontrol('Style','radiobutton','Parent',gcf,'Units','normalized',...
%                 'String','Overlay Tracks','Position',[.8 bb*.5 .19 bb],'Callback',@(src,event)tracksDisplay(CellACDisplay));
            
            CellACDisplay.slider_cb();
        end

        % Other functions 
        chooseCellToEdit(CellACDisplay,subAx,trap)
        slider_cb(CellACDisplay)
        tracksDisplay(CellACDisplay);
    end
end