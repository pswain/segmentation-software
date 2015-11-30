%Exports the data in the 'data' variable, created by ZpTnormplotting

fileNames=[];
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/data/3_3_6um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/data/wtcontrol_28_8.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/data/20_3_10um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/data/23_3_6um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/data/24_3_6umCup2.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/data/25_2_2um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/data/25_3_50um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/data/26_2_10um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/data/26_3_2um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/data/27_2_10um.mat';
frameInterval=5;
for fileIndex=1:length(fileNames)
    fileIndex
    currFileName=fileNames{fileIndex};
    savePath=[fileNames{fileIndex}(1:end-4) '_birthtimes.csv'];
    csvwrite(savePath,data{fileIndex}.bTime.*frameInterval)
    savePath=[fileNames{fileIndex}(1:end-4) '_cumsumbirths.csv'];
    csvwrite(savePath,(data{fileIndex}.cumsumBirths).*frameInterval);
    savePath=[fileNames{fileIndex}(1:end-4) '_normalizedcumsumbirths.csv'];
    csvwrite(savePath,(data{fileIndex}.normCumsum).*frameInterval);

end