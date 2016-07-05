classdef experimentCompareObject <handle
    %EXPERIMENTCOMPAREOBJECT an object to store the location of a ground
    %truth cExperiment and a set of other cExperiments to compare it too
    %for the purposes of error characterisations.
    
    
    properties
        timepointsTrapsToProcess ={} % cell array of timepointTrap matrices to process. Each is a sparse logical array, per position, or [tp x trap] instances to compare
        positionsToProcess = [] % list of positions to process. same size as timepointsTrapsToProcess but just indices.
        curatedtimepointTraps = {} % identitiy of timepoint Trap locations already curated.
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
                [filename,pathname] = uigetfile({'*.mat'},'please select the location of a new cExperiment to add to the comparison');
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
            end
            self.experimentLocations{end+1} = location;
            self.experimentNames{end+1} = name;
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
        
        function setByTimepoint(self,timepoints)
            %setByTimepoint(self,timepoints)
            %
            % set the timepoint/traps to process to be all the traps at all
            % the position for just the timepoints timepoints.
            
            cExperimentGT = self.loadGroundTruth;
            for posi = 1:length(self.positionsToProcess)
                pos = self.positionsToProcess(posi);
                cTimelapse = cExperimentGT.loadCurrentTimelapse(pos);
                timepoint_traps_matrix = false([length(cTimelapse.cTimepoint) length(cTimelapse.defaultTrapIndices)]);
                timepoint_traps_matrix(timepoints,:) = true;
                timepoint_traps_matrix = sparse(timepoint_traps_matrix);
                self.timepointsTrapsToProcess{posi} = timepoint_traps_matrix;
                
            end
            
        end
        
        function clearCuration(self,poses)
            if nargin<2 || isempty(poses)
                poses = self.positionsToProcess;
            end
            
            for posi =1:length(poses)
                loc = self.positionsToProcess == poses(posi);
                self.curatedtimepointTraps{loc} = sparse(false(size(self.timepointsTrapsToProcess{loc})));
            end
            
        end
        
        
        function cExperiment = curateGroundTruthForArea(self,channel_to_curate,skip_curated)
            %cExperiment = curateGroundTruthForArea(self,channel_to_curate,skip_curated)
            %
            % loads the ground truth cExperiment and then loads each
            % trap/timepoint individually using the trackingCurationGUI to
            % for curation
            
            if nargin<2 || isempty(channel_to_curate)
                channel_to_curate = 1;
            end
            
            if nargin<3 || isempty(skip_curated)
                skip_curated = false;
            end
            
            cExperiment = self.loadGroundTruth;
            
            for posi = 1:self.positionsToProcess
                pos = self.positionsToProcess(posi);
                cTimelapse = cExperiment.loadCurrentTimelapse(pos);
                [TPs,Traps] = find(self.timepointsTrapsToProcess{posi});
                cExperiment.cTimelapse = cTimelapse;
                for i = 1:numel(TPs)
                    
                    TP = TPs(i);
                    TI = Traps(i);
                    gui = curateCellTrackingGUI(cTimelapse,cExperiment.cCellVision,TP,TI,1,channel_to_curate);
                    
                    % essentially inactivate slider gui so that you edit
                    % one timepont at a time and don't get confused.
                    gui.slider.Min = TP;
                    gui.slider.Max = TP;
                    
                    
                    uiwait();
                    cExperiment.saveTimelapse(pos);
                    self.curatedtimepointTraps{posi}(TP,TI) =true;
                    
                end
            end
        end
        
        function areaError = determineAreaError(self)
            % calculates the area error for the experiments when compared
            % with the ground truth. returns struct array with the same
            % params
            
            %only runs on the traps/timepoints in self.curatedtimepointTraps{posi}(TP,TI)
            %that should have been labeled as true in the curateGroundTruth
            errorStruct=struct('cellSize',[],'areaError',[]);
            areaError=repmat(errorStruct,1,length(self.experimentNames));
            testExp=[];
            for expInd=1:length(self.experimentNames)
                testExp{expInd}=elf.loadExperiment(expInd);
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
                                        unionCell=tCell & gtCell;
                                        intersectCell=(tCell & ~gtCell) | (~tCell & gtCell);
                                        overlapMatrix(gtCellInd,testCellInd)=sum(unionCell(:))/sum(intersectCell(:));
                                    end
                                end
                                
                                %checks all of the 
                                [v i]=max(abs(overlapMatrix-1),[],2);
                                for overlapInd=1:length(i)
                                    errorStruct(expInd).areaError(end+1)=overlapMatrix(overlapInd,i);
                                    errorStruct(expInd).cellSize(end+1)=gtCellSize(overlapInd);
                                end
                                overlapMatrix(:,i)=NaN;
                                loc=find(max(~isnan(overlapMatrix)));
                                for noOverlapInd=1:length(loc)
                                    errorStruct(expInd).areaError(end+1)=0;
                                    errorStruct(expInd).cellSize(end+1)=testCellSize(loc(noOverlapInd));
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
            
            %
            
            %only runs on the traps in self.curatedtimepointTraps{posi}(TP,TI)
            %that should have been labeled as true in the curateGroundTruth
            errorStruct=struct('gtDuration',[],'testDuration',[],'errorType',[]);
            trackingError=repmat(errorStruct,1,length(self.experimentNames));
            testExp=[];
            for expInd=1:length(self.experimentNames)
                testExp{expInd}=elf.loadExperiment(expInd);
            end
            groundTruthExp=self.loadGroundTruth;

            
        end

        
    end
    
end

