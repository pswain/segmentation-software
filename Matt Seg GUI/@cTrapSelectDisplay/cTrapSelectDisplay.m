classdef cTrapSelectDisplay<handle
    properties
        figure = [];
        imHandle = [];
        image=[];
        axesHandle=[];
        cTimelapse=[]
        timepoint=[];
        trapLocations=[];
        cCellVision=[];
        channel=[];
        ExclusionZones = []; %zones in which to not look for traps automatically stored as 4 vector [xStart1 yStart1 xend1 yend1;xStart2 yStart2 xend2 yend2]
        
    end % properties
    %% Displays timelapse for a single trap
    %This can either dispaly the primary channel (DIC) or a secondary channel
    %that has been loaded. It uses the trap positions identified in the DIC
    %image to display either the primary or secondary information.
    methods
        function cDisplay=cTrapSelectDisplay(cTimelapse,cCellVision,timepoint,channel,ExclusionZones)
            
            if isempty(cCellVision.cTrap)
                errordlg('This cCellVision Model was made to work for timelapses without traps');
                return;
            end
            
            if ~cTimelapse.trapsPresent
                errordlg('This timelapse does not contain traps so this function will not work');
                return;
            end
            
            if nargin<3 || isempty(timepoint)
                timepoint=cTimelapse.timepointsToProcess(1);
            end
            cDisplay.timepoint=timepoint;
            
            if nargin<4 || isempty(channel)
                cDisplay.channel=1;
            else
                cDisplay.channel=channel;
            end
            
            if nargin<5 || isempty(ExclusionZones)
                cDisplay.ExclusionZones = [];
            else
                cDisplay.ExclusionZones = ExclusionZones;
            end
            
            cDisplay.cCellVision=cCellVision;
            cDisplay.cTimelapse=cTimelapse;
            cDisplay.figure=figure;
            cDisplay.axesHandle=axes();
            set(cDisplay.axesHandle,'xtick',[],'ytick',[])
            cDisplay.trapLocations=cTimelapse.cTimepoint(timepoint).trapLocations;
            PreExistingTrapLocations = cTimelapse.cTimepoint(timepoint).trapLocations;
            
            cDisplay.image=cTimelapse.returnSingleTimepoint(timepoint,cDisplay.channel);
            
            [cDisplay.trapLocations trap_mask]=cTimelapse.identifyTrapLocationsSingleTP(timepoint,cCellVision,cDisplay.trapLocations,[],'none');

            TrapsToRemove = [];
            for trapi = 1:length(cDisplay.trapLocations)
                for zonei = 1:size(cDisplay.ExclusionZones,1)
                    
                    if cDisplay.trapLocations(trapi).xcenter>=cDisplay.ExclusionZones(zonei,1) && ...
                            cDisplay.trapLocations(trapi).xcenter<=cDisplay.ExclusionZones(zonei,3) && ...
                            cDisplay.trapLocations(trapi).ycenter>=cDisplay.ExclusionZones(zonei,2) && ...
                            cDisplay.trapLocations(trapi).ycenter<=cDisplay.ExclusionZones(zonei,4);
                        TrapsToRemove = [TrapsToRemove trapi];
                    end
                end
                
            end
            cDisplay.trapLocations(TrapsToRemove) = [];
            
            %bit ugly, but don't want to remove traps that are in the
            %ctimelapse already since they may have been added by user.
            if ~isempty(PreExistingTrapLocations)
            [~,TrapsToPutBack] = setdiff([[PreExistingTrapLocations(:).xcenter]' [PreExistingTrapLocations(:).ycenter]'],...
                    [[cDisplay.trapLocations(:).xcenter]' [cDisplay.trapLocations(:).ycenter]'],'rows');
            
                for trapi = TrapsToPutBack'
                    cDisplay.trapLocations(end+1) = cTimelapse.cTimepoint(timepoint).trapLocations(trapi);
                end
            end
            
            [cDisplay.trapLocations trap_mask]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision,cDisplay.trapLocations,[],'none');
                
            im_mask=cDisplay.image;
            im_mask(trap_mask)=im_mask(trap_mask)*1.5;
            if ~isempty(cTimelapse.omeroImage)
                cDisplay.imHandle=imshow(im_mask,[],'Parent',cDisplay.axesHandle);
                figHandle=get(cDisplay.axesHandle,'Parent');
                set(figHandle,'Name',char(cTimelapse.omeroImage.getName.getValue));
            end
%             cDisplay.subImage(index)=subimage(image);
            %                     colormap(gray);
            %                     set(cDisplay.subAxes(index),'CLimMode','manual')
            set(cDisplay.imHandle,'ButtonDownFcn',@(src,event)addRemoveTraps(cDisplay)); % Set the motion detector.
            set(cDisplay.imHandle,'HitTest','on'); %now image button function will work
        end
        
        function addRemoveTraps(cDisplay)
            cp=get(cDisplay.axesHandle,'CurrentPoint');
            cp=round(cp);
            Cx=cp(1,1);
            Cy=cp(1,2);
            
            if strcmp(get(gcbf,'SelectionType'),'alt')
                pts=[];
                pts(:,1)=[cDisplay.trapLocations.xcenter];
                pts(:,2)=[cDisplay.trapLocations.ycenter];
                
                trapPt=[Cx Cy];
                D = pdist2(pts,trapPt,'euclidean');
                [minval loc]=min(D);
                
                cDisplay.trapLocations(loc)=[];
                [cDisplay.trapLocations trap_mask]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision,cDisplay.trapLocations,[],'none');
                im_mask=cDisplay.image;
                im_mask(trap_mask)=im_mask(trap_mask)*1.5;
%                 cDisplay.imHandle=imshow(im_mask,[],'Parent',cDisplay.axesHandle);
                set(cDisplay.imHandle,'CData',im_mask);
                set(cDisplay.axesHandle,'CLim',[min(im_mask(:)) max(im_mask(:))])

                cDisplay.cTimelapse.cTimepoint(cDisplay.timepoint).trapLocations=cDisplay.trapLocations;
                disp(['remove trap at ', num2str([Cx,Cy])]);
            else
                cDisplay.trapLocations(end+1).xcenter=Cx;
                cDisplay.trapLocations(end).ycenter=Cy;
                [cDisplay.trapLocations trap_mask]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision,cDisplay.trapLocations,[],length(cDisplay.trapLocations));
                im_mask=cDisplay.image;
                im_mask(trap_mask)=im_mask(trap_mask)*1.5;
%                 cDisplay.imHandle=imshow(im_mask,[],'Parent',cDisplay.axesHandle);
                set(cDisplay.imHandle,'CData',im_mask);
                set(cDisplay.axesHandle,'CLim',[min(im_mask(:)) max(im_mask(:))])
                
                cDisplay.cTimelapse.cTimepoint(cDisplay.timepoint).trapLocations=cDisplay.trapLocations;

                disp(['add trap at ', num2str([Cx,Cy])]);
            end
        end

    end
end