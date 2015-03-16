% Script to make a movie from a single trap on a timelapse with the
% segmentation included.

%% load a cTimelapse and cCellvision

load('~/Documents/microscope_files_swain_microscope/FFFD-GFP/2014_11_15_str241_NDFGFPstar_raff_RG_glu/2014_11_14_analysis_exp02/pos1cTimelapse.mat')
load('~/Documents/microscope_files_swain_microscope/FFFD-GFP/2014_11_15_str241_NDFGFPstar_raff_RG_glu/2014_11_14_analysis_exp02/cExperiment.mat','cCellVision')

cTrapDisplayPlot(cTimelapse,cCellVision)

%% 

FileName = '~/Desktop/2014_11_15_pos2_trap2_seg_movie.avi';
FPS = 8;
trap = 2;

%%
writerObj = VideoWriter(FileName);
set(writerObj,'Quality',100,'FrameRate',FPS)
writerObj.open();
Ttotal = length(cTimelapse.timepointsToProcess);

disp = cTrapDisplayPlot(cTimelapse,cCellVision,trap);

kids = get(disp.figure,'children');

%FrameArray = get(get(kids(2),'children'),'cdata');

%FrameArray = ones([size(FrameArray),Ttotal],'uint8');


for ti = 1:Ttotal
    tp = cTimelapse.timepointsToProcess(ti);
    disp.slider.Value = tp;
    disp.slider_cb();
    %FrameArray(:,:,:,ti) = get(get(kids(2),'children'),'cdata');
    FrameArray(ti) = im2frame(get(get(kids(2),'children'),'cdata'));
end


%%
writerObj.open;
writeVideo(writerObj,FrameArray);
writerObj.close;