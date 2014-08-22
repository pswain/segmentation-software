folderPath=uigetdir;
listing=dir(folderPath);
matchData=regexpi({listing.name},'CellAsicData_\d{1,2}\.mat','match');
matchData=[matchData{:}];

for i=1:length(matchData)
    load([folderPath filesep matchData{i}],'savefile');
    savefile=autoselect(savefile);
    save([folderPath filesep matchData{i}],'savefile');
end
