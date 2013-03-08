%% GENERAL DATA PLAY FILE

%% Get CompiledExtractedData

load('~/Documents/microscope_files_swain_microscope/PDR5/2013_02_06/PDR5GFPscGlc_2perc_00/compiledData.mat','CompiledExtractedData');

%% add new data

newExtractedData = cTimelapse.extractedData(2);
EDfields = fields(newExtractedData);
for s = 1:length(EDfields)
    
    CompiledExtractedData.(EDfields{s}) = [CompiledExtractedData.(EDfields{s});newExtractedData.(EDfields{s}) ];
    
end

clear('newExtractedData');

%% save data

save('~/Documents/microscope_files_swain_microscope/PDR5/2013_02_06/PDR5GFPscGlc_2perc_00/compiledData.mat','CompiledExtractedData');


%% prep for new data

toExtract = 'median';
data = CompiledExtractedData.(toExtract);
Plotfig = figure;
TimeDifference = 5;%time between each image
%% plot data all together

plot((1:length(data))*TimeDifference,data);
xlabel('time')
ylabel(ToExtract)


%% plot data Nplot at a time
Nplot = 4;

figure(Plotfig);
plothandle = plot((1:length(data))*TimeDifference,data(1:4,:),'-o');
xlabel('time')
ylabel(toExtract)
ylim([0 max(data(:))])
for i = 1:(floor(size(data,1)/Nplot)-1)
    for n=1:Nplot
        delete(plothandle(n))
    end
    plothandle = plot((1:length(data))*TimeDifference,data((1:Nplot)+(Nplot*i),:),'-o');
    ylim([0 max(data(:))])
pause
end





