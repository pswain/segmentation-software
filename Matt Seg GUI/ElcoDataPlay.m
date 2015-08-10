%% GENERAL DATA PLAY FILE

Data = disp.cExperiment.cellInf;
channels = [3 4];
channeli =1;
channel = channels(channeli);
timepoints = [17 108;1 108];
analysis_timepoint1 = max(timepoints(:,1));
analysis_timepoint2 = min(timepoints(:,2));
total_timepoints = (analysis_timepoint2 - analysis_timepoint1)+1;


%% sort data by some property
which_timepoint = 2; %1 for first, 2 for last.

data1 = full(Data(channel).median);
data2 = full(Data(4).median);

dataRatio = data1./data2;
dataRatioNAN = dataRatio;
dataRatioNAN(data1 == 0) = NaN;

%remove cells with too many NaN's

to_remove = sum(isnan(dataRatioNAN),2)>(0.3*size(data1,2));

data1(to_remove,:) = [];
data2(to_remove,:) = [];
dataRatio(to_remove,:) = [];
dataRatioNAN(to_remove,:) = [];

celln = size(data1,1);

median_last_5 = zeros(celln,1);

median_first_5 = zeros(celln,1);

for i=1:celln
    
    single_cell = dataRatioNAN(i,:);
    single_cell(isnan(single_cell))=[];
    median_first_5(i) = median(single_cell(1:5));
    median_last_5(i) = median(single_cell((end-5):end));

end

[~,order] = sort(iqr(dataRatioNAN,2),'ascend');

median_first_5 = median_first_5(order);

median_last_5 = median_last_5(order);

dataRatioSort = dataRatioNAN(order,:);

meanValues = nanmean(dataRatioSort,2);

varianceValues = nanvar(dataRatioSort,0,2);

maxValues = nanmax(dataRatioSort,[],2);

minValues = nanmin(dataRatioSort,[],2);

iqrValues = iqr(dataRatioSort,2);


data1sort = data1(order,:);

data2sort = data2(order,:);

MandV = [meanValues varianceValues maxValues minValues maxValues./minValues median_last_5./median_first_5 iqrValues] ;

MandVnorm = MandV./(kron(max(MandV,[],1),ones(celln,1)));

if ~exist('plot_h','var')
    plot_h = figure;
end
figure(plot_h);


plot(1:celln,MandVnorm + kron(1:size(MandVnorm,2),ones(celln,1)))



%% pick data to show
% 
data_to_show = dataRatioSort;
timepoint1 = timepoints(channeli,1);
timepoint2 = timepoints(channeli,2);
% 
% data_to_show = MandVnorm;
% timepoint1 = 1;
% timepoint2 = size(MandV,2);
%            
%% show
if ~exist('figure_h','var')
    figure_h = figure;
end
figure(figure_h);
imshow(data_to_show(:,(timepoint1:timepoint2)),[]);
colormap('jet')

%% plot

n_first = 5;
n_end = 5;

figure(figure_h);
plot(data_to_show([timepoint1:(timepoint1 + n_first) ...
    (timepoint2-n_end):timepoint2],:)');


%% decide WT and expression

if ~exist('check_boundary_h1','var')
    check_boundary_h1 = figure;
    check_boundary_h2 = figure;
end

WT = [1:41 43:65];
expressing = 70:celln;

figure(check_boundary_h1);
plot(dataRatioSort(WT,:)','-r')
figure(check_boundary_h2);
plot(dataRatioSort(expressing,:)','-b')
hold off

WTdata1 = data1sort(WT,analysis_timepoint1:analysis_timepoint2);
WTdata2 = data2sort(WT,analysis_timepoint1:analysis_timepoint2);
EXPdata1 = data1sort(expressing,analysis_timepoint1:analysis_timepoint2);
EXPdata2 = data2sort(expressing,analysis_timepoint1:analysis_timepoint2);

%% correct for exposure times

GFPexposuretime = 100;
AGFPexposuretime = 100;
GFPvoltage = 2;
AGFPvoltage = 2;

WTdata1 = 4*WTdata1./(GFPexposuretime*GFPvoltage);
EXPdata1 = 4*EXPdata1./(GFPexposuretime*GFPvoltage);

WTdata2 = 4*WTdata2./(AGFPexposuretime*AGFPvoltage);
EXPdata2 = 4*EXPdata2./(AGFPexposuretime*AGFPvoltage);


%% plot WT data

n_data_points = 5;

rand_cells = randperm(size(WTdata1,1));
rand_cells = rand_cells(1:n_data_points);


rand_tp = randperm(size(WTdata1,1));
rand_tp = rand_cells(1:n_data_points);


if ~exist('WT_plot_h','var')
    WT_plot_h = figure;
end

figure(WT_plot_h);
subplot(1,2,1);
h1 = plot(WTdata2(:,rand_tp),WTdata1(:,rand_tp),'o');
for hi = h1'
    set(hi,'MarkerFaceColor',get(hi,'Color'))
end
title('coloured by timepoint')
xlabel('GFPAutoFL')
ylabel('GFP')



subplot(1,2,2);
h2 = plot((WTdata2(rand_cells,:))',(WTdata1(rand_cells,:))','o');
for hi = h2'
    set(hi,'MarkerFaceColor',get(hi,'Color'))
end
title('coloured by cell')
xlabel('GFPAutoFL')
ylabel('GFP')



%% %% load GFP properties from str81 bleaching in 2014_03_11


load('~/Dropbox/MATLAB_DROPBOX/quantification_by_bleaching/data/2014_03_11_str81_02_processed_for_normalised_GFP_fluorescence_ratio.mat',...
    'FitParametersPixelAlternatePixelFLUOR');


%subtract WT cell data using this scheme boundary selection.
%think/read about clustering for timelapses.


%% fit line of relationship between alternate_pixel_value(x) and pixel_value(y) for WT cells

if ~exist('autofluorescence_fig','var')
    autofluorescence_fig = figure;
end

FitParametersPixelAlternatePixelWT = zeros(total_timepoints,2);
FitResiduals = nan(size(WTdata1));
ymax = nanmax(WTdata1(:));
ymin = nanmin(WTdata1(:));
xmax = nanmax(WTdata2(:));
xmin = nanmin(WTdata2(:));

for TP =1:total_timepoints;
    GFP = WTdata1(:,TP);
    Auto = WTdata2(:,TP);
    keepers = ~GFP==0 & ~Auto==0;
    GFP = GFP(keepers);
    Auto = Auto(keepers);
    FitParameters= polyfit(Auto,GFP,1);
    FitParametersPixelAlternatePixelWT(TP,:) = FitParameters(:);
    FitResiduals(:,TP) =WTdata1(:,TP) - ...
        (WTdata2(:,TP)*FitParametersPixelAlternatePixelWT(TP,1) + FitParametersPixelAlternatePixelWT(TP,2));
    
    figure(autofluorescence_fig);
    plot(Auto,GFP,'or',[min(Auto(:)) max(Auto(:))],...
        [min(Auto(:)) max(Auto(:))]*FitParametersPixelAlternatePixelWT(TP,1) + FitParametersPixelAlternatePixelWT(TP,2),'-b');
    title(sprintf('timepoint %d',TP))
    xlim([xmin xmax])
    ylim([ymin ymax])
    pause(1)
end


clear('ymax','ymin','xmax','xmin')


%% subtract autofluorescent contribution using modified catie's method with offsets and time varying autofluorescence properties.


%this is the one you want to do.
correctedEXPData = EXPdata1;
for TP = 1:total_timepoints

    correctedEXPData(:,TP) = ((EXPdata1(:,TP) - EXPdata2(:,TP)*FitParametersPixelAlternatePixelWT(TP,1)) - FitParametersPixelAlternatePixelWT(TP,2) )/(1 - (FitParametersPixelAlternatePixelWT(TP,1)/FitParametersPixelAlternatePixelFLUOR(1)));

end


correctedEXPData(EXPdata1 ==0) = NaN;
