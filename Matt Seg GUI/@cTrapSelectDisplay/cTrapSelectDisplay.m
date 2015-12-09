classdef cTrapSelectDisplay<handle
% cTrapSelectDisplay
%
% a GUI used for identifying the traps in an image at a single timepoint
% and user curation of the result. A single timepoint is provided and the
% traps identified at that timpoint by the method
%
%   identifyTrapLocationsSingleTP
%
% This method always uses channel 1 of the cTimelapse to identify the
% traps.
% The user then adds and removes traps by left and right clicks on the
% image respectively (selected traps are shown as a brighter square) and
% the result is stored at the given timepoint of the cTIimslapse object
% used to instantiate the object.
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
                             %traps in these zones before the GUI is
                             %initialised will not be removed.
        
        cc %cross correlation from identifyTrapLocationsSingleTP. Storing this prevents having to recalculate it each time the user adds or removes a trap. Much faster
        wholeIm %the whole image from returnSingleTimepoint so that each click doesn't require reloading the image
    end % properties

    methods
        function cDisplay=cTrapSelectDisplay(cTimelapse,cCellVision,timepoint,channel,ExclusionZones)
            % cDisplay=cTrapSelectDisplay(cTimelapse,cCellVision,timepoint,channel,ExclusionZones)
            %
            % automatically find traps at timepoint and remove those in
            % Exclusion zones (unless thewy were already in the timelapse),
            % then show a GUI interface to correct the result.
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
            cDisplay.cc=[];
            cDisplay.cCellVision=cCellVision;
            cDisplay.cTimelapse=cTimelapse;
            cDisplay.figure=figure;
            cDisplay.axesHandle=axes();
            set(cDisplay.axesHandle,'xtick',[],'ytick',[])
            cDisplay.trapLocations=cTimelapse.cTimepoint(timepoint).trapLocations;
            PreExistingTrapLocations = cTimelapse.cTimepoint(timepoint).trapLocations;
            
            cDisplay.image=cTimelapse.returnSingleTimepoint(timepoint,cDisplay.channel);
            
            [cDisplay.trapLocations, trap_mask, tIm, cDisplay.cc, cDisplay.wholeIm]=cTimelapse.identifyTrapLocationsSingleTP(timepoint,cCellVision,cDisplay.trapLocations,[],'none',cDisplay.cc);

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
                    cDisplay.trapLocations(end+1) = PreExistingTrapLocations(trapi);
                end
            end
            
            [cDisplay.trapLocations, trap_mask, tIm, cDisplay.cc]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision,cDisplay.trapLocations,[],'none',cDisplay.cc,cDisplay.wholeIm);
                
            im_mask=cDisplay.image;
            im_mask(trap_mask)=im_mask(trap_mask)*1.5;
            cDisplay.imHandle=imshow(im_mask,[],'Parent',cDisplay.axesHandle);
            
            if ~isempty(cTimelapse.omeroImage)
                figHandle=get(cDisplay.axesHandle,'Parent');
                set(figHandle,'Name',char(cTimelapse.omeroImage.getName.getValue));
            end
            
            set(cDisplay.imHandle,'ButtonDownFcn',@(src,event)addRemoveTraps(cDisplay)); % Set the motion detector.
            set(cDisplay.imHandle,'HitTest','on'); %now image button function will work
        end
        
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
                disp(['remove trap at ', num2str([Cx,Cy])]);
            else
                cDisplay.trapLocations(end+1).xcenter=Cx;
                cDisplay.trapLocations(end).ycenter=Cy;
                [cDisplay.trapLocations trap_mask]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision,cDisplay.trapLocations,[],length(cDisplay.trapLocations),cDisplay.cc,cDisplay.wholeIm);
                im_mask=cDisplay.image;
                im_mask(trap_mask)=im_mask(trap_mask)*1.5;
                set(cDisplay.imHandle,'CData',im_mask);
                set(cDisplay.axesHandle,'CLim',[min(im_mask(:)) max(im_mask(:))])
                
                cDisplay.cTimelapse.cTimepoint(cDisplay.timepoint).trapLocations=cDisplay.trapLocations;

                disp(['add trap at ', num2str([Cx,Cy])]);
            end
        end

    end
end