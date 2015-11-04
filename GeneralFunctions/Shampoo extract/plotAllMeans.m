
fileNames=[];
fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/May 20 - 6uMZpT Cup2DEL switch at 5h/cExperiment.mat';
fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/May 26 - 0uMZpT Cup2DEL control no switch 5h/cExperiment.mat';
fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/May 27 - 2uMZpT glycerol growth switch at 10h/cExperiment.mat';

 fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/Feb 25 - 2uMZpT switch at 0h/cExperiment.mat';
 fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/Feb 26 - 10uM ZpT switch at 5h/cExperiment.mat';
 fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/Feb 27 - 10uM ZpT switch at 5h and back at 10h/cExperiment.mat';
 fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/Mar 3 - 6uM ZpT switch at 5h/cExperiment.mat';
 %fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/Mar 4 - 6uM ZpT switch at 5h and back at 10h - looks contaminated/cExperiment.mat';
 fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/Mar 13 - 6uM ZpT switch at 5h and back at 15/cExperiment.mat';
 fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/Mar 20 - 10uM ZpT switch at 5h and back at 15h/cExperiment.mat';
 fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/Mar 24 - 6uMZpT Cup2DEL switch 5h and back at 15h/cExperiment.mat';
 fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/Mar 25 - 50uMZpT switch at 5h and back at 15h/cExperiment.mat';
 fileNames{end+1}='/Volumes/AcquisitionDataRobin/Shampoo movies/Mar 26 - 2uMZpT switch at 5h and back at 15h/cExperiment.mat';

for fileIndex=1:length(fileNames)
    t=0:5:149*5;
    k=strfind(fileNames{fileIndex},'/');
    name=fileNames{fileIndex};
    name=name(k(end)+1:end-5)
    l(fileIndex)=line(t,mean(data{fileIndex}.normCumsum));
    set(l(fileIndex),'tag',name);
    names{length(names)+1}=name;
end


set(l(1),'color','r')
set(l(2),'color','black')
set(l(3),'color','bl')
set(l(4),'color','r')
set(l(5),'color','r')
set(l(6),'color','g')
set(l(7),'color','black')
set(l(8),'color','bl')
set(l(9),'color','g')
set(l(10),'color','b')
    