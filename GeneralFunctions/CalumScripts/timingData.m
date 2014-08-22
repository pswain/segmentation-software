%If anyone reads this before I have a chance to tidy things up I sincerely
%appologise
%Things here are done the most obvious way, without any real plan for
%future extension.

folderPath=uigetdir;
listing=dir(folderPath);
match=regexpi({listing.name},'CellAsicData_\d{1,2}\.mat','match');
match=[match{:}];
timeLocalised=cell(1);
timesG1=cell(1);
upDownData=[];
cellLabels=[];

%Load files and get data from them, compile into mega matrices
for i=1:length(match)
    load([folderPath filesep match{i}],'savefile');
    [tempLoc, tempG1]=getTimingStats(savefile);
    cellLabels=[cellLabels; savefile.cellLabels(1,:)];
    timeLocalised{i}=tempLoc;
    timesG1{i}=tempG1;
    tempUpDown=getUpDown(savefile);
    upDownData=[upDownData; tempUpDown];
end
numUp=[];


for i=1:length(upDownData(1,:))
    tempNumUp=sum(upDownData(:,i));
    numUp=[numUp tempNumUp];
end


dataForHistogram=[timeLocalised{:}];
dataForHistogram(dataForHistogram==0)=[];

 figure;subax=axes;
 hist(subax,dataForHistogram,1:10);
 
 
% forprint=[forprint; find(timeLocalised)];
% numAtTimepoints=zeros(1,max(forprint(1,:)));
% hold on;
% %Is the highlighted cell the cellID or cellLabel
% for i=1:length(forprint(1,:))
%     label=forprint(2,i);
%     %Get back the original label from the label here
%     for j=1:length(cellLabels(:,1))
%         %positionList is a list of the labels of all cells with data for the specified
%         %timepoint
%         positionList=find(cellLabels(j,:));
%         if label<=length(positionList)
%            labelInPosition=positionList(label);
%            labelText=[int2str(j) ',' int2str(labelInPosition)];
%            break
%         else
%             label=label-length(positionList);
%         end
%     end
%     pos=forprint(1,i);
%     text(pos,(0.5+numAtTimepoints(pos)),labelText,...
%         'backgroundColor','w');
%     numAtTimepoints(pos)=numAtTimepoints(pos)+1;
% end
% 
