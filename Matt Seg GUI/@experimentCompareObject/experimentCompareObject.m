classdef experimentCompareObject <handle
    %EXPERIMENTCOMPAREOBJECT an object to store the location of a ground
    %truth cExperiment and a set of other cExperiments to compare it too
    %for the purposes of error characterisations.
    
    
    properties
        timepointsTrapsToProcess ={} % cell array of timepointTrap matrices to process. Each is a sparse logical array, per position, or [tp x trap] instances to compare
        positionsToProcess = [] % list of positions to process. same size as timepointsTrapsToProcess but just indices.
        curatedtimepointTraps = {} % identitiy of timepoint Trap locations already curated.
        curatedTrapTracking = {} %identity of trap locations already curated
        groundTruthLocation = [] % path to ground truth cExperiment.
        experimentLocations = {} % paths to cExperiments to compare to ground truth
        experimentNames = {}
    end
    
    methods
        function obj = experimentCompareObject()
        end
        
        function setGroundTruth(self,location)
            %setGroundTruth(self,location)
            if nargin<2 || isempty(location)
                [filename,pathname] = uigetfile({'*.mat'},'please select the location of the ground truth cExperiment');
                location = fullfile(pathname,filename);
            end
            self.groundTruthLocation = location;
        end
        
        function addNewExperiment(self,location,experiment_name)
            %  addNewExperiment(self,location,experiment_name)
            if nargin<2 || isempty(location)
                [filename,pathname] = uigetfile({'*.mat'},'please select the location of a new cExperiment to add to the comparison',self.groundTruthLocation);
                location = fullfile(pathname,filename);
            end
            if nargin<3||isempty(experiment_name)
                name = '';
                while isempty(name);
                    name = inputdlg('please provide a name for this experiment that has is not already taken','experiment name',1);
                    name = name{1};
                    if ismember(name,self.experimentNames)
                        name = '';
                    end
                end
                experiment_name=name;
            end
            
            self.experimentLocations{end+1} = location;
            self.experimentNames{end+1} = experiment_name;
        end
        
        function cExperiment = loadExperiment(self,index)
            % cExperiment = loadExperiment(self,index)
            l1 = load(self.experimentLocations{index});
            cExperiment = l1.cExperiment;
            cExperiment.cCellVision = l1.cCellVision;
        end
        
        function cExperiment = loadGroundTruth(self)
            % cExperiment = loadGroundTruth(self)
            l1 = load(self.groundTruthLocation);
            cExperiment = l1.cExperiment;
            cExperiment.cCellVision = l1.cCellVision;
        end
        
        function setToProcessByTimepoint(self,timepoints)
            % setToProcessByTimepoint(self,timepoints)
            %
            % set the timepoint/traps to process to be all the traps at all
            % the position for just the timepoints timepoints. if
            % timepoints is not provided, uses all.
            cExperimentGT = self.loadGroundTruth;
            for posi = 1:length(self.positionsToProcess)
                pos = self.positionsToProcess(posi);
                cTimelapse = cExperimentGT.loadCurrentTimelapse(pos);
                timepoint_traps_matrix = false([length(cTimelapse.cTimepoint) length(cTimelapse.defaultTrapIndices)]);
                if nargin<2
                    timepoints = 1:length(length(cTimelapse.cTimepoint));
                end
                timepoint_traps_matrix(timepoints,:) = true;
                timepoint_traps_matrix = sparse(timepoint_traps_matrix);
                self.timepointsTrapsToProcess{posi} = timepoint_traps_matrix;
            end
        end
        
        function setTpProcessAsAll(self)
            %setByTrap(self,traps)
            %
            % set the timepoint/traps to process to be all the traps at all
            % the position forfor all timepoints.
            setToProcessByTimepoint(self);
        end
        
        function clearCuration(self,poses)
            % clearCuration(self,poses)
            % clears the declaration of timepoints as curated, resetting
            % them to false so that the curation can begin from the
            % beginning.
            % See Also: REMOVECURATIONAREA
            if nargin<2 || isempty(poses)
                poses = self.positionsToProcess;
            end
            for posi =1:length(poses)
                loc = self.positionsToProcess == poses(posi);
                self.curatedtimepointTraps{loc} = sparse(false(size(self.timepointsTrapsToProcess{loc})));
            end
        end
        
        function clearCurationTracking(self,poses)
            % clearCurationTracking(self,poses)
            % 
            % clears tracking curation
            
            if nargin<2 || isempty(poses)
                poses = self.positionsToProcess;
            end
            for posi =1:length(poses)
                loc = self.positionsToProcess == poses(posi);
                [TPs,Traps] = find(self.timepointsTrapsToProcess{posi});
                self.curatedTrapTracking{loc} = sparse(1e3,1e3);
            end
        end
        
        function removeCurationArea(self,number_to_remove)
            %removeCurationArea(self,number_to_remove)
            %bit of a hack function. removes the last 'number_to_remove'
            %curated images.
            % useful if you accidently let a few slip.
            % See Also: CLEARCURATION
            
            empty_poses = cellfun(@(x) any(full(x(:))),self.curatedtimepointTraps);
            last_pos_curated = find(empty_poses,1,'last');
            
            if isempty(last_pos_curated)
                last_pos_curated = 1;
            end
            
            curated_points = find(self.curatedtimepointTraps{last_pos_curated}(:));
            to_remove = curated_points((end-(number_to_remove-1)):end);
            self.curatedtimepointTraps{last_pos_curated}(to_remove) = false;
            
        end
        
        
        function cExperiment = curateGroundTruthForArea(self,channel_to_curate,skip_curated)
            %cExperiment = curateGroundTruthForArea(self,channel_to_curate,skip_curated)
            %
            % loads the ground truth cExperiment and then loads each
            % trap/timepoint individually using the trackingCurationGUI
            % for curation. Only those timepoints/traps specificed by
            % self.tpProcess are loaded.
            % When the GUI is closed it is assumed the timepoint/trap has
            % been curated and the correspoind entry in
            % self.curatedTimepointsTraps is set to 1.
            % 
            % channel_to_curate - channel to show in the curation GUI
            % skip_curated      - if true, skips traps/timepoints already
            %                     curated according to the self.curatedtimepointTraps
            %                     field.
            % See Also:
            % REMOVECURATIONAREA,CLEARCURATION,SETTOPROCESSBYTIMEPOINT,CURATEGROUNDTRUTHFORTRACKING
            
            if nargin<2 || isempty(channel_to_curate)
                channel_to_curate = 1;
            end
            
            if nargin<3 || isempty(skip_curated)
                skip_curated = false;
            end
            
            cExperiment = self.loadGroundTruth;
            
            for posi = 1:length(self.positionsToProcess)
                pos = self.positionsToProcess(posi);
                cTimelapse = cExperiment.loadCurrentTimelapse(pos);
                [TPs,Traps] = find(self.timepointsTrapsToProcess{posi});
                cExperiment.cTimelapse = cTimelapse;
                for i = 1:numel(TPs)
                    
                    TP = TPs(i);
                    TI = Traps(i);
                    
                    if ~skip_curated || ~(self.curatedtimepointTraps{posi}(TP,TI))
                        
                        gui = curateCellTrackingGUI(cTimelapse,cExperiment.cCellVision,TP,TI,1,channel_to_curate);
                        
                        % essentially inactivate slider gui so that you edit
                        % one timepont at a time and don't get confused.
                        % also, strange bug where last doesn't seem to be
                        % allowed by constructor.
                        
                        gui.slider.Value = TP;
                        gui.slider.Min = TP;
                        gui.slider.Max = TP;
                        
                        
                        uiwait();
                        cExperiment.saveTimelapse(pos);
                        self.curatedtimepointTraps{posi}(TP,TI) =true;
                    end
                end
            end
        end
        
        
        function cExperiment = curateGroundTruthForTracking(self,channel_to_curate,skip_curated)
            %cExperiment = curateGroundTruthForTracking(self,channel_to_curate,skip_curated)
            %
            % loads each experiment, and then goes through each trap to
            % make sure that they are curated for tracking
            
%             distThresh=20;
            
            if nargin<2 || isempty(channel_to_curate)
                channel_to_curate = 1;
            end
            
            if nargin<3 || isempty(skip_curated)
                skip_curated = false;
            end
            
            cExperiment = self.loadGroundTruth;
            
            for posi = 1:length(self.positionsToProcess)
                pos = self.positionsToProcess(posi);
                cTimelapse = cExperiment.loadCurrentTimelapse(pos);
                [TPs,Traps] = find(self.timepointsTrapsToProcess{posi});
                cExperiment.cTimelapse = cTimelapse;
                Traps=unique(Traps);
                for i = 1:numel(Traps)
                    for cellI=1:cTimelapse.cTimepoint(1).trapMaxCell(i)
                        TI = Traps(i);
                        
                        if ~skip_curated || ~(self.curatedTrapTracking{posi}(cellI,TI))
                            startTP=[];
                            for tempTP=TPs(end):-1:1
                                if any(cTimelapse.cTimepoint(tempTP).trapInfo(TI).cellLabel==cellI)
                                    startTP=tempTP;
                                end
                            end
                            if ~isempty(startTP)
                                isCellCloseEnough=self.IsCellCloseEnough(cTimelapse,startTP,TI,cellI);
%                                 centerIm=cTimelapse.trapImSize/2;
%                                 tempCellI=find(cTimelapse.cTimepoint(startTP).trapInfo(TI).cellLabel==cellI);
%                                 cellCent=cTimelapse.cTimepoint(startTP).trapInfo(TI).cell(tempCellI).cellCenter;
%                                 distFromCenter=pdist2(centerIm,cellCent);
                                if isCellCloseEnough%distFromCenter<distThresh
                                    gui = curateCellTrackingGUI(cTimelapse,cExperiment.cCellVision,TPs(1),TI,5,channel_to_curate);
                                    
                                    % essentially inactivate slider gui so that you edit
                                    % one timepont at a time and don't get confused.
                                    % also, strange bug where last doesn't seem to be
                                    % allowed by constructor.
                                    gui.CellLabel=cellI;
                                    gui.slider.Value = startTP;
                                    gui.slider.Min = TPs(1);
                                    gui.slider.Max = TPs(end);
                                    gui.UpdateImages
                                    
                                    uiwait();
                                    self.curatedTrapTracking{posi}(cellI,TI) =true;
                                    cExperiment.saveTimelapse(pos);
                                end
                            end
                        end
                    end
                end
            end
        end
        
        function isCellCloseEnough=IsCellCloseEnough(cTimelapse,startTP,TI,cellI)
            % isCellCloseEnough=IsCellCloseEnough(cTimelapse,startTP,TI,cellI)
            %
            % checks if a cell is within 20 pixels of the centre of the
            % trap - 
            % MATT - was this a criteria for being part of the tracking
            % curation set?
            distThresh=20;
            centerIm=cTimelapse.trapImSize/2;
            tempCellI=find(cTimelapse.cTimepoint(startTP).trapInfo(TI).cellLabel==cellI);
            cellCent=cTimelapse.cTimepoint(startTP).trapInfo(TI).cell(tempCellI).cellCenter;
            distFromCenter=pdist2(centerIm,cellCent);
            isCellCloseEnough=distFromCenter<distThresh;
            
        end
        
        
        function areaError = determineAreaError(self)
            % areaError = determineAreaError(self)
            %
            % calculates the area error for the experiments when compared
            % with the ground truth. returns struct array with the same
            % params
            
            % only runs on the traps/timepoints in self.curatedtimepointTraps{posi}(TP,TI)
            % that should have been labeled as true in the curateGroundTruth
            % See Also: CURATEGROUNDTRUTHFORAREA
            errorStruct=struct('cellSize',[],'areaError',[]);
            areaError=repmat(errorStruct,1,length(self.experimentNames));
            testExp=[];
            for expInd=1:length(self.experimentNames)
                testExp{expInd}=self.loadExperiment(expInd);
            end
            groundTruthExp=self.loadGroundTruth;
            
            for posInd=1:length(self.positionsToProcess)
                currPos=self.positionsToProcess(posInd);
                gtTimelapse=groundTruthExp.returnTimelapse(currPos);
                curatedLoc=self.curatedtimepointTraps{posInd}; %row=tp col=trap
                for expInd=1:length(testExp)
                    testTimelapse=testExp{expInd}.returnTimelapse(currPos);
                    for tpInd=1:size(curatedLoc,1)
                        for trapInd=1:size(curatedLoc,2)
                            overlapMatrix=[];%row=gt cell col=testCell
                            if curatedLoc(tpInd,trapInd) %only calc error if was curated
                                gtTrapInfo=gtTimelapse.cTimepoint(tpInd).trapInfo(trapInd);
                                testTrapInfo=testTimelapse.cTimepoint(tpInd).trapInfo(trapInd);
                                gtCellSize=[];testCellSize=[];
                                for gtCellInd=1:length(gtTrapInfo.cell)
                                    gtCell=imfill(full(gtTrapInfo.cell(gtCellInd).segmented),'holes');
                                    gtCellSize(gtCellInd)=sum(gtCell(:));
                                    for testCellInd=1:length(testTrapInfo.cell)
                                        tCell=imfill(full(testTrapInfo.cell(testCellInd).segmented),'holes');
                                        testCellSize(testCellInd)=sum(tCell(:));
                                        unionCell=tCell | gtCell;
                                        intersectCell=(tCell & gtCell); %| (~tCell & gtCell);
                                        overlapMatrix(gtCellInd,testCellInd)=sum(intersectCell(:))/sum(unionCell(:));
                                    end
                                end
                                
                                % finds the most overlapping test cell for each ground truth cell and records their error.
                                % MATT - slight issue if a test overlaps
                                % with two ground truth cells it might be
                                % used twice??
                                [v maxInd]=max(overlapMatrix,[],2);
                                for overlapInd=1:length(maxInd)
                                    areaError(expInd).areaError(end+1)=overlapMatrix(overlapInd,maxInd(overlapInd));
                                    areaError(expInd).cellSize(end+1)=gtCellSize(overlapInd);
                                end
                                % all cells with no ground truth
                                % counterpart contribute a score of zero.
                                overlapMatrix(:,maxInd)=NaN;
                                loc=find(max(~isnan(overlapMatrix)));
                                for noOverlapInd=1:length(loc)
                                    areaError(expInd).areaError(end+1)=0;
                                    areaError(expInd).cellSize(end+1)=testCellSize(loc(noOverlapInd));
                                end
                            end
                        end
                    end
                end
            end
            
        end
        
        function trackingError = determineTrackingError(self)
            % goes through all timepoints to identify the cell that is
            % there the longest in the curated dataset. This is labelled
            % the mother cell. It then finds the cell in the test dataset
            % that most closely matches up with that cell and then checks
            % the amount of time it overlaps with the real mother, as well
            % as the error type. 
            %only runs on the traps in self.curatedtimepointTraps{posi}(TP,TI)
            %that should have been labeled as true in the curateGroundTruth
            %  
            % MATT - please check
            %
            % OUTPUTS:
            % trackingError - structure array with one element for
            %                 each experiment
            %FIELDS:
            % errorMatrix   - matrix of the form [ground_truth_label x identified_cell_label] 
            %                 with each element being the number of
            %                 timepoints they overlap for.
            % errorAddCell  - matrix of the form [1 x ground_truth_label] 
            %                 with each element being the number of
            %                 timepoints for which no overlapping test cell
            %                 was found.
            % errorSeperate - matrix of the form [1 x ground_truth_label] 
            %                 with each element being the number of
            %                 times the overlapping cell had already been
            %                 used in the track of a previous cell.
            % erroCalc      - matrix of the form [1 x ground_truth_label] 
            %                 with each error calculated assuming error
            %                 weightings of 
            %                   join =1.0;
            %                   split = 2.0
            %                   add = 2.0;
            weightJoin=1.0;
            weightAdd=2;
            weightSplit=2;
            overlapThresh=.5;
            
            errorStruct=struct('errorMatrix',sparse(1e3,1e3),'errorAddCell',sparse(1,1e3),'errorSeparate',sparse(1,1e3),'errorCalc',[]);

            trackingError=repmat(errorStruct,1,length(self.experimentNames));
            testExp=[];
            groundTruthExp=self.loadGroundTruth;
            for expInd=1:length(self.experimentNames)
                testExp{expInd}=self.loadExperiment(expInd);
            end
            %             cellIndAll=zeros(1,length(self.experimentNames));
            
            for expInd=1:length(testExp)
                cellIndAll=0;
                for posInd=1:length(self.curatedTrapTracking)
                    currPos=posInd;
                    gtTimelapse=groundTruthExp.returnTimelapse(currPos);
                    curatedLoc=self.curatedTrapTracking{posInd}; %row=cellInd col=trapInde
                    [curatedCells curatedTraps]=find(curatedLoc);
                    traps=unique(curatedTraps);
                    testTimelapse=testExp{expInd}.returnTimelapse(currPos);
                    
                    for trapInd=1:length(traps)
                        completedCells=[];
                        currTrap=traps(trapInd);
                        cellsCurTrap=curatedCells(curatedTraps==currTrap);
                        cellIndAll=max(cellIndAll)+1:max(cellIndAll)+length(cellsCurTrap);
                        for cellInd=1:length(cellsCurTrap)
                            currCellSepInd=0;
                            for tpInd=1:length(gtTimelapse.cTimepoint)
                            
                                currCellInd=cellsCurTrap(cellInd);
                                cellLoc=find(gtTimelapse.cTimepoint(tpInd).trapInfo(currTrap).cellLabel==currCellInd);
                                if ~isempty(cellLoc)
                                    %                                     try
                                        gtCellSeg=gtTimelapse.cTimepoint(tpInd).trapInfo(currTrap).cell(cellLoc).segmented;
%                                     catch 
%                                         b=1;
%                                     end
                                    gtCellSeg=full(gtCellSeg);
                                    gtCellSeg=imfill(gtCellSeg,'holes');
                                    cellOverlap=[];
                                    for testCellInd=1:length(testTimelapse.cTimepoint(tpInd).trapInfo(currTrap).cell)
                                        tCell=full(testTimelapse.cTimepoint(tpInd).trapInfo(currTrap).cell(testCellInd).segmented);
                                        tCell=imfill(tCell,'holes');
                                        unionCell=tCell | gtCellSeg;
                                        intersectCell=(tCell & gtCellSeg); %| (~tCell & gtCell);
                                        cellOverlap(testCellInd)=sum(intersectCell(:))/sum(unionCell(:));
                                    end
                                    [vMax indMax]=max(cellOverlap);
                                    testCellLabel=testTimelapse.cTimepoint(tpInd).trapInfo(currTrap).cellLabel(indMax);
                                    %                                     try
                                    if vMax>overlapThresh
                                        trackingError(expInd).errorMatrix(cellIndAll(cellInd),testCellLabel)=1 + trackingError(expInd).errorMatrix(cellIndAll(cellInd),testCellLabel);
                                        alreadyUsedCell=find(completedCells==testCellLabel);
                                        if isempty(alreadyUsedCell)
                                            completedCells=[completedCells testCellLabel];
                                            currCellSepInd=[currCellSepInd testCellLabel];
                                        else
                                            if ~any(currCellSepInd==testCellLabel)
                                                currCellSepInd=[currCellSepInd testCellLabel];
                                                trackingError(expInd).errorSeparate(cellIndAll(cellInd))=trackingError(expInd).errorSeparate(cellIndAll(cellInd))+1;
                                            end
                                        end
                                    else
                                        trackingError(expInd).errorAddCell(cellIndAll(cellInd))=1+ trackingError(expInd).errorAddCell(cellIndAll(cellInd));
                                    end
                                    %                                     catch
                                    %                                         b=1
                                    %                                     end
                                end
                            end
                        end
                    end
                end
            end
            

            for expInd=1:length(testExp)
                errorMatrix=trackingError(expInd).errorMatrix;
                errorAdd=trackingError(expInd).errorAddCell;
                errorSplit=trackingError(expInd).errorSeparate; %b/c all cells by default have one split in the calculations
                loc=find(max(errorMatrix,[],2)>0);
                nCells=max(loc);
                for cellInd=1:nCells
                    tVal=errorMatrix(cellInd,:);
                    totalTp=sum(tVal)+errorAdd(cellInd);
                    
                    [corrTrack ind]=max(tVal);
                    tVal(ind)=0;
                    joinErr=sum((tVal>0)*weightJoin);
                    addErr=errorAdd(cellInd)*weightAdd;
                    splitErr=errorSplit(cellInd)*weightSplit;
                    errTemp=1 - (addErr+joinErr+splitErr)/(totalTp*weightAdd);
                    % shouldn't happen
                    if isinf(errTemp)
                        errTemp=NaN;
                    end
                    trackingError(expInd).errorCalc(cellInd)=errTemp;
                end
            end
        end
        
        

        
    end
    
end

