classdef loop_timepoints<trackmethods.TrackMethodsSuperClass
    methods
        function LT=loop_timepoints(varargin)
            % loop_timepoints --- a tracking function that can be called by
            %                     TrackYeast class. This costructor merely
            %                     sorts sets the parameters.
            
            % Synopsis:           loop_timepoints(Timelapse,varargin)
            %
            % Input:              Timelapse = an object of a Timelapse3 class
            %                     varargin = place in which parameters can be specified
            %                     in the conventional matlab way. Two possible parameters are:
            %                        ScoreFunction - a string specifying function in
            %                                        the +loopscorefunctions package to use
            %                        ScoreFunctionParameters - a cell array of parameters to
            %                                                  use in the score function
            
            %
            % Output:             LT == an object of a loop_timepoints class
            %default parameters
            LT.parameters = struct;
            LT.parameters.ScoreFnc = 'distance_SF';
            LT.parameters.ScoreFncParameters = {30};
        end
        
        
        
        function Timelapse = run(LT,Timelapse)
            
            % run      ---        a tracking function that can be called by TrackYeast
            %                     Timlapse method. Loops through each timepoint and calls one of a range of
            %                     score functions to assign score to each cell.
            
            % Synopsis:           Timelapse = run(LT,Timelapse)
            %
            % Input:              LT = an object of the loop_timepoints class
            %                     Timelapse = an object of a Timelapse3 class
            %                     
            
            %
            % Output:             Timelapse == an object of a Timelapse3 class
            
            % Notes: The function loops through each timepoint,t, and then in turn
            % loops through each timepoint previous to that, tpast, and calls one of a
            % range of score functions (given by ScoreFunction and found in
            % +loopScoreFunctions package) to assign score to each cell. These score
            % functions are all of the form:
            
            % [ScoreMat] = ScoreFunction(Timelapse,TNnow,TNpast,tnow,tpast,paramScoreFnc)
            % where:
            % Timelapse is an object of the timelapse class
            % TNnow = vector of tracking numbers of cells of interest at the current timepoint.
            % TNpast = vector of tracking numbers of cells of interest at the past timepoint.
            % t = current timepoint
            % tpast = past timepoint that is of interest
            % paramScoreFnc = parameters of the score function in a cell array
            
            %ScoreMat is a [tracking numbers at previous timepoint]x[tracking numbers
            % %at current timepoint] matrix of scores with the property:
            % Positive real number = a score to be compared with higher scores indicating that two cells are more likely to share a cell number.
            % -1 = assign a new cell number to this score.
            % -2 = pass to the cell to the timepoint previous to this one and look there for a cell number
            
            % The function then loops through the matrix, finding the highest score,
            % assigning the corresponding cell number to a given cell and then removing
            % that row and column from the matrix. If there is a draw (i.e. to entries
            % in the matrix have the same score, the algorithm arbitrarily picks the
            % one at the top left corner and moves on. This continues until all the
            % cells have been either assigned a cell number or are to be passed on to
            % the next timepoint. At this point function reduced tpast by one and
            % starts the loop again.
            
            
            ScoreFunction = str2func(['trackmethods.loopScoreFunctions.' LT.parameters.ScoreFnc]);%function handle to the score function
            paramScoreFnc = LT.parameters.ScoreFncParameters;%parameters for the score function
            
            ParamCell = LT.param2struct;%cell to be entered in trackingdata structure to record tracking method used.
            
            if isempty(Timelapse.TimePoints)
                Timelapse.TimePoints=size(Timelapse.Segmented,2);
            end
            
            tp1CellNumbers = num2cell([Timelapse.TrackingData(1).cells(:).trackingnumber]);%cell numbers at time point 1 - just the tracking numbers
            [Timelapse.TrackingData(1).cells(:).cellnumber]=deal(tp1CellNumbers{:});%assign cell numbers
            
            
            clear tp1CellNumbers
            
            highest = Timelapse.gethighest;
            %highest cell number currently used.
            
            %loop through the remaining timepoints calling the score function and
            %assigning cell numbers
            
            if Timelapse.TimePoints>1
                for tnow=2:Timelapse.TimePoints %loop over current timepoints
                    showMessage(strcat('Tracking time point ',num2str(tnow)));%COMMENT THIS LINE FOR SPEED
                    tpast = tnow-1; %for looping over past timepoints
                    if ~isempty(Timelapse.TrackingData(tnow).cells)
                    TNnow = [Timelapse.TrackingData(tnow).cells([Timelapse.TrackingData(tnow).cells().cellnumber] ==0).trackingnumber];
                    %tracking numbers of cells without a cell number in the current timepoint
                    
                    while(any(TNnow))
                        message=['comparing with timepoint ' num2str(tpast)];
                        showMessage(message);
                        if tpast<1 %once tpast gets to 0 have to assign new cell numbers to all the remaining cells at the current time point
                            tempCN = num2cell(highest+1:highest+(size(TNnow,2)));
                            [Timelapse.TrackingData(tnow).cells(TNnow).cellnumber]=deal(tempCN{:});
                            %numMethods=size(Timelapse.TrackingData(tnow).cells(TNnow).methodobj,2);
                            %Timelapse.TrackingData(tnow).cells(TNnow).methodobj(numMethods+1)=LT;
                            highest = highest + size(TNnow,2);
                            TNnow = [];
                            clear tempCN
                        else
                            
                            if ~isempty(Timelapse.TrackingData(tpast).cells)
                            TNpast = [Timelapse.TrackingData(tpast).cells(...
                                ~ismember([Timelapse.TrackingData(tpast).cells(:).cellnumber],[Timelapse.TrackingData(tnow).cells(:).cellnumber])...
                                ).trackingnumber];%tracking numbers of cells at the timepoint tpast with...
                            %cell numbers not yet used in the current timepoint
                            
                            if isempty(TNpast) %if all the cell numbers at tpast are already observed at tnow then TNpast will be empty and the timpoint should be skipped.
                                ScoreMat = [];
                            else
                                try
                                [ScoreMat] = ScoreFunction(Timelapse,TNnow,TNpast,tnow,tpast,paramScoreFnc);
                                catch
                                disp('debug point in looptimepoints.run');
                                ScoreMat=[];
                                end
                            end
                            
                            MoveOn = 0;
                            %variable indicating whether to continue looping through the
                            %curent past timepoint tpast
                            while(any(TNnow) && MoveOn == 0 && ~isempty(ScoreMat))
                                
                                [msVEC,bcnVEC] = max(ScoreMat,[],1);
                                %msVEC = the best scores for every cell tracked in the current
                                %timepoint
                                %bcnVEC = the indices in TNpast of the cells that
                                %give the best scores for cells tracked at the current
                                %timepoint
                                
                                
                                [ms,btn] = max(msVEC,[],2);
                                %maxScore = the best score in ScoreMat
                                %btn = the index in TNnow of the cell at the current time point with the best
                                %score
                                
                                bcn = bcnVEC(btn);
                                %bcn = index in TNpast of the cell that gives the best
                                %score for cell with tracking number TNnow(btn) at the current
                                %timepoint tnow
                                
                                if ms>-1
                                    Timelapse.TrackingData(tnow).cells(TNnow(btn)).cellnumber=Timelapse.TrackingData(tpast).cells(TNpast(bcn)).cellnumber;
                                    Timelapse.TrackingData(tnow).cells(TNnow(btn)).trackingmethod=mfilename;
                                    Timelapse.TrackingData(tnow).cells(TNnow(btn)).trackingparameters=ParamCell;
                                    
                                    ScoreMat(bcn,:) = [];%remove the column of the cell which now has a cell number
                                    ScoreMat(:,btn) = [];%remove the row of the cell with the corrsponding cell number at time tpast
                                    TNnow(btn) = [];%similarly remove cell from TNnow and TNpast
                                    TNpast(bcn) = [];
                                elseif ms ==-1
                                    tempTN = TNnow(msVEC==-1);%all the cells with -1 as their highest score in the score matrix
                                    tempCN = num2cell(highest+1:highest+(size(temp,2)));
                                    [Timelapse.TrackingData(tnow).cells(tempTN).cellnumber]=deal(tempCN{:});%assign a new cell number to all the cells with -1 as their highest score in the score matrix
                                    [Timelapse.TrackingData(tnow).cells(tempTN).trackingmethod]=deal(mfilename);
                                    [Timelapse.TrackingData(tnow).cells(tempTN).trackingparameters]=deal(ParamCell);
                                    
                                    ScoreMat(:,tempTN) = [];
                                    TNnow(msVEC==-1) = [];
                                    highest = highest+(size(tempTN,2));
                                    clear tempTN
                                    clear tempCN
                                elseif ms ==-2 %if the highest remaining score is -2 no further cell numbers should be assigned and the next previous timepoint inspected.
                                    MoveOn=1;
                                else%this should not occur, since score should always be positive real, -1 or -2.
                                    save(['score_fnc_error_' param.ScoreFnc])
                                    showMessage('score matrix is: \n');
                                    showMessage(num2str(ScoreMat))
                                    error(['error in score matrix. Entries must be: \n    positive real (->score)\n    -1 (->assign new cell number)' ...
                                        '\n    -2 (->pass cell to previous timepoint) \n see score_fnc_error_' param.ScoreFnc '.mat for variable states at time of error'  ])
                                end
                            end
                            end
                            tpast = tpast - 1;
                            
                            
                        end
                    end
                    end
   
                    
                    
                end
                
                
                
            end
        end
    end
end
