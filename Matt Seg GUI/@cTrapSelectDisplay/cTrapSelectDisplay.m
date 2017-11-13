classdef cTrapSelectDisplay<handle
% cTrapSelectDisplay
%
% a GUI used for identifying the traps in an image at a single timepoint
% and user curation of the result. 
%
% The GUI first automatically detects traps by cross correlation of the
% image from the experiment with the trap image stored in the cellVision
% model.
%
% The user then adds and removes traps by left and right clicks on the
% image respectively (selected traps are shown as a brighter square) and
% the result is stored. These will be the traps used throughout the
% processing.
%
% Red boxes are also shown. These are ExclusionsZones: areas in which traps
% are not automatically identified.
%
%
% DETAILS
%
% A single timepoint is provided and the traps identified at that timpoint
% by the method
%   identifyTrapLocationsSingleTP
%
% This method uses the:
%       timelapseTraps.channelForTrapDetection
% channel to identify the traps by cross correlation with the images stored
% in the loaded cellVision model (cellVision.cTrap.trap1/trap2).
%


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
        gui_help = {help('cTrapSelectDisplay')}; % text displayed if h pressed. 
        cc %cross correlation from identifyTrapLocationsSingleTP. Storing this prevents having to recalculate it each time the user adds or removes a trap. Much faster
        wholeIm %the whole image from returnSingleTimepoint so that each click doesn't require reloading the image
    end % properties

    methods
        function cDisplay=cTrapSelectDisplay(cTimelapse,cCellVision,timepoint,channel,ExclusionZones)
            % cDisplay=cTrapSelectDisplay(cTimelapse,cCellVision,timepoint,channel,ExclusionZones)
            %
            % automatically find traps at timepoint and remove those in
            % Exclusion zones (unless they were already in the timelapse),
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
                cDisplay.channel=cTimelapse.channelForTrapDetection;
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
            
            cDisplay.image=cTimelapse.returnSingleTimepoint(cDisplay.timepoint,cDisplay.channel);
            
            cDisplay.cc = generateTrapLocationPredictionImage(cTimelapse,cCellVision,cDisplay.timepoint,cDisplay.channel);
            
            [cDisplay.trapLocations]=cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision,cDisplay.trapLocations,'none',cDisplay.cc);

            TrapsToRemove = cDisplay.identifyExcludedTraps(cDisplay.trapLocations,PreExistingTrapLocations);
            
            cDisplay.trapLocations(TrapsToRemove) = [];
            
            % this call simply updates the trapLocations and trapInfo of
            % cTimelapse if any have been removed by the two lines above.
            [cDisplay.trapLocations]=cDisplay.cTimelapse.identifyTrapLocationsSingleTP(cDisplay.timepoint,cDisplay.cCellVision,cDisplay.trapLocations,'none',cDisplay.cc);
                
            cDisplay.setImage;
            
            set(cDisplay.figure,'Name',cTimelapse.getName);
            
            set(cDisplay.imHandle,'ButtonDownFcn',@(src,event)addRemoveTraps(cDisplay)); % Set the motion detector.
            set(cDisplay.imHandle,'HitTest','on'); %now image button function will work
            %keydown function - get help on h
            set(cDisplay.figure,'WindowKeyPressFcn',@(src,event)keyPress_cb(cDisplay,src,event));
            
        end
        
        function setImage(cDisplay)
            % setImage(cDisplay,trap_mask)
            % set the
            
            im_mask=cDisplay.image;
            
            trap_locations_array = zeros(length(cDisplay.trapLocations),2);
            for loci = 1:length(cDisplay.trapLocations);
                trap_locations_array(loci,:) = [cDisplay.trapLocations(loci).ycenter,...
                                                cDisplay.trapLocations(loci).xcenter];
            end
            
            trap_locations_array = round(trap_locations_array);
            
            % make mask where all trap pixels are true.
            trap_mask = PutSubStack(false(size(im_mask)),...
                                    trap_locations_array,...
                                    {true(cDisplay.cTimelapse.trapImSize)});
                                
            
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