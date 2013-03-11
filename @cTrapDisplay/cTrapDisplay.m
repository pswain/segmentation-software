classdef cTrapDisplay<handle
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
        function cDisplay=cTrapDisplay(cTimelapse,cCellVision,overlay,channel,traps)
            
            if nargin<3
                cDisplay.trackOverlay=false;
            else
                cDisplay.trackOverlay=overlay;
            end
            
            if nargin<4
                cDisplay.channel=1;
            else
                cDisplay.channel=channel;
            end
            if nargin<5 && cTimelapse.trapsPresent
                traps=1:length(cTimelapse.cTimepoint(1).trapLocations);
            else
                %traps=1;
            end
            
            
            
            timepoints=1:length(cTimelapse.cTimepoint);
            
            try
                isempty(cTimelapse.cTimepoint(1).trapInfo);
                b=0;
            catch
                b=1;
            end
            
            if cTimelapse.trapsPresent           
                %In case the traps haven't been tracked through time
                if isempty(cTimelapse.cTimepoint(end).trapLocations)
                    h = waitbar(0,'Please wait as this tracks the traps through the timelapse ...');
                    for i=2:length(timepoints)
                        timepoint=timepoints(i);
                        cTimelapse.identifyTrapLocationsSingleTP(timepoint,cCellVision.cTrap,cTimelapse.cTimepoint(timepoints(i-1)).trapLocations);
                        waitbar(timepoint/timepoints(end));
                    end
                    close(h)
                end
            elseif b 
                image=cTimelapse.returnTrapsTimepoint(traps,1,cDisplay.channel);
%                 if isempy(
                for timepoint=timepoints
                    cTimelapse.cTimepoint(timepoint).trapInfo=struct('segCenters',zeros(size(image))>0,'cell',[],'cellsPresent',0,'cellLabel',[],'segmented',sparse(zeros(size(image))>0));
                    cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.cellCenter=[];
                    cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.cellRadius=[];
                    cTimelapse.cTimepoint(timepoint).trapInfo(1).cell.segmented=sparse(zeros(size(image))>0);
                    cTimelapse.cTimepoint(timepoint).trapInfo(1).cellsPresent=0;
                end
            end
            
%             cDisplay.channel=channel;
            cDisplay.cTimelapse=cTimelapse;
            cDisplay.traps=traps;
            cDisplay.cCellVision=cCellVision;
            cDisplay.figure=figure('MenuBar','none');
            
            dis_w=ceil(sqrt(length(traps)));
            if dis_w>1
                dis_w=dis_w+1;
            end
            dis_h=max(ceil(length(traps)/dis_w),1);
            image=cTimelapse.returnTrapsTimepoint(traps,1,cDisplay.channel);
            
            t_width=.9/dis_w;
            t_height=.9/dis_h;
            bb=.1/max([dis_w dis_h+1]);
            index=1;
            for i=1:dis_w
                for j=1:dis_h
                    if index>length(traps)
                        break;
                    end
                    cDisplay.subAxes(index)=subplot('Position',[(t_width+bb)*(i-1)+bb/2 (t_height+bb)*(j-1)+bb*3 t_width t_height]);
                    cDisplay.trapNum(index)=traps(index);
                    cDisplay.subImage(index)=subimage(image(:,:,i));
                    set(cDisplay.subAxes(index),'xtick',[],'ytick',[])
                    set(cDisplay.subImage(index),'ButtonDownFcn',@(src,event)addRemoveCells(cDisplay,cDisplay.subAxes(index),cDisplay.trapNum(index))); % Set the motion detector.
                    if cDisplay.trackOverlay
                        set(cDisplay.subImage(index),'HitTest','off'); %now image button function will work
                    else
                        set(cDisplay.subImage(index),'HitTest','on'); %now image button function will work
                    end
                    index=index+1;
                end
            end
            
            cDisplay.slider=uicontrol('Style','slider',...
                'Parent',gcf,...
                'Min',1,...
                'Max',length(cTimelapse.cTimepoint),...
                'Units','normalized',...
                'Value',1,...
                'Position',[bb*2/3 bb 1-bb/2 bb*1.5],...
                'SliderStep',[1/(length(cTimelapse.cTimepoint)-1) 1/(length(cTimelapse.cTimepoint)-1)],...
                'Callback',@(src,event)slider_cb(cDisplay));
            hListener = addlistener(cDisplay.slider,'Value','PostSet',@(src,event)slider_cb(cDisplay));
            
%             cDisplay.tracksDisplayBox=uicontrol('Style','radiobutton','Parent',gcf,'Units','normalized',...
%                 'String','Overlay Tracks','Position',[.8 bb*.5 .19 bb],'Callback',@(src,event)tracksDisplay(cDisplay));
            
            cDisplay.slider_cb();
        end

        % Other functions 
        addRemoveCells(cDisplay,subAx,trap)
        slider_cb(cDisplay)
        tracksDisplay(cDisplay);
    end
end