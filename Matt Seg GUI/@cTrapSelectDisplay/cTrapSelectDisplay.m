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
% the result is stored at the given timepoint of the cTimelapse object
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

            TrapsToRemove = cDisplay.identifyExcludedTraps(cDisplay.trapLocations,PreExistingTrapLocations);
            
            cDisplay.trapLocations(TrapsToRemove) = [];
            
            [cDisplay.trapLocations, trap_mask, tIm, cDisplay.cc]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision,cDisplay.trapLocations,[],'none',cDisplay.cc,cDisplay.wholeIm);
                
            cDisplay.setImage(trap_mask);
            
            set(cDisplay.figure,'Name',cTimelapse.getName);
            
            set(cDisplay.imHandle,'ButtonDownFcn',@(src,event)addRemoveTraps(cDisplay)); % Set the motion detector.
            set(cDisplay.imHandle,'HitTest','on'); %now image button function will work
        end
        
        function setImage(cDisplay,trap_mask)
            % setImage(cDisplay,trap_mask)
            % set the
            
            im_mask=cDisplay.image;
            im_mask(trap_mask)=im_mask(trap_mask)*1.5;
            im_mask = SwainImageTransforms.min_max_normalise(im_mask);
            if isempty(cDisplay.imHandle)
                cDisplay.imHandle=imshow(im_mask,[0,1],'Parent',cDisplay.axesHandle);
            else
                set(cDisplay.imHandle,'CData',im_mask);
            end
            
            if ~isempty(cDisplay.ExclusionZones)
                for i = 1:size(cDisplay.ExclusionZones,1)
                    rh = rectangle('Parent',cDisplay.axesHandle,'Position',cDisplay.ExclusionZones(i,:));
                    set(rh,'EdgeColor','r');
                end
            end
            
        end
    end
end