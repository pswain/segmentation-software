function [rowNum colNum]=findDirectoryPosRobin(cExperiment)

pattern='\d{3,3}';
rowNum=[]; colNum=[];
for i=1:length(cExperiment.dirs)
    
    fileNum=regexp(cExperiment.dirs(i),pattern,'match');
    fileNum=fileNum{1};
    
     rowNum(i)=str2num(fileNum{2});
    colNum(i)=str2num(fileNum{1});
end