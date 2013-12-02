%% GENERAL DATA PLAY FILE

%% Get CompiledExtractedData

load('~/Documents/microscope_files_swain_microscope/PDR5/2013_02_06/PDR5GFPscGlc_2perc_00/compiledData.mat','CompiledExtractedData');

%% add new data

newExtractedData = cTimelapse.extractedData(2);
EDfields = fields(newExtractedData);
for s = 1:length(EDfields)
    
    CompiledExtractedData.(EDfields{s}) = [CompiledExtractedData.(EDfields{s});newExtractedData.(EDfields{s}) ];
    
end

clear('newExtractedData','s');

%% save data

save('~/Documents/microscope_files_swain_microscope/PDR5/2013_02_06/PDR5GFPscGlc_2perc_00/compiledData.mat','CompiledExtractedData');


%% prep for new data

toExtract = 'mean';
data = CompiledExtractedData.(toExtract);
Plotfig = figure;
TimeDifference = 5;%time between each image
%% plot data all together

figure(Plotfig);
plot((1:length(data))*TimeDifference,data);
xlabel('time (min)')
ylabel([toExtract ' fluorescence (arbitrary units)'])


%% plot data Nplot at a time
Nplot = 8;

MData = max(data(:));

figure(Plotfig);
plothandle = plot((1:size(data,2))*TimeDifference,data(1:Nplot,:),'-o');
xlabel('time')
ylabel(toExtract)
ylim([0 MData])
pause
for i = 1:(floor(size(data,1)/Nplot)-1)
    for n=1:Nplot
        delete(plothandle(n))
    end
    plothandle = plot((1:size(data,2))*TimeDifference,data((1:Nplot)+(Nplot*i),:),'-o');
    ylim([0 MData])
pause
end

%% find mean of all time courses

for t = 1:size(data,2)

MeanOfData(t) = mean(data((data(:,t)~=0),t));

end

plot(1:size(data,2)*TimeDifference,MeanOfData)





