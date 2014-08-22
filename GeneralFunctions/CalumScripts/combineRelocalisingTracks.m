%Combine the tracks for localising cells

folderPath=uigetdir;
listing=dir(folderPath);
matchData=regexpi({listing.name},'CellAsicData_\d{1,2}\.mat','match');
matchData=[matchData{:}];
matchData=sort(matchData,'ascend');


% %Localisers plots
% for i=1:length(matchData)
%     load([folderPath filesep matchData{i}],'savefile');
%     %Do stuff
%     save([folderPath filesep matchData{i}],'savefile');
% end
% 
% 
% %Non-localisers plots
% for i=1:length(matchData)
%     load([folderPath filesep matchData{i}],'savefile');
%     %Do something else
%     save([folderPath filesep matchData{i}],'savefile');
% end
