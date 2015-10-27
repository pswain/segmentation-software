function useCurrentTrap(cCellVisionGUI)
% 
% [FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of cCellVision Model used to create this segmentation') ;
% load(fullfile(PathName,FileName),'cCellVision');

traps=cCellVisionGUI.cTimelapse.returnTrapsTimepoint;
b=floor(rand(1,2)*size(traps,3)/2)+1;
cCellVisionGUI.cCellVision.cTrap.trap1=traps(:,:,b(1));
cCellVisionGUI.cCellVision.cTrap.trap2=traps(:,:,b(2));


        cCellVisionGUI.cCellVision.cTrap.bb_width=size(traps,2);
        cCellVisionGUI.cCellVision.cTrap.bb_height=size(traps,1);
        cCellVisionGUI.cCellVision.cTrap.scaling=150;
        cCellVisionGUI.cCellVision.cTrap.Prior=.5;
        cCellVisionGUI.cCellVision.cTrap.thresh=.5;
        cCellVisionGUI.cCellVision.cTrap.thresh_first=.4;


cCellVisionGUI.cCellVision.identifyTrapOutline();