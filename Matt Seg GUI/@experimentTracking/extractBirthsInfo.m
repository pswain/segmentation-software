function cExperiment=extractBirthsInfo(cExperiment, params)
%Extracts data on the number of budding events undergone by each mother
%cell during a timelapse. This replaces the script "extractDandruffData".
%Results are recorded in cExperiment.lineageInfo.birthsData

%Input params is a structure, defined as below
if nargin==1%Default parameter values
   params.mStartTime=12;%Only cells present from mStartTime to mEndTime will be included
   params.mEndTime=cExperiment.timepointsToProcess(end);%
   %Parameters for 
   params.motherDurCutoff=180;
   params.motherDistCutoff=8;
   params.budDownThresh=0;
   params.birthRadiusThresh=7;
   params.daughterGRateThresh=-1;
end

%ADD A SERIES OF IF STATEMENTS HERE TO DETERMINE IF PRE-PROCESSING STEPS
%HAVE BEEN DONE
%Need to check here if the cells have been tracked. If not, track them.

%If no cells have been tracked then cExperiment.posTracked=0
%If cells tracked then it's a 1xnumPositions logical vector, all 1s

%If cells not selected then cExperiment.cellsToPlot={[]}


%If data not extracted

%Also if cells have been selected. 

%Segmented positions have indices: find(cExperiment.posSegmented);
%Tracked positions have cExperiment.posTracked==1

%Also need to select cells (eg autoselect) and extract data




%Call cExperiment.extractLineageInfo
cExperiment.extractLineageInfo(find(cExperiment.posTracked),params);
%Compile lineage info (to copy data from the saved cTimelapsees to
%cExperiment)
cExperiment.compileLineageInfo;
%Run HMM to define mother cells
cExperiment.extractHMMTrainingStates;
load('birthHMM_robin.mat');
cExperiment.classifyBirthsHMM(birthHMM);
%Record the the births data in a usable form in the .birthsData structure
mStartTime=params.mStartTime;
mEndTime=params.mEndTime;
totalTimepoints=length(cExperiment.timepointsToProcess);
%only use mothers there for most of the run
motherDur=diff(cExperiment.lineageInfo.motherInfo.motherStartEnd,1,2);
motherDurThresh=max(motherDur)*.5;
motherLongEnough=motherDur>=motherDurThresh;
motherLongEnough=motherLongEnough&cExperiment.lineageInfo.motherInfo.motherStartEnd(:,1)<=mStartTime;
motherLongEnough=motherLongEnough&cExperiment.lineageInfo.motherInfo.motherStartEnd(:,2)>=mEndTime;


motherLoc=returnMotherIndicesCellInf(cExperiment,[],motherDurThresh,motherLongEnough);
cExperiment.lineageInfo.birthsData.motherIndices=find(motherLoc);%Indices in extracted data of the mother cells
cExperiment.lineageInfo.birthsData.bTime=cExperiment.lineageInfo.motherInfo.birthTimeHMM(motherLongEnough(1:size(cExperiment.lineageInfo.motherInfo.birthTimeHMM,1)),:);

binaryBirths=zeros(size(cExperiment.lineageInfo.birthsData.bTime,1),totalTimepoints);
for cellInd=1:size(cExperiment.lineageInfo.birthsData.bTime,1)
    bTimeTemp=cExperiment.lineageInfo.birthsData.bTime(cellInd,:);
    bTimeTemp(bTimeTemp==0)=[];
    binaryBirths(cellInd,bTimeTemp)=1;
end

cExperiment.lineageInfo.birthsData.cumsumBirths=cumsum(binaryBirths(:,1:totalTimepoints),2);

cExperiment.saveExperiment;
end