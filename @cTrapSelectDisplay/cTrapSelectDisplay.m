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
    end % properties
    %% Displays timelapse for a single trap
    %This can either dispaly the primary channel (DIC) or a secondary channel
    %that has been loaded. It uses the trap positions identified in the DIC
    %image to display either the primary or secondary information.
    methods
        function cDisplay=cTrapSelectDisplay(cTimelapse,cCellVision,timepoint,channel)
            
            if isempty(cCellVision.cTrap)
                errordlg('This cCellVision Model was made to work for timelapses without traps');
                return;
            end
            
            if ~cTimelapse.trapsPresent
                errordlg('This timelapse does not contain traps so this function will not work');
                return;
            end
            
            if nargin<3
                timepoint=1;
            end
            cDisplay.timepoint=timepoint;
            
            if nargin<4
                cDisplay.channel=1;
            else
                cDisplay.channel=channel;
            end
            cDisplay.cCellVision=cCellVision;
            cDisplay.cTimelapse=cTimelapse;
            cDisplay.figure=figure;
            cDisplay.axesHandle=axes();
            set(cDisplay.axesHandle,'xtick',[],'ytick',[])
            cDisplay.trapLocations=cTimelapse.cTimepoint(timepoint).trapLocations;
            
            cDisplay.image=cTimelapse.returnSingleTimepoint(timepoint,cDisplay.channel);
            
            [cDisplay.trapLocations trap_mask]=cTimelapse.identifyTrapLocationsSingleTP(timepoint,cCellVision.cTrap,cDisplay.trapLocations);

            
            im_mask=cDisplay.image;
            im_mask(trap_mask)=im_mask(trap_mask)*1.5;
            cDisplay.imHandle=imshow(im_mask,[],'Parent',cDisplay.axesHandle);
%             cDisplay.subImage(index)=subimage(image);
            %                     colormap(gray);
            %                     set(cDisplay.subAxes(index),'CLimMode','manual')
            set(cDisplay.imHandle,'ButtonDownFcn',@(src,event)addRemoveTraps(cDisplay)); % Set the motion detector.
            set(cDisplay.imHandle,'HitTest','on'); %now image button function will work
        end
        
        function addRemoveTraps(cDisplay)
            cp=get(cDisplay.axesHandle,'CurrentPoint');
            cp=round(cp)
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
                [cDisplay.trapLocations trap_mask]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision.cTrap,cDisplay.trapLocations);
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
                [cDisplay.trapLocations trap_mask]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision.cTrap,cDisplay.trapLocations);
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