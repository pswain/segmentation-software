%Analyse a list of cells for multiple positions and extract
%Data from them

%   1.Cell Label(provided)
%   2.Time spent Localised
%   3.Time since last G1 phase
%   4.Peak intensity while relocalising
%Then displayCellAsicData(relevantTimelapse,cellsToPlotList) for each
%Now also extract the tracks for localising and non-localising cells


%% Parameters
dataCells_reloc={[],[],[],[],[],[],[],[],[],[],[],[],[1,31],[],[],[20]};
dataCells_noReloc={[],[],[],[],[],[],[],[],[],[],[],[],[7,20,21,22,25,33],[1,6,8,13,15,18,22,29,31],[5,8,12],[4,5,15,18,21,25]};

%%

timepointLength=5;
folderPath=uigetdir;
listing=dir(folderPath);
matchData=regexpi({listing.name},'CellAsicData_\d{1,2}\.mat','match');
matchTimelapse=regexpi({listing.name},'.*\d{2,3}_.*cTimelapse\.mat','match');
matchData=[matchData{:}]; matchTimelapse=[matchTimelapse{:}];
matchData=sort_nat(matchData);
allData_reloc=[];
allData_noReloc=[];%Vector w columns [cellLabel timeLocalised timesG1 max(intensity)]
numCells=cell(1);
combinedTracks_reloc=[];
combinedTracks_noReloc=[];
for filenum=1:length(matchData)
    %disp(['Position: ' int2str(filenum)])%DEBUG
    load([folderPath filesep matchData{filenum}],'savefile');
    up=savefile.upslopes;
    down=savefile.downslopes;
    firstKeypoint=savefile.keypoint;
    lastKeypoint=firstKeypoint+6;        
    intensity=(savefile.extractedData(2).max5)./(savefile.extractedData(2).median);
    numCells{filenum}=length(dataCells_reloc{filenum});
    for i=1:length(dataCells_reloc{filenum})
        %Set vals to empty
        %disp(['Reloc ' int2str(i) ' of '
        %int2str(length(dataCells_reloc{filenum}))] )%DEBUG
        tpG1=[]; tpDelocalised=[];
        thisCell=find(savefile.cellLabels==dataCells_reloc{filenum}(i));
        combinedTracks_reloc=[combinedTracks_reloc; filenum dataCells_reloc{filenum}(i) intensity(thisCell,:)];

        if any(up(thisCell,firstKeypoint:lastKeypoint))%Upslopes in roi
            upslopePosition=firstKeypoint+find(up(thisCell,firstKeypoint:lastKeypoint),1,'first');
            tpG1=find(down(thisCell,1:firstKeypoint),1,'last');
            tpDelocalised=upslopePosition+find(down(thisCell,(upslopePosition):length(up(1,:))),1,'first');
            
            if ~isempty(tpDelocalised)
                timeLocalised=timepointLength*(tpDelocalised-upslopePosition);
            else
                disp(['No decrease in intensity in file ' int2str(filenum) ' r cell ' int2str(dataCells_reloc{filenum}(i))]);
                tpDelocalised=length(intensity(1,:));
                timeLocalised=timepointLength*(tpDelocalised-upslopePosition);
            end%if
            
            if ~isempty(tpG1)
                timesG1=timepointLength*(firstKeypoint-tpG1);
            else
                disp(['No earlier exit from G1 in file ' int2str(filenum) ' r cell ' int2str(dataCells_reloc{filenum}(i))]);
                timesG1=timepointLength*(firstKeypoint);
            end%if
            peakIntensity=max(intensity(thisCell,upslopePosition:tpDelocalised));
            allData_reloc=[allData_reloc; filenum dataCells_reloc{filenum}(i) timeLocalised timesG1 peakIntensity];
        else
            disp(['No upslope found in region of interest for file ' int2str(filenum) ' r cell ' int2str(dataCells_reloc{filenum}(i))  ])         
        end
        
    end
    
    %NON relocalising cells
    for i=1:length(dataCells_noReloc{filenum})
        %Set vals to empty
        tpG1=[];
        thisCell=find(savefile.cellLabels==dataCells_noReloc{filenum}(i));
        tpG1=find(down(thisCell,1:firstKeypoint),1,'last');
        combinedTracks_noReloc=[combinedTracks_noReloc; filenum dataCells_noReloc{filenum}(i) intensity(thisCell,:)];

        if ~isempty(tpG1)
            timesG1=timepointLength*(firstKeypoint-tpG1);
        else
            disp(['No earlier exit from G1 in file ' int2str(filenum) ' n-r cell ' int2str(dataCells_noReloc{filenum}(i))]);
            timesG1=timepointLength*firstKeypoint;
        end

        allData_noReloc=[allData_noReloc; filenum dataCells_noReloc{filenum}(i) timesG1];

        
    end
end
if isempty(allData_reloc)
    allData_reloc = ' ';
    combinedTracks_reloc=' ';
end

if isempty(allData_noReloc)
    allData_noReloc = ' ';
    combinedTracks_noReloc=' ';
end

[filename, path]=uiputfile('allData.xls','Save analysed data');
xlswrite([path filename(1:end-4) '_timingData'],matchTimelapse(1));
% xlswrite([path filename],numCells,1,'A2');
offset=2;
xlswrite([path filename(1:end-4) '_timingData'],{'Position', 'Cell Label', 'Time Localised', 'Time since G1','Peak intensity while relocalised,' ' ', 'Position','Cell Label', 'Time since G1'},1,['A' int2str(offset + 2)])
xlswrite([path filename(1:end-4) '_timingData'],allData_reloc,1,['A' int2str(offset + 3)]);
xlswrite([path filename(1:end-4) '_timingData'],allData_noReloc,1,['G' int2str(offset + 3)]);

xlswrite([path filename(1:end-4) '_combinedTracks.xls'],combinedTracks_reloc)
xlswrite([path filename(1:end-4) '_combinedTracks.xls'],combinedTracks_noReloc,1,['A' int2str(length(combinedTracks_reloc(:,1))+2)])
