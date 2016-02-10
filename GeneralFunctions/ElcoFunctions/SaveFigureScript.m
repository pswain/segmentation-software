%% a script for setting a figures properties and then saving it as .png file 

%% for single plots

h = gcf;
LW = 1;
FS = 14;
set(h,'PaperUnits','centimeters',...
     'PaperPosition',[0 0 20 10]) %[0 0 width height]
set(get(h,'children'),'FontSize',FS,'LineWidth',LW)
set(get(get(h,'children'),'children'),'LineWidth',LW)


%% for plots
set(h,'LooseInset',get(h,'TightInset'))

%% for images
set(gca,'position',[0 0 1 1],'units','normalized','LineWidth',10);
aspect_ratio = get(gca,'PlotBoxAspectRatio'); 
set(gcf,'PaperUnits','centimeters',...
     'PaperPosition',[0 0 (aspect_ratio(1)/aspect_ratio(2))*10 10]) %[0 0 width height]


%% writeup

location = '~/Dropbox/ongoing_writeup/logbook_and_notebook_images/segmentation_and_active_contour/2014_10_07_diff_fluor_brightness.png';

%% facs locations

location = '~/Documents/FACS data/2014_07_02_ND(F)GFPstar_expression_check/Analysis/histogram';

%% by gui

dirrr = uigetdir('~/Documents');

nameeee = inputdlg('file name','name box',1,{'.png'});

nameeee = nameeee{1};
%% same dir

%nameeee = 'a.png'

location = fullfile(dirrr,nameeee)
  

saveas(gca,location,'png')


