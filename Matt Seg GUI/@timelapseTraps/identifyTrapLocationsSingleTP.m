function [trapLocations] = identifyTrapLocationsSingleTP(cTimelapse,timepoint,cCellVision,trapLocations,trapLocationsToCheck,trap_prediction_image)
% [trapLocations, trap_mask, cc] = identifyTrapLocationsSingleTP(cTimelapse,timepoint,cCellVision,trapLocations,trapImagesPrevTp,trapLocationsToCheck,cc)
%
% function for identifying traps in the single timepoint using cross
% correlation and producing:
% trap_mask : a logical of all the areas defined as being parts of traps in
%             an image (note, ot the pillars, but the trap areas)
% trapImage : a stack of images of each trap.
%
% If trapLocations are provided then these images are simply generated
% using those locations.
%
% If trapLocations are not provided (i.e. in a call like:
%
%           cTimelapse.identifyTrapLocationsSingleTP(timepoint,cCellVision)
%
% the trap1 field of cCellVision.cTrap is cross correlated with the first
% channel of cTimelapse at timepoint 'timepoint' (note, the first channel
% is always used, so this should correspond to the image in trap1 of
% cCellVision). A normalised cross correlation is calculated, the absolute
% taken (I'm not sure why, probably beccause DIC is often somewhat
% variable), and local maxima chosen until all the points above a threhold
% (0.65* the maximum of the cross correlation) have been selected. At each
% new selection, the points in its immediate vicinity are rules out.
%
% If TrapLocationToCheck is the string 'none', it has no effect, if it is an
% index then those trapLocations are shifted to their nearest maxima in the
% cross correlation image. This is sort of a half way between the two
% behaviours used in trap selection. Most of the trap Locations are left
% unaffected, but only those in trapLocationsToCheck are changed.
%
% trapImagesPrevTp is no longer used, but don't want to remove it since it
% will mess up calls to the function.


if nargin<5 || isempty(trapLocationsToCheck)
    trapLocationsToCheck='none'; %traps to put through the 'find nearest best point and set trap location to that' mill. if string 'none' does none of them.
end


cTrap=cCellVision.cTrap;

cTrap.bb_width=ceil((size(cTrap.trap1,2)-1)/2);
cTrap.bb_height=ceil((size(cTrap.trap1,1)-1)/2);

cTimelapse.cTrapSize.bb_width=cTrap.bb_width;
cTimelapse.cTrapSize.bb_height=cTrap.bb_height;

if nargin<6 || isempty(trap_prediction_image)
    channel = 1;
    
    trap_prediction_image = generateTrapLocationPredictionImage(cTimelapse,cCellVision,timepoint,channel);

end

if nargin<4 || isempty(trapLocations)
    [trapLocations]=predictTrapLocations(cTrap,trap_prediction_image); 
end

[trapLocations]=updateTrapLocations(cTrap,trapLocations,trapLocationsToCheck,trap_prediction_image);

cTimelapse.cTimepoint(timepoint).trapLocations=trapLocations;

trapInfo = cTimelapse.trapInfoTemplate;

cTimelapse.cTimepoint(timepoint).trapInfo=trapInfo ;
cTimelapse.cTimepoint(timepoint).trapInfo(1:length(trapLocations))= trapInfo;
end

function [trapLocations]=predictTrapLocations(cTrap,trap_predictions_image)
% [trapLocations]=predictTrapLocations(cTrap,cc)
%
% uses trap1 of cTrap (an image of the trap) to identify traps in the image
% by normalised cross correlation. Takes 0.65*the maximum of the cross
% correlation as a threshold and picks all values below this in order,
% ruling out the area directly around each new trap Location.

[max_trap_pred_im, imax] = max(trap_predictions_image(:));
max_dynamic=max_trap_pred_im;
trap_index=1;

trapLocations = struct('xcenter',[],'ycenter',[]);

ccBounding=1.2;
bY=floor(cTrap.bb_height*ccBounding);
bX=floor(cTrap.bb_width*ccBounding);
    
while max_dynamic> .45*max_trap_pred_im
    [ypeak, xpeak] = ind2sub(size(trap_predictions_image),imax(1));
    trap_predictions_image(ypeak-bY:ypeak+bY,xpeak-bX:xpeak+bX) = 0;
    
    trapLocations(trap_index).xcenter=xpeak;
    trapLocations(trap_index).ycenter=ypeak;
    
    trap_index=trap_index+1;
    [max_dynamic, imax] = max(trap_predictions_image(:));   
end

end


function [trapLocations] = updateTrapLocations(cTrap,trapLocations,trapLocationsToCheck,trap_prediction_image)
% [trapLocations] = updateTrapLocations(image,cTrap,trapLocations,trapLocationsToCheck,trap_prediction_image)
% 
% shifts those locations marked as 'ToCheck' to their nearest maximum in
% the trap_prediction_image.
%
% cTrap                     -   structure coming from cCellvision with
%                               information about the trap (only the size
%                               is used).
% trapLocations             -   structure array of trapLocation as stored
%                               by TIMELAPSETRAPS
% trapLocationsToCheck      -   array of indices of traps that should be
%                               shifted to their nearest maximum.
% trap_prediction_image     -   image of the size of TIMELAPSETRAPS.IMSIZE
%                               with high values at likely trap centres. 

if nargin<4 || isempty(trapLocationsToCheck)
    trapLocations = 1:length(trapLocationsToCheck);
elseif strcmp(trapLocationsToCheck,'none')
    trapLocationsToCheck = [];
end

for i=1:length(trapLocations)

    xcurrent=trapLocations(i).xcenter;
    ycurrent=trapLocations(i).ycenter;
    
    if ismember(i,trapLocationsToCheck) 
        %if this is one of the trap locations to check, make it's location
        %the maximum cross correlation value within a third of a trap width
        %of the point selected for the trap.
        temp_im=trap_prediction_image(round(ycurrent-cTrap.bb_height/3:ycurrent+cTrap.bb_height/3),round(xcurrent-cTrap.bb_width/3:xcurrent+cTrap.bb_width/3));

        [~, maxloc]=max(temp_im(:));
        [ypeak, xpeak] = ind2sub(size(temp_im),maxloc);

        xcenter=(xcurrent+xpeak-cTrap.bb_width/3-1);
        ycenter=(ycurrent+ypeak-cTrap.bb_height/3-1);

        trapLocations(i).xcenter=xcenter;
        trapLocations(i).ycenter=ycenter;

    end
    
end


end


