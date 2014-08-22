folderPath=uigetdir;
listing=dir(folderPath);
match=regexpi({listing.name},'CellAsicData_\d{1,2}\.mat','match');
matchTimelapse=regexpi({listing.name},'.*\d{2,3}_.*cTimelapse\.mat','match');
matchTimelapse=[matchTimelapse{:}];
match=[match{:}];
upDownData=[];
cellLabels=[];
timereloc=[];
%Load files and get data from them, compile into mega matrices
for i=1:length(match)
    load([folderPath filesep match{i}],'savefile');
    up=savefile.upslopes;
    down=savefile.downslopes;
    for j=1:length(up(:,1))
        upLoc=find(up(j,:));
        
        for k=1:length(upLoc)
            downLoc=find(down(j,upLoc(k):end),1,'first')+upLoc(k);
            if ~isempty(downLoc)&&~isempty(upLoc)
                timereloc=[timereloc; i j downLoc-upLoc(k)];
            end
        end
    end
end
[filename, path]=uiputfile('allData.xls');
xlswrite([path filesep filename],matchTimelapse);
xlswrite([path filesep filename],{'Position' 'cellID' 'Time spent localised'},1,'A3');
xlswrite([path filesep filename],timereloc,1,'A4');
