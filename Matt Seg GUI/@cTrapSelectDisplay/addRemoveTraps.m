function addRemoveTraps(cDisplay)
        % addRemoveTraps(cDisplay)
        % 
        % function add and remove traps from cTimelapse. If SelectionType is
        % 'alt' this is a right click and the trap is removed, if not then
        % it is a left click and it is added. In both cases the
        % identifyTrapLocationsSingleTP method of timelapseTraps is used to
        % fix the location of the traps and produce the overlap image.
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
                
                %don't need to update the trap positions when removing
                %cells
                [cDisplay.trapLocations trap_mask ]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision,cDisplay.trapLocations,[],'none',cDisplay.cc,cDisplay.wholeIm);
                im_mask=cDisplay.image;
                im_mask(trap_mask)=im_mask(trap_mask)*1.5;
                set(cDisplay.imHandle,'CData',im_mask);
                set(cDisplay.axesHandle,'CLim',[min(im_mask(:)) max(im_mask(:))])

                cDisplay.cTimelapse.cTimepoint(cDisplay.timepoint).trapLocations=cDisplay.trapLocations;
                
                % Update the log
                logmsg(cDisplay.cTimelapse,'Remove trap at %s', num2str([Cx,Cy]));
            else
                cDisplay.trapLocations(end+1).xcenter=Cx;
                cDisplay.trapLocations(end).ycenter=Cy;
                [cDisplay.trapLocations trap_mask]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision,cDisplay.trapLocations,[],length(cDisplay.trapLocations),cDisplay.cc,cDisplay.wholeIm);
                im_mask=cDisplay.image;
                im_mask(trap_mask)=im_mask(trap_mask)*1.5;
                set(cDisplay.imHandle,'CData',im_mask);
                set(cDisplay.axesHandle,'CLim',[min(im_mask(:)) max(im_mask(:))])
                
                cDisplay.cTimelapse.cTimepoint(cDisplay.timepoint).trapLocations=cDisplay.trapLocations;

                % Update the log
                logmsg(cDisplay.cTimelapse,'Add trap at %s',num2str([Cx,Cy]));
            end
        end
