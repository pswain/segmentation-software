fileNames=[];
% fileNames{end+1}='C:\Users\mcrane2\OneDrive\timelapses\Dandruff\Feb 26 - 10uM ZpT switch at 5h\cExperiment.mat';
% fileNames{end+1}='C:\Users\mcrane2\OneDrive\timelapses\Dandruff\Feb 27 - 10uM ZpT switch at 5h and back at 10h\cExperiment.mat';
fileNames{end+1}='C:\Users\mcrane2\OneDrive\timelapses\Dandruff\Mar 3 - 6uM ZpT switch at 5h\cExperiment.mat';

addpath('dandruff');
for fileIndex=1:length(fileNames)
    currFileName=fileNames{fileIndex};
    load(currFileName);
    process_cExperimentsDandruff;
end
