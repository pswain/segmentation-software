function trap_prediction_image = generateTrapLocationPredictionImage(cTimelapse,cCellVision,timepoint,channel)
% function trap_prediction_image = generateTrapLocationPredictionImage(cTimelapse,cCellVision,timepoint,channel)
%
% generates trap prediction image by normalised cross correlation with
% traps images in cCellVision.cTrap.
%
% uses trap1 of cTrap (an image of the trap) to identify traps in the image
% by normalised cross correlation. Takes 0.65*the maximum of the cross
% correlation as a threshold and picks all values below this in order,
% ruling out the area directly around each new trap Location.
cTrap = cCellVision.cTrap;

image=cTimelapse.returnSingleTimepoint(timepoint,channel);

image=padarray(image,[cTrap.bb_height cTrap.bb_width],median(image(:)));

trap_prediction_image = normxcorr2(cTrap.trap1,image);
% in some older cellVIsion models, 2 trap images were used for tracking to
% make detection robust.
if isfield(cTrap,'trap2')
    trap_prediction_image = (trap_prediction_image+normxcorr2(cTrap.trap2,image))/2;
end
trap_prediction_image = ...
    trap_prediction_image(2*cTrap.bb_height+1:end-2*cTrap.bb_height,2*cTrap.bb_width+1:end-2*cTrap.bb_width);

f1 = fspecial('disk',1);
trap_prediction_image = (imfilter((trap_prediction_image),f1,'same'));

end