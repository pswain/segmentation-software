function [birthTimesRemovedDuplicates motherStart]=removeDuplicateBirthTimes(cExperiment,duplCutoff,switchTime)

birthTimes=cExperiment.lineageInfo.motherInfo.birthTime;

motherStartEnd=cExperiment.lineageInfo.motherInfo.motherStartEnd;

% remove mothers not present before the switch
if nargin>2
    birthTimes(motherStartEnd(:,1)>switchTime-12,:)=[];
    motherStartEnd(motherStartEnd(:,1)>switchTime-12,:)=[];
    birthTimes(motherStartEnd(:,2)<switchTime+16,:)=[];
    motherStartEnd(motherStartEnd(:,2)<switchTime+16,:)=[];

end
motherStart=motherStartEnd(:,1);
% 
% %remove daughters that are present when the cell appears
% for i=1:size(birthTimes,1)
%     temp=birthTimes(i,:);
%     birthTimes(i,:)=zeros(1,length(temp));
%     temp(temp==motherStart(i))=[];
%     birthTimes(i,1:length(temp))=temp;
% end
  
%remove daughters 1tp before and after the switch
if nargin>2
    for i=1:size(birthTimes,1)
        temp=birthTimes(i,:);
        birthTimes(i,:)=zeros(1,length(temp));
        

        
        temp(temp==switchTime)=[];
%                 temp(temp==switchTime-1)=[];
%         temp(temp==switchTime+1)=[];

        birthTimes(i,1:length(temp))=temp;
    end
end

%remove duplicate birth events
duplicateBirth=diff(birthTimes,1,2)<duplCutoff;
birthTimesRemovedDuplicates=[];
for i=1:size(duplicateBirth,1)
    temp=birthTimes(i,:);
    for j=1:length(temp)-1
        dBirth=(temp(j+1)-temp(j))<duplCutoff;
        if dBirth
            temp(j+1)=temp(j);
        end
    end
    duplicateBirth=diff(temp,1,2)<1;
    temp(duplicateBirth)=[];
    birthTimesRemovedDuplicates(i,1:length(temp))=temp;
end


