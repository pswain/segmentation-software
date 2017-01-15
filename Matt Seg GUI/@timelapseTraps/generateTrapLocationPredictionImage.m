function trap_prediction_image = generateTrapLocationPredictionImage(cTimelapse,cCellVision,timepoint,channel)
% function trap_prediction_image = generateTrapLocationPredictionImage(cTimelapse,cCellVision,timepoint,channel)
%
% generates trap prediction image by normalised cross correlation with
% traps images in cCellVision.cTrap.

cTrap = cCellVision.cTrap;

image=cTimelapse.returnSingleTimepoint(timepoint,channel);

image=image*cTrap.scaling/median(image(:));
image=padarray(image,[cTrap.bb_height cTrap.bb_width],median(image(:)));

trap_prediction_image = abs(normxcorr2(cTrap.trap1,image))+abs(normxcorr2(cTrap.trap2,image));
trap_prediction_image = ...
    trap_prediction_image(2*cTrap.bb_height+1:end-2*cTrap.bb_height,2*cTrap.bb_width+1:end-2*cTrap.bb_width);

f1 = fspecial('disk',1);
trap_prediction_image = (imfilter((trap_prediction_image),f1,'same'));

end